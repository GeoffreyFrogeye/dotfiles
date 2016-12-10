#!/usr/bin/env bash

# Handles indexing and SSH keys of machines I
# have access on
# (sourceable)

MACHINES_HOME=$HOME
MACHINES_CONFIG=$HOME/.config/machines
MACHINES_API=https://machines.frogeye.fr

mkdir -p $MACHINES_HOME &> /dev/null
mkdir -p $MACHINES_CONFIG &> /dev/null

# COMMON

function prompt { # text
    while true; do
        read -p "$1 [yn] " yn
        case $yn in
            [Yy]* ) return 1;;
            [Nn]* ) return 0;;
            * ) echo "Please answer y or n.";;
        esac
    done
}

# From https://gist.github.com/cdown/1163649

urlencode() { # string
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
    LC_COLLATE=$old_lc_collate
}

urldecode() { # string
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

# API ACCESS

function _machines-api {
    route=$1
    shift
    wget $MACHINES_API/$route --content-on-error --quiet --output-document=- "$@"
}

function _machines-apiToken {
    read -p 'TOTP token: ' token
    _machines-api "$@" --header="X-TOTP: $token"
}

function _machines-apiSigned {
    _machines-api "$@" --certificate=$MACHINES_CONFIG/machines.crt --private-key=$MACHINES_CONFIG/machines.key
}

function _machines-getQR {
    _machines-apiSigned totp | qrencode -o - | feh -
}

# APPLICATION KEYS & CERTIFICATE

function _machines-pubFromCrt {
    openssl x509 -in $MACHINES_CONFIG/machines.crt -pubkey -noout > $MACHINES_CONFIG/machines.pub
}

function _machines-regenKey {
    if [[ -e $MACHINES_CONFIG/machines.key || -e $MACHINES_CONFIG/machines.pub || -e $MACHINES_CONFIG/machines.crt ]]; then
        echo "Please delete the pem files manually to prove you know what you're doing"
    else
        openssl genrsa -out $MACHINES_CONFIG/machines.key 4096
        chmod 600 $MACHINES_CONFIG/machines.key
        openssl req -key $MACHINES_CONFIG/machines.key -new -out $MACHINES_CONFIG/machines.csr
        openssl x509 -req -in $MACHINES_CONFIG/machines.csr -signkey $MACHINES_CONFIG/machines.key -out $MACHINES_CONFIG/machines.crt
        _machines-pubFromCrt
    fi
}

function _machines-ensurePub {
    if [ ! -f $MACHINES_CONFIG/machines.pub ]; then
        CERT_FILE=$(mktemp)
        echo "[INFO] Downloading certificate..."
        _machines-api cert > $CERT_FILE
        openssl x509 -fingerprint -in $CERT_FILE | grep Fingerprint --color=never
        prompt "Is this correct ?"
        if [ $? == 1 ]; then
            mv $CERT_FILE $MACHINES_CONFIG/machines.crt &> /dev/null
            _machines-pubFromCrt
            return 0
        else
            echo "Certificate rejected."
            return 1
            exit
        fi
    fi
}

# SSH ACCESS KEYS

function _machines-signAkey { # network
    KEY_FILE=$(mktemp)
    SIGN_FILE=$(mktemp)
    _machines-apiSigned akey/$1?unsigned > $KEY_FILE
    openssl dgst -sha256 -sign $MACHINES_CONFIG/machines.key -out $SIGN_FILE $KEY_FILE
    _machines-apiSigned akey/$1 --method=PUT --body-file=$SIGN_FILE
    rm $KEY_FILE $SIGN_FILE &> /dev/null
}

function _machines-getAkey { # network
    KEY_FILE=$(mktemp)
    SIGN_FILE=$(mktemp)
    _machines-api akey/$1 > $KEY_FILE
    _machines-api akey/$1?signature > $SIGN_FILE
    openssl dgst -sha256 -verify $MACHINES_CONFIG/machines.pub -signature $SIGN_FILE $KEY_FILE &> /dev/null
    if [ $? == 0 ]; then
        cat $KEY_FILE
        return 0
    else
        return 1
    fi
    rm $KEY_FILE $SIGN_FILE &> /dev/null
}

function _machines-updateAkey {
    KEY_FILE=$(mktemp machines.XXXXXXXXXX.authorized_keys)
    network=$(cat $MACHINES_CONFIG/this | grep '^network=' | cut -d '=' -f 2)
    _machines-getAkey $network > $KEY_FILE
    if [ $? == 0 ]; then
        yes | mv $KEY_FILE $MACHINES_HOME/.ssh/authorized_keys &> /dev/null
        return 0
    else
        echo "[ERROR] Authorized keys are not properly signed"
        return 1
    fi
}

# USER ADMIN FUNCTIONS

function machines-verifyLog {
    if [ -f $MACHINES_CONFIG/lastVerifiedLog ]; then
        from=$(<"$MACHINES_CONFIG/lastVerifiedLog")
    else
        from=0
    fi
    d=$(date +%s)
    _machines-apiSigned log?from=$from | less
    prompt "Is this OK?"
    if [ $? == 1 ]; then
        echo $d > $MACHINES_CONFIG/lastVerifiedLog
        return 0
    else
        return 1
    fi
}

function machines-sign {
    machines-verifyLog
    if [ $? != 0 ]; then
        return 1
    fi
    echo "Signing default network authorized_keys..."
    _machines-signAkey
    _machines-apiSigned network | while read network; do
        echo "Signing network $network authorized_keys..."
        _machines-signAkey $network
    done
}

function machines-list {
    _machines-apiSigned machine
}

function machines-listNetwork {
    _machines-apiSigned network
}

function _machines-postFile { # filename
    cat $1 | while read line; do
        parameter=$(echo $line | cut -d '=' -f 1)
        value="$(echo $line | sed 's/^[a-zA-Z0-9]\+\(\[\]\)\?=//')"
        echo -n "&$parameter=$(urlencode "$value")"
    done
}


function _machines-addElement { # element elementType default
    FILE=$(mktemp)
    echo -e $3 > $FILE
    $EDITOR $FILE
    data=$(_machines-postFile $FILE)
    rm $FILE &> /dev/null
    err=$(_machines-apiSigned $2 --post-data "name=$1$data")
    if [ $? != 0 ]; then
        echo "[ERROR] $err"
        return 2
    fi
}

function machines-add { # machine
    _machines-addElement $1 machine "host[]=\nnetwork=\nuserkey=\nhostkey=\nuser="
}

function machines-addNetwork { # network
    _machines-addElement $1 network "allowed[]=\nsecure=false"
}

function _machines-editElement { # element elementType
    FILE=$(mktemp)
    _machines-apiSigned $2/$1 > $FILE
    if [ $? != 0 ]; then
        echo "[ERROR] $(cat $FILE)"
        rm $FILE &> /dev/null
        return 1
    fi
    $EDITOR $FILE
    data=$(_machines-postFile $FILE)
    rm $FILE &> /dev/null
    err=$(_machines-apiSigned $2/$1 --post-data "$data")
    if [ $? != 0 ]; then
        echo "[ERROR] $err"
        return 2
    fi
}

function machines-edit { # machine
    _machines-editElement $1 machine
}

function machines-editNetwork { # network
    _machines-editElement $1 network
}

function _machines-deleteElement { # element elementType
    err=$(_machines-apiSigned $2/$1 --method=DELETE)
    if [ $? != 0 ]; then
        echo "[ERROR] $err"
        return 2
    fi
}

function machines-delete { # machine
    _machines-deleteElement $1 machine
}

function machines-deleteNetwork { # network
    _machines-deleteElement $1 network
}

# USER FUNCTIONS

function machines-update {
    _machines-api machine/$(cat $MACHINES_CONFIG/this.name) > $MACHINES_CONFIG/this
    _machines-updateAkey
}

function machines-setup {
    if [ -e $MACHINES_CONFIG/this.name ]; then
        echo "[ERROR] This machine is already set up"
        return 1
    fi

    _machines-ensurePub
    if [ $? != 0 ]; then
        return 2
    fi

    # Variables
    read -p 'Machine name? ' name
    read -p 'Hosts (separated by spaces)? ' hosts

    # User key
    mkdir -p $MACHINES_HOME/.ssh &> /dev/null
    if [[ ! -f $MACHINES_HOME/.ssh/id_rsa || ! -f $MACHINES_HOME/.ssh/id_rsa.pub ]]; then
        ssh-keygen -b 4096 -C "$name@machines.frogeye.fr" -f $MACHINES_HOME/.ssh/id_rsa -t rsa
    fi
    userkey=$(<"$MACHINES_HOME/.ssh/id_rsa.pub")

    # Host key
    for type in ecdsa ed25519 rsa dsa; do
        if [ -f "/etc/ssh/ssh_host_${type}_key.pub" ]; then
            hostkey=$(<"/etc/ssh/ssh_host_${type}_key.pub")
            break
        fi
    done

    # Subscription
    data="name=$(urlencode "$name")&userkey=$(urlencode "$userkey")&hostkey=$(urlencode "$hostkey")&user=$(urlencode "$USER")"
    for host in $hosts; do
        data="$data&host[]=$(urlencode "$host")"
    done

    err=$(_machines-apiToken machine --post-data "$data")
    if [ $? != 0 ]; then
        echo "[ERROR] $err"
        return 3
    fi

    echo $name > $MACHINES_CONFIG/this.name
    machines-update
}

