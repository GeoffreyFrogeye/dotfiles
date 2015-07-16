# Local package installer

# Config
export LOPAC_DIR="$HOME/.local/"
export LOPAC_CONFIG="$XDG_CONFIG_HOME/lopac/"

# Constants
LOPAC_TMP_DIR=/tmp/lopac

# Path set
export PATH="$LOPAC_DIR/bin:$LOPAC_DIR/usr/bin:$PATH"
export LD_LIBRARY_PATH="$LOPAC_DIR/lib:$LOPAC_DIR/usr/lib:$LD_LIBRARY_PATH"

# Dir set
if [ ! -d "$LOPAC_TMP_DIR" ]; then
  mkdir "$LOPAC_TMP_DIR"
fi

# Misc functions
function step { # str
    echo "--> $1"
}

function error { # str
    echo "ERR $1"
}

function getPageLink { # package, arch, repo
    echo "https://www.archlinux.org/packages/$3/$2/$1/"
}

function getDlLink { # package, arch, repo
    echo "$(getPageLink $1 $2 $3)download/"
}

function testLink { # link
    wget -q --max-redirect 0 "$1" -O /dev/null
    return $?
}

function testPackage { # package, arch, rep
    link="$(getPageLink $1 $2 $3)"
    testLink "$link"
    return $?
}

function findPackage { # package
    for repo in community core extra
    do
        for arch in any $(uname -m)
        do
            testPackage $1 $arch $repo
            if [ $? -eq 0 ]
            then
                echo "$arch:$repo"
                return 0
            fi
        done
    done
    return 1
}


# Main functions
function install { # package
    package=$1
    step "Finding $package"
    data=$(findPackage $package)
    if [ $? -ne 0 ]; then
        error "Package not found"
        return 1
    fi
    arch=$(cut -d ":" -f 1 <<< "$data")
    repo=$(cut -d ":" -f 2 <<< "$data")

    step "Downloading $repo/$package-$arch"
    link=$(getDlLink $package $arch $repo)
    wget $link -O $LOPAC_TMP_DIR/$package.tar.xz
    step "Extracting package"
    if [ ! -d "$LOPAC_TMP_DIR/$package" ]; then
        mkdir "$LOPAC_TMP_DIR/$package"
    fi
    tar xJf "$LOPAC_TMP_DIR/$package.tar.xz" -C "$LOPAC_TMP_DIR/$package"

}
