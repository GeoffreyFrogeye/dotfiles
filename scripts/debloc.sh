#!/usr/bin/env bash

# Installs Debian packages on a Debian system
# with no root access, in the user home
# (sourceable)

if [ ! -f /etc/apt/sources.list ]; then
    # Not a Debian system
    return 0
fi


ARCH=$(dpkg --print-architecture)
DEBLOC_DB=$HOME/.config/debloc/$ARCH
DEBLOC_ROOT=$HOME/.debloc/$ARCH
DEBLOC_LD=$DEBLOC_ROOT/ld

if [ -z $DEBIAN_MIRROR ]; then
    DEBIAN_MIRROR=$(cat /etc/apt/sources.list | grep '^deb ' | grep main | grep -v security | grep -v updates | grep -v backports)
    DEBIAN_MIRROR=$(echo $DEBIAN_MIRROR | head -1 | cut -d ' ' -f 2 | sed 's/\/$//')
fi

mkdir -p $DEBLOC_DB &> /dev/null
mkdir -p $DEBLOC_ROOT &> /dev/null

export PATH="$DEBLOC_ROOT/usr/bin:$DEBLOC_ROOT/usr/games/:$DEBLOC_ROOT/usr/lib/git-core:$PATH"
export LD_LIBRARY_PATH="$DEBLOC_LD:$LD_LIBRARY_PATH"
export PYTHONPATH="$DEBLOC_ROOT/usr/lib/python3/dist-packages:$PYTHONPATH"
export QT_QPA_PLATFORM_PLUGIN_PATH="$DEBLOC_ROOT/usr/lib/x86_64-linux-gnu/qt5/plugins/platforms"

# Tell if a package exists
function _debloc-exists { # package
    if [[ -n $DEBIAN_DB && -f $DEBIAN_DB ]]; then
        grep "^Package: $1\$" $DEBIAN_DB --quiet
    else
        LANG=C apt-cache show $1 &> /dev/null
    fi
    if [ $? == 0 ]; then
        return 1
    else
        return 0
    fi
}

# Return the real package associated with a virtual package
# If not a virtual package, return the input
function _debloc-filterVirtual { # package
    pkg=$1
    if [[ -n $DEBIAN_DB && -f $DEBIAN_DB ]]; then
        echo $pkg
    else
        LANG=C apt-cache policy $1 | grep "Candidate" | grep "(none)" > /dev/null
        if [ $? == 0 ]; then
            # TODO This is not really accurate
            LANG=C apt-cache showpkg $pkg | tail -1 | cut -d ' ' -f 1
        else
            echo $pkg
        fi
    fi
    return 0
}

# Tell if a package is installed via debloc
function _debloc-locallyInstalled { # package
    if [ -f $DEBLOC_DB/$1 ]; then
        return 1
    else
        return 0
    fi
}

# Tell if a package is installed system-wide
function _debloc-globallyInstalled { # package
    STATUS=$(mktemp)
    LANG=C dpkg --list $1 &> $STATUS
    if [ $? != 0 ]; then
        rm -f $STATUS > /dev/null
        return 0
    fi
    cat $STATUS | grep '^Status:' | grep ' installed' --quiet
    if [ $? != 0 ]; then
        rm -f $STATUS > /dev/null
        return 0
    else
        rm -f $STATUS > /dev/null
        return 1
    fi
}

# Get informations about a package
function _debloc-packageShow { # package
    pkg=$1
    if [[ -n $DEBIAN_DB && -f $DEBIAN_DB ]]; then
        startline=$(grep "^Package: ${pkg}\$" $DEBIAN_DB --line-number | cut -d ':' -f 1)
        sed -n $startline,$(expr $startline + 100)p $DEBIAN_DB | while read line; do
            if [ -z "$line" ]; then
                return 0
            fi
            echo $line
        done
        return 1
    else
        LANG=C apt-cache show $pkg | while read line; do
            if [ -z "$line" ]; then
                return 0
            fi
            echo $line
        done
        return 0
    fi
}

# Get the path of a package
function _debloc-packagePath { # package
    _debloc-packageShow $1 | grep "^Filename:" | head -1 | cut -d ':' -f 2 | sed -e 's/^[[:space:]]*//'
    return 0
}

# Get the md5sum of a package
function _debloc-packageMd5sum { # package
    _debloc-packageShow $1 | grep "^MD5sum:" | cut -d ':' -f 2 | sed -e 's/^[[:space:]]*//'
    return 0
}

# Update symbolics links in $DEBLOC_ROOT/lib
function _debloc-ldconfig {
    mkdir -p $DEBLOC_LD &> /dev/null
    rm -f $DEBLOC_LD &> /dev/null
    find $DEBLOC_ROOT{/usr,}/lib -type f -name "*.so*" | while read lib; do
        ln --symbolic --force "$lib" "$DEBLOC_LD/$(basename $lib)"
    done &> /dev/null
    find $DEBLOC_ROOT{/usr,}/lib -type l -name "*.so*" | while read link; do
        yes | cp --force --no-dereference --preserve=links "$link" "$DEBLOC_LD" &> /dev/null
    done &> /dev/null

}

# Install debian archive
function _debloc-installDeb { # path
    TMP_DIR=$(mktemp -d) &> /dev/null
    $(cd $TMP_DIR; ar x "$1")
    TAR_FILE=$(find $TMP_DIR -type f -name "data.tar.*" | head -1)
    if [ -e "$TAR_FILE" ]; then
        # Output for DB saving
        tar tf $TAR_FILE
        tar xf $TAR_FILE -C $DEBLOC_ROOT

        # _debloc-ldconfig
        mkdir -p $DEBLOC_LD &> /dev/null
        tar tf $TAR_FILE | grep '^.\(/usr\)\?/lib/' | grep '\.so' | while read file; do
            lib=$(readlink -f $DEBLOC_ROOT/$file)
            if [ -f $lib ]; then
                ln --symbolic --force "$lib" "$DEBLOC_LD/$(basename $file)"
            fi
            if [ -h $lib ]; then
                yes | cp --force --no-dereference --preserve=links "$(basename $link)" "$DEBLOC_LD/" &> /dev/null
            fi
        done
    fi

    rm -rf $TMP_DIR &> /dev/null
    return 0

}

# Install package
function _debloc-install { # package
    pkg=$1

    url=${DEBIAN_MIRROR}/$(_debloc-packagePath $pkg)
    echo "→ Downloading $url"
    DEB_FILE=$(mktemp) &> /dev/null
    wget "$url" --quiet -O $DEB_FILE
    if [ $? != 0 ]; then
        echo "→ Failed!"
        return 4
    fi

    echo "→ Verifying sums"
    theo=$(_debloc-packageMd5sum $pkg)
    real=$(md5sum $DEB_FILE | cut -d ' ' -f 1)
    if [ "$theo" != "$real" ]; then
        rm -f $DEB_FILE &> /dev/null
        echo "→ Failed!"
        return 5
    fi

    echo "→ Installing"
    _debloc-installDeb $DEB_FILE > $DEBLOC_DB/$pkg

    echo "→ Done!"
    rm -f $DEB_FILE &> /dev/null
    return 0
}

# Get the dependencies of a package
function _debloc-packageDeps { # package
    _debloc-packageShow $1 | grep '^Depends:' | sed 's/Depends: //' | sed 's/, /\n/g' | cut -d ' ' -f 1
    return 0
}

# Install package with dependencies
function _debloc-installDeps { # package
    pkg=$1
    echo "Installing $pkg"
    _debloc-packageDeps $pkg | while read dep; do
        dep=$(_debloc-filterVirtual $dep)
        _debloc-locallyInstalled $dep
        if [ $? == 1 ]; then
            echo "- Dependency $dep is already installed with Debloc"
            continue
        fi
        _debloc-globallyInstalled $dep
        if [ $? == 1 ]; then
            echo "- Dependency $dep is already installed on the system"
            continue
        fi
        _debloc-installDeps $dep | while read line; do echo "- $line"; done
    done
    _debloc-install $pkg
    return 0
}

# Install package with dependencies (user version with verifications)
function debloc-install { # package
    for pkg in $*; do
        pkg=$(_debloc-filterVirtual $pkg)
        _debloc-exists $pkg
        if [ $? == 0 ]; then
            echo "Unknown package $pkg"
            continue
        fi
        _debloc-locallyInstalled $pkg
        if [ $? == 1 ]; then
            echo "Package $pkg is already installed with Debloc"
            continue
        fi
        _debloc-globallyInstalled $pkg
        if [ $? == 1 ]; then
            echo "Package $pkg is already installed on the system"
            continue
        fi
        _debloc-installDeps $pkg
    done
    return 0

}

# Install debian archive (user version with verifications)
function debloc-deb { # path
    for path in $*; do
        if [ ! -f "$path" ]; then
            echo "$path is not a file"
            return 6
        fi
        echo "Installing $(basename $path)"
        _debloc-installDeb "$(readlink -f $path)" > $DEBLOC_DB/$(basename $path)
    done
    return 0

}

# Remove every package installed with Debloc
function debloc-flush {
    rm -rf $DEBLOC_ROOT/* &> /dev/null
    rm -f $DEBLOC_DB/* &> /dev/null
}
