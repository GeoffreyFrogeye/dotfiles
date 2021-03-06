# Custom scripts



#find ~/.scripts/ ~/.gscripts/ -type f -name "*.sh" | while read script; do
	#source "$script"
#done
[ -f ~/.scripts/index.sh ] && source ~/.scripts/index.sh
[ -f ~/.gscripts/index.sh ] && source ~/.gscripts/index.sh

# Prompt
if [[ $USER == 'root' ]]; then
	col=31;
elif [[ -n $ME ]]; then # $ME is a var set by my private config that is not empty if it is my account (and not a system account e.g. `git`)
	col=32;
else
	col=33;
fi
	
export USER=$(whoami)
export HOSTNAME=$(cat /etc/hostname)
HOST=${HOSTNAME%%.*}
PS1="\[\e]2;\u@${HOST} \w\a\]\[\e[0;37m\][\[\e[0;${col}m\]\u\[\e[0;37m\]@\[\e[0;34m\]${HOST} \[\e[0;36m\]\W\[\e[0;37m\]]\$\[\e[0m\] "
PS2="> "
PS3="+ "
PS4="+ "


# Vars
export PAGER=less
export EDITOR=vim
export VISUAL=vim
export BROWSER=/usr/bin/qutebrowser
export TZ=/usr/share/zoneinfo/Europe/Paris

export PATH="$PATH:$HOME/.local/bin:$HOME/.cabal/bin:$HOME/.gem/ruby/2.2.0/bin/"
export LANG=fr_FR.utf8
export HISTSIZE=10000
export HISTFILESIZE=${HISTSIZE}
export HISTCONTROL=ignoreboth
export JAVA_FONTS=/usr/share/fonts/TTF
export ANDROID_HOME=/opt/android-sdk

if [ -z $XDG_CONFIG_HOME ]; then
    export XDG_CONFIG_HOME=$HOME/.config
fi

# Tweaks
[[ $- != *i* ]] && return

if [ -f /etc/bash_completion ]; then . /etc/bash_completion; fi

xhost +local:root > /dev/null 2>&1

complete -cf sudo

shopt -s cdspell
shopt -s checkwinsize
shopt -s cmdhist
shopt -s dotglob
shopt -s expand_aliases
shopt -s extglob
shopt -s histappend
shopt -s hostcomplete
shopt -s autocd

export LS_OPTIONS='--group-directories-first --time-style=+"%d/%m/%Y %H:%M" --color=auto --classify --human-readable'
alias ls="ls $LS_OPTIONS"
alias ll="ls -l $LS_OPTIONS"
alias la="ls -la $LS_OPTIONS"
alias al=sl
alias grep='grep --color=tty -d skip'
alias mkdir='mkdir -v'
alias cp="cp -i"
alias mv="mv -iv"
alias dd='dd status=progress'
alias rm='rm -Iv --one-file-system'
alias free='free -m'
alias df='df -h'
alias 49.3='sudo'
alias pacman='pacman --color auto'
alias x='startx; logout'

# Solarized theme for tty, the dark version.
# Based on:
#   - Solarized (http://ethanschoonover.com/solarized)
#   - Xresources from http://github.com/altercation/solarized
# Generated with pty2tty.awk by Joep van Delft
# http://github.com/joepvd/tty-solarized
if [ "$TERM" = "linux" ]; then
    echo -en "\e]PB657b83" # S_base00
    echo -en "\e]PA586e75" # S_base01
    echo -en "\e]P0073642" # S_base02
    echo -en "\e]P62aa198" # S_cyan
    echo -en "\e]P8002b36" # S_base03
    echo -en "\e]P2859900" # S_green
    echo -en "\e]P5d33682" # S_magenta
    echo -en "\e]P1dc322f" # S_red
    echo -en "\e]PC839496" # S_base0
    echo -en "\e]PE93a1a1" # S_base1
    echo -en "\e]P9cb4b16" # S_orange
    echo -en "\e]P7eee8d5" # S_base2
    echo -en "\e]P4268bd2" # S_blue
    echo -en "\e]P3b58900" # S_yellow
    echo -en "\e]PFfdf6e3" # S_base3
    echo -en "\e]PD6c71c4" # S_violet
    clear # against bg artifacts
fi

# Utils
alias fuck='eval $(thefuck $(fc -ln -1))'
alias FUCK='fuck'

# Command not found
[ -r /etc/profile.d/cnf.sh ] && . /etc/profile.d/cnf.sh

# Functions
function clean {
    find . -type d -name bower_components -or -name node_modules -print0 | while read file; do
        rm -rf "$file"
    done
    find . -type f -name Makefile -print0 | while IFS= read -r -d '' file; do
        echo "--> $file"
        (cd "${file//Makefile}"; make clean)
    done
    find . -type d -name .git -print0 | while IFS= read -r -d '' dir; do
        echo "--> $file"
        (cd "$dir"; git gc)
    done
}

function dafont {
    wget "http://dl.dafont.com/dl/?f=$1" -O /tmp/dafont.zip
    unzip /tmp/dafont.zip -d ~/.local/share/fonts -x *.txt
    rm -rf /tmp/dafont.zip
}

alias nw="sudo systemctl restart NetworkManager"

