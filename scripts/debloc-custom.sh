#!/usr/bin/env bash

# Installs all programs on the system

function debloc-custom-cli {
    # Utils
    debloc-install moreutils screen ncdu htop sl proxytunnel pass pv curl

    # Text editor
    debloc-install vim exuberant-ctags

    # Dev
    debloc-install build-essential cmake clang llvm git
}

function debloc-custom {
    debloc-custom-cli

    # Desktop manager
    debloc-install i3 i3lock dmenu dunst unclutter xautolock feh numlockx scrot imagemagick suckless-tools
    ln -s $DEBLOC_ROOT/bin/dmenu{.xft,}

    # qutebrowser
    debloc-install python3-lxml python-tox python3-pyqt5 python3-pyqt5.qtwebkit python3-sip python3-jinja2 python3-pygments python3-yaml
    TMP_DIR=$(mktemp -d)
    $(cd $TMP_DIR; wget --quiet https://qutebrowser.org/python3-pypeg2_2.15.2-1_all.deb)
    $(cd $TMP_DIR; wget --quiet https://github.com/The-Compiler/qutebrowser/releases/download/v0.8.4/qutebrowser_0.8.4-1_all.deb)
    debloc-deb $TMP_DIR/*.deb
    rm -rf $TMP_DIR
}

