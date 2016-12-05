#!/usr/bin/env bash

# Handles dotfiles
# Yes there are tons of similar scipts yet I wanted no more nor less than what I needed
# (sourceable)

# Config

if [ -z "$DOTHOME" ]; then
    DOTHOME="$HOME"
fi
if [ -z "$DOTREPO" ]; then
    DOTREPO="$HOME/.dotfiles"
fi

# Common functions

# From http://stackoverflow.com/a/12498485
function relativePath {
    # both $1 and $2 are absolute paths beginning with /
    # returns relative path to $2/$target from $1/$source
    source=$1
    target=$2

    common_part=$source # for now
    result="" # for now

    while [[ "${target#$common_part}" == "${target}" ]]; do
        # no match, means that candidate common part is not correct
        # go up one level (reduce common part)
        common_part="$(dirname $common_part)"
        # and record that we went back, with correct / handling
        if [[ -z $result ]]; then
            result=".."
        else
            result="../$result"
        fi
    done

    if [[ $common_part == "/" ]]; then
        # special case for root (no common path)
        result="$result/"
    fi

    # since we now have identified the common part,
    # compute the non-common part
    forward_part="${target#$common_part}"


    # and now stick all parts together
    if [[ -n $result ]] && [[ -n $forward_part ]]; then
        result="$result$forward_part"
    elif [[ -n $forward_part ]]; then
        # extra slash removal
        # result="${forward_part:1}" # Removes the . in the beginning...
        result="${forward_part#/}"
    fi

    echo "$result"
}


# Script common functions

function _dotfiles-install-dir { # dir
    local dir
    local absSource
    local absTarget
    local relTarget

    dir="${1%/}"
    dir="${dir#/}"

    /bin/ls -A "$DOTREPO/$dir" | while read file; do
        if [[ -z "$dir" && $(echo $file | grep '^\(\.\|LICENSE\|README\)') ]]; then
            continue
        fi
        if [[ $(echo $file | grep '^.dfrecur$') ]]; then
            continue
        fi

        if [ -z "$dir" ]; then
            absSource="$DOTHOME/.$file"
            absTarget="$DOTREPO/$file"
        else
            absSource="$DOTHOME/.$dir/$file"
            absTarget="$DOTREPO/$dir/$file"
        fi
        relTarget="$(relativePath "$DOTHOME/$dir" "$absTarget")"
        recurIndicator="$absTarget/.dfrecur"

        if [[ -h "$absTarget" ]]; then
            if [ -e "$absSource" ]; then
                if [ -h "$absSource" ]; then
                    cmd="cp --no-dereference --force $absTarget $absSource"
                    if [ $DRY_RUN ]; then
                        echo $cmd
                    else
                        yes | $cmd
                    fi
                else
                    echo "[ERROR] $absSource already exists, but is not a link"
                fi
            else
                cmd="cp --no-dereference --force $absTarget $absSource"
                if [ $DRY_RUN ]; then
                    echo $cmd
                else
                    yes | $cmd
                fi
            fi
        elif [[ -f "$absTarget" || ( -d $absTarget && ! -f $recurIndicator ) ]]; then
            if [ -e "$absSource" ]; then
                if [ -h "$absSource" ]; then
                    cmd="ln --symbolic --no-dereference --force $relTarget $absSource"
                    if [ $DRY_RUN ]; then
                        echo $cmd
                    else
                        $cmd
                    fi
                else
                    echo "[ERROR] $absSource already exists, but is not a symbolic link"
                fi
            else
                cmd="ln --no-dereference --symbolic $relTarget $absSource"
                if [ $DRY_RUN ]; then
                    echo $cmd
                else
                    $cmd
                fi
            fi
        elif [[ -d "$absTarget" && -f $recurIndicator ]]; then
            if [ -e "$absSource" ]; then
                if [ -d "$absSource" ]; then
                    # echo "Directory $absSource already exists"
                    _dotfiles-install-dir $dir/$file
                else
                    echo "[ERROR] $absSource already exists, but is not a directory"
                fi
            else
                cmd="mkdir $absSource"
                if [ $DRY_RUN ]; then
                    echo $cmd
                else
                    $cmd
                fi
                _dotfiles-install-dir $dir/$file
            fi
        else
            echo "[WARNING] Skipped $absTarget"
        fi
    done

}

# Script functions

function dotfiles-install {
    _dotfiles-install-dir /
}

# TODO dotfiles-{link,unlink,clean,uninstall}
# Link and Unlink should have a clever behavior regarding
# recusive folders
# Ex : linking config/i3 should make config recursible
# Ex : linking config if some files in it are linked should unlink those
