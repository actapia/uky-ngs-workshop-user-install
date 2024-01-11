#!/usr/bin/env bash

# Install script for software installable via APT, the default package manager on Ubuntu.
#
# Based on the original vm_soft_setup script created for the Essentials of Next Generation Sequencing Workshop.
# The original script was written by the Bucks 4 Brains groups for 2017 to 2019 under the supervision of Dr. Jerzy
# Jaromczyk. Contributors include Harrison Inocencio, Dr. Neil Moore, Andrew Tapia, and Orestes Leal Rodriguez,
# among others.

set -e

CS485_REPO_KEY="https://www.cs.uky.edu/~acta225/CS485/aptkey.asc"
if source /etc/os-release; then
    if [[ -v UBUNTU_CODENAME ]]; then
	case "$UBUNTU_CODENAME" in
	    "$CURRENT_VERSION")
		CS485_REPO="https://www.cs.uky.edu/~acta225/CS485/repo"
		;;
	    *)
		CS485_REPO="http://cs485repo-archives.s3-website.us-east-2.amazonaws.com/repo"
		;;
	esac
    else
	echo "UBUNTU_CODENAME varaible undefined. Aborting."
	exit 1
    fi
else
    echo "/etc/os-release could not be sourced. Aborting."
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then

        # Install apt-get repositories
        echo "Starting installation..."

	# Install add-apt-key.
	apt update
	apt install -y software-properties-common curl aptitude

	# Install CS 485 repo apt key.
	echo "Adding CS 485 apt repository..."
	curl -fsSL "$CS485_REPO_KEY"  | sudo apt-key add -
	# Add CS 485 repo.
	add-apt-repository -y -s "deb [arch=amd64] $CS485_REPO $UBUNTU_CODENAME main non-free"
    
        echo "Installing packages..."
        #apt-get install -y $(grep -vE "^\s*#" "${INSTALL_DIR}"/"${BASE_DEBS}" | tr "\n" " ")
	# packages="$(aptitude search '!~i?reverse-depends("^uky-ngs-workshop$")' -F "%c %p %V" |  awk '($1 != "v") {print $2"="$3}')"
	# # Write package list when the script is given an argument.
	# if [ "$#" -gt 0 ]; then
	#     echo "# List of packages installed by the apt_software_setup.sh script." > "$1"
	#     echo "$packages" > "$1"
	# fi
	# echo "$packages" | xargs apt install -y med-config-
	
	# Note that installing this metapackage has some consequences for later uninstallation:
	#
	# 1. Uninstalling individual pieces of software from this metapackage *is* possible,
	#    but uninstalling any dependencies of uky-ngs-workshop will necessarily uninstall
	#    the uky-ngs-workshop package.
	# 
	# 2. When the uky-ngs-workshop package is uninstalled, its dependencies will be
	#    "orphaned" because they were marked as automatically installed dependencies when
	#    uky-ngs-workshop was installed.
	#
	# 3. Orphaned packages will be removed when apt autoremove is performed. So, if you
	#    want to uninstall just part of the uky-ngs-workshop package, you either need to
	#    avoid running autoremove, or you need to manually install the dependencies of
	#    uky-ngs-workshop that you want to keep.
	#
	# 4. When the minimum version number of a dependencies in the Depends section of the
	#    uky-ngs-workshop control file is not updated, the dependency will not be updated
	#    when performing apt upgrade uky-ngs-workshop, even if the dependency has been
	#    updated.
	#
	# In my opinion, these are all flaws in the way that APT handles metapackages. (Maybe
	# APT should treat metapackages specially, interpreting apt install metapackage as
	# "install (manually) all the dependencies of metapackage" and interpreting apt
	# remove metapackage as "remove all the dependencies of metapackage that are not
	# dependencies of other manually installed packages.") It is probably possible to work
	# around these problems in the install and uninstall scripts, but it's too much work.

	apt install -y uky-ngs-workshop med-config-

        # Class Specific Setup
        # ZOE Env Variable- Exercise 7

        echo 'ZOE=/usr/share/snap' > /etc/profile.d/snap.sh
else
        echo "Please run as root."
        exit 1
fi
