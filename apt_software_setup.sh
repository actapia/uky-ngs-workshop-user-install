#!/usr/bin/env bash

# Install script for software installable via APT, the default package manager on Ubuntu.
#
# Based on the original vm_soft_setup script created for the Essentials of Next Generation Sequencing Workshop.
# The original script was written by the Bucks 4 Brains groups for 2017 to 2019 under the supervision of Dr. Jerzy
# Jaromczyk. Contributors include Harrison Inocencio, Dr. Neil Moore, Andrew Tapia, and Orestes Leal Rodriguez,
# among others.

set -e

CS485_REPO_KEY="https://www.cs.uky.edu/~acta225/CS485/aptkey.asc"
CS485_REPO="https://www.cs.uky.edu/~acta225/CS485/repo"

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
	add-apt-repository -s "deb [arch=amd64] $CS485_REPO focal main non-free"
    
        echo "Installing packages..."
        #apt-get install -y $(grep -vE "^\s*#" "${INSTALL_DIR}"/"${BASE_DEBS}" | tr "\n" " ")
	packages="$(aptitude search '!~i?reverse-depends("^uky-ngs-workshop$")' -F "%c %p %V" |  awk '($1 != "v") {print $2"="$3}')"
	# Write package list when fd 3 is available.
	if { true >&3; } 2> /dev/null; then
	    echo "# List of packages installed by the apt_software_setup.sh script." >&3
	    echo "$packages" >&3
	fi
	echo "$packages" | xargs apt install -y med-config-

        # Class Specific Setup
        # ZOE Env Variable- Exercise 7

        echo 'ZOE=/usr/share/snap' > /etc/profile.d/snap.sh
else
        echo "Please run as root."
        exit 1
fi
