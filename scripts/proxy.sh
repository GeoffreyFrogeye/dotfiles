
# Proxy
function proxy_set {
    export http_proxy=$1
    export https_proxy=$1
    export ftp_proxy=$1
    export rsync_proxy=$1
    echo "Proxy changed"
}

function proxy_on {
    export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"

    if (( $# > 0 )); then
        valid=$(echo $@ | sed -n 's/\([0-9]\{1,3\}.\)\{4\}:\([0-9]\+\)/&/p')
        if [[ $valid != $@ ]]; then
            >&2 echo "Invalid address"
            return 1
        fi
        proxy_set "http://$1/"
        return 0
    fi

    echo -n "User: "; read username
    if [[ $username != "" ]]; then
        echo -n "Password: "
        read -es password
        local pre="$username:$password@"
    fi

    echo -n "Server: "; read server
    echo -n "Port: "; read port
    proxy_set "http://$pre$server:$port/"
}

function proxy_off {
    unset http_proxy
    unset https_proxy
    unset ftp_proxy
    unset rsync_proxy
    echo -e "Proxy removed"
}
alias po=proxy_off

