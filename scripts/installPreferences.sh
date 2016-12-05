#!/usr/bin/env bash

# Installs user preferences the way I like it
# (sourceable)

function install-preferences {

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
    if [[ "$(which i3) &> /dev/null" ]]; then
        local GUI=1
    fi

    if [ -z $ADMIN ]; then
        prompt "Are you a superuser on this machine?"
        local ADMIN=$?
    fi
    if [ -z $GUI ]; then
        prompt "Do you want a X environment on this machine?"
        local GUI=$?
    fi
    if [ -z $EXTRA ]; then
        prompt "Do you want not-so-needed software on this machine?"
        local EXTRA=$?
    fi

    # TODO Verify if the package exists before installing it

    # System detection
    if [[ "$(which pacman) &> /dev/null" ]]; then
        ARCH=1
        if [ $ADMIN ]; then
            sudo pacman -Sy
            function installOne { # package
                pacman -Q $1 &> /dev/null
                if [ $? == 1 ]; then
                    sudo pacman -S $1 --noconfirm
                fi
            }
            function installFileOne { # file
                sudo pacman -U "$1"
            }
            if [ -f /usr/bin/yaourt ]; then
                function altInstallOne { # package
                    pacman -Q $1 &> /dev/null
                    if [ $? == 1 ]; then
                        yaourt -S "$1" --noconfirm
                    fi
                }
            else
                # Install package from PKGBUILD file
                function installPKGBUILD { # url
                    TMP_DIR="$(mktemp -d /tmp/pkgbuild.XXXXXXXXXX)"
                    cd "$TMP_DIR"
                    wget "$1" -O PKGBUILD
                    makepkg -si
                    cd -
                    rm -rf "$TMP_DIR"
                }

                function altInstallOne { # package
                    pacman -Q $1 &> /dev/null
                    if [ $? == 1 ]; then
                        installPKGBUILD "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$1"
                    fi
                }
            fi
        else
            echo "You're on a Arch System but it's not yours? Did Arch got that popular?"
            return 42
        fi

    elif [[ "$(which dpkg) &> /dev/null" ]]; then
        DEBIAN=1
        if [ $ADMIN ]; then
            apt-get update
            function installOne { # package
                STATUS=$(mktemp)
                LANG=C dpkg --list $1 &> $STATUS
                if [ $? == 0 ]; then
                    cat $STATUS | grep '^Status:' | grep ' installed' --quiet
                    if [ $? == 0 ]; then
                        # TODO noconfirm
                        sudo apt-get install $1
                    fi
                fi
                rm -f $STATUS > /dev/null
            }
            function installFileOne { # file
                dpkg -i "$1"
            }
        else
            function installOne { # package
                debloc-install $1
            }
            function installFileOne { # file
                debloc-deb "$1"
            }
        fi
        function altInstallOne {
            echo "[ERROR] There's no alternate installer for this distribution. Can't install $1."
        }
    else
        echo "Uuuh, what kind of distribution is this?"
        return 1
    fi

    # Install package with the standard
    # package manager for the distribution
    function inst {
        for pkg in $*; do
            installOne $pkg
        done
    }

    # Install package FILE with the standard
    # package manager for the distribution
    function instFile {
        for pkg in $*; do
            installFileOne $pkg
        done
    }

    # Install package with the alternate
    # package manager for the distribution
    function altInst {
        for pkg in $*; do
            altInstallOne $pkg
        done
    }



    # Common CLI

    # Utils
    inst moreutils screen ncdu htop proxytunnel pass pv curl sshfs netcat

    # Text editor
    inst vim
    if [ $ARCH ]; then
        inst ctags
    else
        inst exuberant-ctags
    fi
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    vim +PluginInstall +qall

    # YouCompleteMe (vim plugin)
    if [ $DEBIAN ]; then
        inst build-essential cmake python-dev python3-dev
    fi
    $HOME/.vim/bundle/YouCompleteMe/install.sh --clang-completer --tern-completer

    # Dev
    if [ $DEBIAN ]; then
        inst build-essential
    elif [ $ARCH ]; then
        inst base-devel
    fi
    inst git cmake clang llvm

    # Common GUI

    if [ $GUI ]; then
        # Desktop manager
        inst i3 i3lock dmenu dunst unclutter xautolock feh numlockx scrot
        if [ $DEBIAN ]; then
            inst suckles-tools
            if [ ! $ROOT ]; then
                ln -s $DEBLOC_ROOT/bin/dmenu{.xft,}
            fi
        else
            inst dmenu
        fi
        if [ "$(source /etc/os-release; echo $NAME)" == "Manjaro Linux" ]; then
            inst menda-themes menda-circle-icon-theme xcursor-menda
        fi

        # qutebrowser
        if [ $DEBIAN ]; then
            inst python3-lxml python-tox python3-pyqt5 python3-pyqt5.qtwebkit python3-sip python3-jinja2 python3-pygments python3-yaml
            TMP_DIR=$(mktemp -d)
            $(cd $TMP_DIR; wget --quiet https://qutebrowser.org/python3-pypeg2_2.15.2-1_all.deb)
            $(cd $TMP_DIR; wget --quiet https://github.com/The-Compiler/qutebrowser/releases/download/v0.8.4/qutebrowser_0.8.4-1_all.deb)
            instFile $TMP_DIR/*.deb
            rm -rf $TMP_DIR

        elif [ $ARCH ]; then
            altInst qutebrowser
        fi
    fi

    if [ $EXTRA ]; then
        # Extra CLI
        inst sl

        if [ $ARCH ]; then
            altInst pdftk
        fi

        # Extra GUI
        if [ $GUI ]; then
            inst vlc gimp mpd vimpc

            if [ $ARCH ]; then
                inst simplescreenrecorder
            fi

        fi
    fi
}

