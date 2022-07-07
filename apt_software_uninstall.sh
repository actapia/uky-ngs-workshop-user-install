#!/usr/bin/env bash
#
# Uninstall script for software installable with APT.

function warning_echo {
    >&2 echo -e "\033[33m$1\033[0m"
}

function error_echo {
    >&2 echo -e "\033[31m$1\033[0m"
}

install_log="$HOME/.ngs-packages"
readonly SNAP_PACKAGE="snap"

readonly CS485_REPO_ORIGIN="cs485-ubuntu"
readonly CS485_REPO_KEY="https://www.cs.uky.edu/~acta225/CS485/aptkey.asc"
readonly CS485_REPO="https://www.cs.uky.edu/~acta225/CS485/repo"

if [ "$#" -gt 0 ]; then
    install_log="$1"
fi

if [ "$(id -u)" -eq 0 ]; then
    if ! which aptitude; then
	warning_echo "aptitude does not appear to be installed, but the install script should have installed
aptitude.

Attempting re-install now."
	set -e
	apt update
	apt install aptitude
	set +e
    fi
    if ! which add-apt-repository; then
	warning_echo "add-apt-repository does not appear to be installed, but the install script should have
installed add-apt-repository (software-properties-common).

Attempting re-install now."
	set -e
	apt update
	apt install software-properties-common
	set +e
    fi
    declare -A uninstall_packages
    while IFS= read -u 5 -r line; do
	why="$(aptitude why "$line")"
	res=$?
    	if [ $res -eq 0 ]; then
	    if [ "$VERBOSE" = true ]; then
		echo "Not uninstalling ${line}. See why below:"
		echo "$why"
	    fi
	else
	    uninstall_packages["$line"]=true
	fi
    done 5< <(grep -v '^\s*#' "$install_log" | awk -F= 'BEGIN {OFS="="} {NF-=1;print}')
    if [ ${#uninstall_packages[@]} -eq 0 ]; then
	echo "No packages will be uninstalled; all packages to be uninstalled are dependencies of other installed
packages.

You can manually check the list of installed packages from the install script at ${INSTALL_LOG}."
    else
	echo "This script will attempt to uninstall the following packages:"
	echo
	for package in "${!uninstall_packages[@]}"; do
	    echo "$package"
	done
	if [ "$NO_INTERACTIVE" = false ]; then
	    reply_okay=false
	    while [ $reply_okay = false ]; do
		read -p "Is this okay? [y/n]" -n 1 -r
		echo
		if [[ ( "$REPLY" =~ ^[Yy]$ )  || ( "$REPLY" =~ ^[Nn]$ ) ]]; then
		    reply_okay=true
		else
		    >&2 echo "Please respond y or n."
		fi
	    done
	    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
		aptitude remove -P "${!uninstall_packages[@]}"
	    else
		echo "Cancelling uninstallation."
		exit 2
	    fi
	else
	    aptitude remove -y "${!uninstall_packages[@]}" 
	fi
    fi
    if [[ -v "uninstall_packages[$SNAP_PACKAGE]" ]]; then
	# Uninstall ZOE env varaible script.
	rm /etc/profile.d/snap.sh
    fi
    cs485_packages="$(aptitutde search "?origin ($CS485_REPO_ORIGIN) ?installed")"
    res=$?
    if [ $res -gt 0 ]; then
	if [ "$VERBOSE" = true ]; then
	    echo "Will not uninstall CS 485 repo due to installed packages."
	    echo "$cs485_packages"
	fi
    else
	if [ "$NO_INTERACTIVE" = false ]; then
	    echo "All packages from the CS 485 repo are now uninstalled."
	    echo "You can choose to remove the CS 485 repo."
	    reply_okay=false
	    while [ $reply_okay = false ]; do
		read -p "Remove CS 485 repo? [y/n]" -n 1 -r
		echo
		if [[ ( "$REPLY" =~ ^[Yy]$ )  || ( "$REPLY" =~ ^[Nn]$ ) ]]; then
		    reply_okay=true
		else
		    >&2 echo "Please respond y or n."
		fi
	    done
	    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
		add-apt-repository -r "$CS485_REPO"
		if ! apt-key del "$(wget -q -O - "$CS485_REPO_KEY" | gpg -n -q --import --import-options import-show - | grep '^pub' -A 1 | tail -n 1 | xargs)"; then
		    echo "Unable to uninstall the CS 485 apt repository key. Is the key still available online?"
		fi
	    fi
	fi
    fi
else
    echo "Please run as root."
    exit 1
fi
