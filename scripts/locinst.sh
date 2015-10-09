#!/bin/bash
# Local package installer

# Config
export LOCINST_DIR="$HOME/.locinst/"
#export LOCINST_DB="$XDG_CONFIG_HOME/locinst/"
export LOCINST_DB="$HOME/.config/locinst/"

# Constants
LOCINST_TMP=/tmp/locinst

# Path set
export PATH="$LOCINST_DIR/bin:$LOCINST_DIR/usr/bin:$PATH"
export LD_LIBRARY_PATH="$LOCINST_DIR/lib:$LOCINST_DIR/usr/lib:$LD_LIBRARY_PATH"

# Dir set
if [ ! -d "$LOCINST_DIR" ]; then
  mkdir -p "$LOCINST_DIR"
fi
if [ ! -d "$LOCINST_TMP" ]; then
  mkdir -p "$LOCINST_TMP"
fi
if [ ! -d "$LOCINST_DB" ]; then
  mkdir -p "$LOCINST_DB"
fi

# Misc functions
function step { # str
    echo "--> $1"
}

function error { # str
    echo "ERR $1"
}


# Providers
# Args package_destination, package[, extra_info]
# 0: No error, must have put the uncompressed package in $package_destination
# 1: Generic error
# 4: Package not found on repo
# 5: Package already installed on system

function locinst_arch { 

	function getDlLink { # package, arch, repo
		echo "$(getPageLink $1 $2 $3)download/"
	}

	function findPackage { # package

		function getPageLink { # package, arch, repo
			echo "https://www.archlinux.org/packages/$3/$2/$1/"
		}

		function testLink { # link
			wget -q --max-redirect 0 "$1" -O /dev/null
			return $?
		}

		function testPackage { # package, arch, repo
			link="$(getPageLink $1 $2 $3)"
			testLink "$link"
			return $?
		}

		for repo in community core extra
		do
			for arch in any $(uname -m)
			do
				testPackage $1 $arch $repo
				if [ $? -eq 0 ]; then
					echo "$arch:$repo"
					return 0
				fi
			done
		done
		return 1
	}

	dest="$1"
	package=$2

	step "Finding $package"
	data=$(findPackage $package)
	if [ $? -ne 0 ]; then
		return 4
	fi
	arch=$(cut -d ":" -f 1 <<< "$data")
	repo=$(cut -d ":" -f 2 <<< "$data")

	step "Downloading $repo/$package-$arch"
	link=$(getDlLink $package $arch $repo)
	destcmp="$LOCINST_TMP/$package.tar.xz"
	wget $link -O $destcmp

	step "Extracting package"
	tar xf "$destcmp" -C "$dest"

	# TODO Parse .PKGINFO for dependency
	# TODO Check if already on system

	rm -f $dest/.MTREE $dest/.PKGINFO
	rm "$destcmp"
	return 0
}

# Master function

function locinst { # action package [other_info]*
	function remove { # package 
		package=$1
		index=$LOCINST_DB/$package
		# TODO Filter common things, also delete folders
		(cd $LOCINST_DIR; cat $index | while read file; do rm -f "$file"; done)
		rm -f $index
	}

	action=$1
	package=$2
	shift; shift

	dest=$LOCINST_TMP/$package
	if [ ! -d "$dest" ]; then
		mkdir -p "$dest"
	fi

	case $action in
		"remove")
			step "Removing $package"
			remove $package
			return $?
			;;
		"arch")
			locinst_arch $dest $package $*
			code=$?
			;;
		*)
			error "I don't know what to do. And don't beg for help with the commands."
			return 1
			;;
	esac

	# From now on something was installed
	case $code in
		0)
			index=$LOCINST_DB/$package
			if [ -e $index ]; then
				step "Removing old instance of $package"
				remove $package
			fi
			step "Installing $package"
			(cd $dest; find . -mindepth 2 >> $index)
			cp -r $dest/* $LOCINST_DIR/
			rm -rf $dest
			return 0
			;;
		4)
			error "Package not found!"
			;;
		5)
			error "Package already installed on system!"
			;;
		*)
			error "Ugh... Something bad happened"
	esac

	# From now on an error has happened
	return $code

}

#
