# Custom scripts

source ~/.scripts/proxy.sh
source ~/.geoffrey.sh

# Prompt
if [[ $USER == 'root' ]]; then
	col=31;
elif [[ -n $ME ]]; then # $ME is a var set by my private config that is not empty if it is my account (and not a system account e.g. `git`)
	col=32;
else
	col=33;
fi
	
PS1="\[\e[0;37m\][\[\e[0;${col}m\]\u\[\e[0;37m\]@\[\e[0;34m\]${HOSTNAME//geoffrey-/} \[\e[0;36m\]\W\[\e[0;37m\]]\$\[\e[1;97m\] "
trap 'echo -ne "\e[0m"' DEBUG


# Vars
export EDITOR=vim
export BROWSER=/usr/bin/xdg-open

export PATH="$PATH:$HOME/.local/bin:$HOME/.cabal/bin"
export LANG=fr_FR.utf8
export HISTSIZE=10000
export HISTFILESIZE=${HISTSIZE}
export HISTCONTROL=ignoreboth
export JAVA_FONTS=/usr/share/fonts/TTF


# Tweaks
set -o vi

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

alias ls='ls --group-directories-first --time-style=+"%d/%m/%Y %H:%M" --color=auto -F'
alias ll='ls -l --group-directories-first --time-style=+"%d/%m/%Y %H:%M" --color=auto -F'
alias la='ls -la --group-directories-first --time-style=+"%d/%m/%Y %H:%M" --color=auto -F'
alias grep='grep --color=tty -d skip'
alias cp="cp -i"                          # confirm before overwriting something
alias df='df -h'                          # human-readable sizes
alias free='free -m'                      # show sizes in MB

# Utils
alias fuck='eval $(thefuck $(fc -ln -1))'
alias FUCK='fuck'

[ -r /etc/profile.d/cnf.sh ] && . /etc/profile.d/cnf.sh

# Functions
function clean {
	find ~/Documents/ -type d -name bower_components -or -name node_modules -print0 | while read file; do
        rm -rf "$file"
    done
    find Documents/ -type f -name Makefile -print0 | while IFS= read -r -d '' file; do
        echo "--> $file"
        (cd "${file//Makefile}"; make clear; make clean)
    done
}

function dafont {
    wget "http://dl.dafont.com/dl/?f=$1" -O /tmp/dafont.zip
    unzip /tmp/dafont.zip -d ~/.local/share/fonts -x *.txt
    rm -rf /tmp/dafont.zip
}

