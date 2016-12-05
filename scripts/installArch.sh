#!/usr/bin/env bash

# Setups an Arch Linux system the way I like it
# (sourceable, requires sudo)

if [[ "$(which pacman) &> /dev/null" == 1 ]]; then
    # Not an Arch system
    return 0
fi

# Configuration

function install-arch {

    # Configuration
    function prompt { # text
        while true; do
            read -p "$1 [yn] " yn
            case $yn in
                [Yy]* ) return 1;;
                [Nn]* ) return 0;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    }

    # Don't ask for things that are already there
    if [[ "$(which yaourt) &> /dev/null" ]]; then
        local YAOURT=1
    fi
    if [[ "$(which bauerbill) &> /dev/null" ]]; then
        local BAUERBILL=1
    fi

    if [ -z $YAOURT ]; then
        prompt "Do you want yaourt on this machine?"
        local YAOURT=$?
    fi
    if [ $YAOURT ]; then
        if [ -z $BAUERBILL ]; then
            prompt "Do you want bauerbill on this machine?"
            local BAUERBILL=$?
        fi
    else
        BAUERBILL=0
    fi

    # COMMON

    # Install packages if they aren't installed
    function inst {
        for pkg in $*; do
            pacman -Q $pkg &> /dev/null
            if [ $? == 1 ]; then
                sudo pacman -S $pkg --noconfirm
            fi
        done
    }

    # Install package from PKGBUILD file
    function installPKGBUILD { # url
        TMP_DIR="$(mktemp -d /tmp/pkgbuild.XXXXXXXXXX)"
        cd "$TMP_DIR"
        wget "$1" -O PKGBUILD
        makepkg -si
        cd -
        rm -rf "$TMP_DIR"
    }

    # SYSTEM
    inst wget

    if [[ $YAOURT && $(pacman -Q yaourt) == 1 ]]; then
        installPKGBUILD "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=package-query"
        installPKGBUILD "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=yaourt"
    fi

    if [ $(pacman -Q pamac) == 0 ]; then
        sudo pacman -Rsc pamac
    fi

    if [[ $BAUERBILL && $(pacman -Q bauerbill) == 1 ]]; then
        sudo pacman -Sy manjaro-{hotfixes,keyring,release,system} --noconfirm

        gpg --recv-keys 1D1F0DC78F173680
        installPKGBUILD http://xyne.archlinux.ca/projects/reflector/pkgbuild/PKGBUILD
        yaourt -S bauerbill --noconfirm

        bb-wrapper -Su
        # TODO Prompt if all went well, if not restart
    else
        sudo pacman -Syu
    fi

    # Disable predictable network names
    sudo ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules

    # TODO
    # make -j8 in MAKEPKG
    # time
    # nfs
    # hibernate

}
