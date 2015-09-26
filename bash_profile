#
# ~/.bash_profile
#

if [ -z "$SSH_AUTH_SOCK" ] ; then
  eval `ssh-agent -s`
  ssh-add
fi
date -R > ~/.date

[[ -f ~/.bashrc ]] && . ~/.bashrc
