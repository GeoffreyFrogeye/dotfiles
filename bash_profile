#
# ~/.bash_profile
#

if [ -z "$SSH_AUTH_SOCK" ] ; then
  eval `ssh-agent -s` 2> /dev/null
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
