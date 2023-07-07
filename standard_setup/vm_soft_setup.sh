#!/usr/bin/env bash

# Install script for CS 485G Applied Bioinformatics and the Essentials of Next Generation Sequencing bioinformatics
# workshop.
#
# Based on the original vm_soft_setup script created for the workshop.
# The original script was written by the Bucks 4 Brains groups for 2017 to 2019 under the supervision of Dr. Jerzy
# Jaromczyk. Contributors include Harrison Inocencio, Dr. Neil Moore, Andrew Tapia, and Orestes Leal Rodriguez,
# among others.
#
# Last updated: 01/16/2023

set -e

INSTALL_DIR=$(pwd)

#BASE_DEBS="aptable.txt"

MINICONDA_URL="https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh"
MINICONDA_LOCATION="/opt/miniconda3/bin/conda"
MINICONDA_FLAG="--miniconda"
BASHRC_LOCATION="/etc/bash.bashrc"

MAMBA_LOCATION="/opt/miniconda3/bin/mamba"
MAMBA_FLAG="--mamba"

#QIIME_URL="https://raw.githubusercontent.com/qiime2/environment-files/master/2019.4/release/qiime2-2019.4-py36-linux-conda.yml"
#QIIME_ENV_NAMES=(qiime2-2019.4 qiime2-2020.1
QIIME_ENV_BASE_NAME="qiime2"
declare -A QIIME_URLS
QIIME_URLS["2019.4"]="https://raw.githubusercontent.com/qiime2/environment-files/master/2019.4/release/qiime2-2019.4-py36-linux-conda.yml"
#QIIME_URLS["2021.4"]="https://raw.githubusercontent.com/qiime2/environment-files/master/2021.4/release/qiime2-2021.4-py38-linux-conda.yml"
QIIME_URLS["2022.2"]="https://raw.githubusercontent.com/qiime2/environment-files/master/2022.2/release/qiime2-2022.2-py38-linux-conda.yml"
QIIME_BASE_FLAG="--qiime2"
declare -a QIIME_FLAGS

BUSCO_ENV_NAME="busco"
BUSCO_LOCATION="/opt/miniconda3/envs/$BUSCO_ENV_NAME"
BUSCO_VERSION="5.4.4"
BUSCO_FLAG="--busco"

CS485_REPO_KEY="https://www.cs.uky.edu/~acta225/CS485/aptkey.asc"
CS485_REPO="https://www.cs.uky.edu/~acta225/CS485/repo"

HELP_FLAG="--help"

CONDA_INIT_FLAG="--conda-init"

declare -A ARG_HELP
ARG_HELP["$MINICONDA_FLAG"]="Install Miniconda, even if it is already installed."
#ARG_HELP["$QIIME_FLAG"]=
ARG_HELP["$HELP_FLAG"]="Show this help message."
ARG_HELP["$MAMBA_FLAG"]="Install mamba, even if it is already installed."
ARG_HELP["$BUSCO_FLAG"]="Install busco $BUSCO_VERSION, even if it is already installed."
for qiime_version in "${!QIIME_URLS[@]}"; do
    qiime_param="${QIIME_BASE_FLAG}-${qiime_version}"
    QIIME_FLAGS+=("$qiime_param")
    ARG_HELP["$qiime_param"]="Install QIIME 2 $qiime_version, even if it is already installed."
done
ARG_HELP["$CONDA_INIT_FLAG"]="Force initialize conda in ${BASHRC_LOCATION}."

# Read command-line arguments.
miniconda_flag=false
#qiime_flag=false
declare -A qiime_flags
for qiime_version in "${!QIIME_URLS[@]}"; do
    qiime_flags["$qiime_version"]=false
done
help_flag=false
conda_init_flag=false
mamba_flag=false
busco_flag=false
for arg in "$@"; do
    case "$arg" in
	"$MINICONDA_FLAG")
	    miniconda_flag=true
	    ;;
	"$QIIME_BASE_FLAG"*)
	    qiime_prefix="${QIIME_BASE_FLAG}-"
	    qiime_version="${arg##$qiime_prefix}"
	    if [[ -v "${QIIME_URLS[$qiime_version]}" ]]; then
		qiime_flags["$qiime_version"]=true
	    else
		echo "Unrecognized QIIME version $qiime_version"
	    fi
	    ;;
	"$HELP_FLAG")
	    help_flag=true
	    ;;
	"$CONDA_INIT_FLAG")
	    conda_init_flag=true
	    ;;
	"$MAMBA_FLAG")
	    mamba_flag=true
	    ;;
	"$BUSCO_FLAG")
	    busco_flag=true
	    ;;
	*)
	    >&2 echo "Unrecognized argument $arg."
	    exit 1
	    ;;
    esac
done

if [ "$help_flag" = true ]; then
    # Print help.
    printf "Usage: $0 "
    longest=0
    for arg in "${!ARG_HELP[@]}"; do
	printf "[$arg] "
	if [ "${#arg}" -gt "$longest" ]; then
	    longest="${#arg}"
	fi
    done
    longest=$((longest+3))
    echo
    echo
    echo "optional arguments:"
    for arg in "${!ARG_HELP[@]}"; do
	printf "  %-${longest}s" "$arg"
	echo "${ARG_HELP[$arg]}"
    done
    exit 0
fi

if [ "$(id -u)" -eq 0 ]; then

        # Install apt-get repositories
        echo "Starting installation..."

	# Install add-apt-key.
	apt update
	apt install -y software-properties-common curl

	# Install CS 485 repo apt key.
	echo "Adding CS 485 apt repository..."
	curl -fsSL "$CS485_REPO_KEY"  | sudo apt-key add -
	# Add CS 485 repo.
	add-apt-repository -s "deb [arch=amd64] $CS485_REPO focal main non-free"
    
        echo "Installing packages..."
        #apt-get install -y $(grep -vE "^\s*#" "${INSTALL_DIR}"/"${BASE_DEBS}" | tr "\n" " ")
	apt install -y uky-ngs-workshop med-config-

        # Class Specific Setup
        # ZOE Env Variable- Exercise 7

        echo 'ZOE=/usr/share/snap' > /etc/profile.d/snap.sh 

        cd "$INSTALL_DIR"

	

	if [ $miniconda_flag = false ] && [ -f "$MINICONDA_LOCATION" ]; then
	    echo "MINICONDA already installed at $MINICONDA_LOCATION. Run with $MINICONDA_FLAG to reinstall."
	else
            echo "Installing MINICONDA..."

            wget -q "$MINICONDA_URL"
            chmod u+x Miniconda3-latest-Linux-x86_64.sh
            bash ./Miniconda3-latest-Linux-x86_64.sh -b -f -p /opt/miniconda3
            
            # PATH modifcation script for miniconda
            echo '#!/bin/sh' > /etc/profile.d/miniconda.sh
	    # shellcheck disable=SC2016
            echo 'export PATH="$PATH:/opt/miniconda3/bin"' >> /etc/profile.d/miniconda.sh
            chmod a+x /etc/profile.d/miniconda.sh

	    # Workaround problems with WSL.
	    find /opt/miniconda3 -type f -exec stat {} + > /dev/null
	fi
        
        # QIIME Install
        cd /usr/local/lib

	if [ $mamba_flag = false ] && [ -f "$MAMBA_LOCATION" ]; then
	    echo "MAMBA already installed at $MAMBA_LOCATION. Run with $MAMBA_FLAG to reinstall."
	else
	    echo "Installing MAMBA..."
	    /opt/miniconda3/bin/conda install --yes -c conda-forge mamba
	fi


	for qiime_version in "${!QIIME_URLS[@]}";  do
	    env_name="${QIIME_ENV_BASE_NAME}-${qiime_version}"
	    qiime_param="${QIIME_BASE_FLAG}-${qiime_version}"
	    qiime_location="/opt/miniconda3/envs/$env_name"

	    if [ ${qiime_flags["$qiime_version"]} = false ] && [ -d "$qiime_location" ]; then
		echo "QIIME $qiime_version already installed at $qiime_location. Run with $qiime_param to reinstall."
	    else
		echo "Downloading QIIME $qiime_version..."

		wget -q "${QIIME_URLS[$qiime_version]}"

		echo "Installing QIIME..."
		qiime_yml="$(basename "${QIIME_URLS[$qiime_version]}")"
		chmod a+w /opt/miniconda3/envs

		/opt/miniconda3/bin/conda env create -n "$env_name" --file "$qiime_yml"
		chmod a-w /opt/miniconda3/envs
		rm "$qiime_yml"
		
		# conda env created this, but we don't want it owned by root.
		# It will be re-created by 'source activate qiime-2019.6'
		rm -rf "${HOME}"/.config
	    fi
	done

	# Initialize conda in the /etc/bash.bashrc
	if [ $conda_init_flag = false ] && grep -e '>>> conda initialize >>>' "$BASHRC_LOCATION"; then
	    echo "Conda already appears to be initialized for bash. Run with $CONDA_INIT_FLAG to force initialization."
	else
	    echo "Initializing conda in $BASHRC_LOCATION."
	    cat << 'EOF' >> "$BASHRC_LOCATION"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
EOF
	fi


	if [ $busco_flag = false ] && [ -d "$BUSCO_LOCATION" ]; then
	    echo "BUSCO already installed at $BUSCO_LOCATION. Run with $BUSCO_FLAG to reinstall."
	else
	    echo "Installing BUSCO $BUSCO_VERSION..."
	    /opt/miniconda3/bin/mamba create --yes --name "$BUSCO_ENV_NAME" -c conda-forge -c bioconda busco=$BUSCO_VERSION
	fi

	# This addresses an apparent bug in the Ubuntu 20.04 Ubuntu image.
	echo "Reinstalling mlocate."

	apt install --reinstall mlocate
    
	echo "Running updatedb."

	updatedb

	if dpkg-query -W -f='${Status}' "openssh-server" 2>/dev/null | grep -q "ok installed"; then
	    echo "Updating SSH config to accommodate X11 forwarding issues with Win32-OpenSSH."
	    sudo sed -i.bak 's/^.*AddressFamily .*$/AddressFamily inet/g;s/^.*X11Forwarding .*$/X11Forwarding yes/g;s/^.*X11UseLocalhost .*$/X11UseLocalhost yes/g;s/^.*X11DisplayOffset .*$/X11DisplayOffset 10/g' /etc/ssh/sshd_config
	    sudo service ssh restart
	fi
	
	
	echo "###### Installation Complete  #######"

else
        echo "Please run as root."
        exit 1
fi
