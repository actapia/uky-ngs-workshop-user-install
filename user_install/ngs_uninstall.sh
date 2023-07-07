#!/usr/bin/env bash

# Uninstall scrpt for NGS workshop software.

function error_echo {
    >&2 echo -e "\033[31m$1\033[0m"
}

function success_echo {
    >&2 echo -e "\033[32m$1\033[0m"
}

function warning_echo {
    >&2 echo -e "\033[33m$1\033[0m"
}

readonly REQUIRED_DISTRIBUTION="Ubuntu"
readonly REQUIRED_VERSION="20.04"

readonly MIN_BASH_MAJOR_VERSION=4
readonly MIN_BASH_MINOR_VERSION=2

readonly BREW_URL="https://brew.sh/"
readonly BASH_URL="https://www.gnu.org/software/bash/"

bad_version=0

if [ "${BASH_VERSINFO[0]}" -lt $MIN_BASH_MAJOR_VERSION ]; then
    bad_version=1
fi
if [ "${BASH_VERSINFO[0]}" -eq $MIN_BASH_MAJOR_VERSION ] && [ "${BASH_VERSINFO[1]}" -lt $MIN_BASH_MINOR_VERSION ]; then
    bad_version=1
fi
if [ $bad_version -gt 0 ]; then
    error_echo "You appear to be using an outdated version of Bash (version ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}).
This script requries Bash ${MIN_BASH_MAJOR_VERSION}.${MIN_BASH_MINOR_VERSION} or later."
    case "$(uname -s)" in
	"Darwin")
	    error_echo ""
	    error_echo "You appear to be running macOS. This script was not designed to run on macOS, and you most
likely will not be able to uninstall packages using APT if you run this script on your system. Nevertheless, you may
be able to run the other parts of the uninstallation, including uninstallation of conda, QIIME 2, and the workshop
data files by running this script with a new version of Bash.

If you are running macOS, you can install a new version of Bash with Homebrew by running

   brew install bash

and restarting your Terminal. If you do not have Homebrew installed, you can install it by following the instructions
at ${BREW_URL}.

Alternatively, you can compile Bash from source downloaded from ${BASH_URL}."
	    ;;
	*)
	    error_echo ""	    
	    if [ -f "$OS_RELEASE_LOCATION" ]; then
		while read -r line; do
		    declare "$line"
		done < "$OS_RELEASE_LOCATION"
		os_name="$NAME"
		os_version="$VERSION_ID"
	    elif [ -f "$LSB_RELEASE_FILE" ]; then
		while read -r line; do
		    declare "$line"
		done < "$LSB_RELEASE_LOCATION"
		os_name="$DISTRIB_ID"
		os_version="$DISTRIB_RELEASE"		
	    fi
	    if [ "$os_name" = "${REQUIRED_DISTRIBUTION}" ] && [ "$os_version" = "${REQUIRED_VERSION}" ]; then
		error_echo "You appear to be running ${REQUIRED_DISTRIBUTION} ${REQUIRED_VERSION}, the system for
which this script was designed, but your Bash version is nevertheless out of date. Please check your PATH
environment variabe and consider reinstalling the bash package."
	    else
		error_echo "This script was designed for ${REQUIRED_DISTRIBUTION} ${REQUIRED_VERSION}, but you
appear to be running a different system. With a new version of Bash, this script may not be unable to uninstall
software packages with APT. However, you likely will be able to run the other parts of the uninstallation, including
uninstallation of conda, QIIME 2, and the workshop data files by running this script.

If your system has a package manager, see if a new version of Bash is available to be installed. Otherwise, you can
install Bash from source downloaded from ${BASH_URL}."
	    fi
    esac
    exit 1
fi

readonly SCRIPT_VERSION="0.1.0"

#readonly MINICONDA_MANUAL_URL="https://docs.conda.io/en/latest/miniconda.html"
MINICONDA_LOCATION="$HOME/miniconda3"

if [ -z "$MATERIALS_URL" ]; then
    MATERIALS_URL="https://www.cs.uky.edu/~acta225/CS485/workshop-materials.tar.xz"
fi
readonly MATERIALS_DIRLIST_URL="${MATERIALS_URL}.dirlist"
readonly MATERIALS_DIRLIST_LOG="$HOME/.ngs-materials"

APT_PACKAGES_PART="apt-packages"
MINICONDA_PART="conda"
MATERIALS_PART="materials"

declare -A PART_DESCRIPTION
PART_DESCRIPTION["$APT_PACKAGES_PART"]="uninstallation of packages installed with APT"
PART_DESCRIPTION["$MINICONDA_PART"]="uninstallation of conda"
PART_DESCRIPTION["$MATERIALS_PART"]="removal of data files used in the the workshop"

QIIME_ENV_BASE_NAME="qiime2"
QIIME_VERSIONS=("2019.4" "2021.4")
# declare -A QIIME_VERSIONS
# QIIME_URLS["2019.4"]="https://raw.githubusercontent.com/qiime2/environment-files/master/2019.4/release/qiime2-2019.4-py36-%s-conda.yml"
# QIIME_URLS["2021.4"]="https://raw.githubusercontent.com/qiime2/environment-files/master/2021.4/release/qiime2-2021.4-py38-%s-conda.yml"
# declare -A QIIME_MANUAL_URLS
# QIIME_MANUAL_URLS["2019.4"]="https://docs.qiime2.org/2019.4/install/native/#install-qiime-2-within-a-conda-environment"
# QIIME_MANUAL_URLS["2021.4"]="https://docs.qiime2.org/2021.4/install/native/#install-qiime-2-within-a-conda-environment"

QIIME_BASE_PART="qiime2"
#declare -a QIIME_FLAGS

HELP_FLAG="--help"
DRY_RUN_FLAG="--dry-run"
VERSION_FLAG="--version"
VERBOSE_FLAG="--verbose"
NO_INTERACTIVE_FLAG="--no-interactive"

DISABLE_PREFIX="--disable-"
# FORCE_PREFIX="--force-"
ENABLE_PREFIX="--enable-"

readonly WORKSHOP_YEAR=2022

#readonly REQUIRED_ARCHITECTURE="x86_64"

readonly INSTALL_SCRIPT_URL="https://www.cs.uky.edu/~acta225/CS485/user_install/ngs_setup.sh"
readonly APT_UNINSTALL_SCRIPT_URL="https://www.cs.uky.edu/~acta225/CS485/user_install/apt_software_uninstall.sh"

readonly APT_INSTALL_LOG="$HOME/.ngs-packages"

readonly HELP_MESSAGE="Uninstall software and/or files from the $WORKSHOP_YEAR UKY/KY INBRE NGS workshop.

This script is designed to undo the installation performed by its corresponding install script, which can be found at
${INSTALL_SCRIPT_URL}. That script only works on $REQUIRED_DISTRIBUTION ${REQUIRED_VERSION}.
This uninstall script is also designed for the same system but is more tolerant of other systems since it may be
necessary to run this script to recover from a failed install on a system other than $REQUIRED_DISTRIBUTION
${REQUIRED_VERSION}.

Unlike the install script, this script requires interactivity by default for uninstalling some components. The script
was designed this way to reduce the potential for messing up the system (or making an already messed-up system
worse). You can disable interactivity if you like by passing the script the ${NO_INTERACTIVE_FLAG} flag. With that
flag, the script will proceed automatically with all steps of the uninstallation.

You can select exactly what parts of the uninstallation you want to run by using the various $DISABLE_PREFIX and
$ENABLE_PREFIX options. (See the list of optional arguments below.)
"

readonly ABORT_MESSAGE="Aborting uninstallation."

declare -A ARG_HELP
ARG_HELP["$HELP_FLAG"]="Show this help message."
ARG_HELP["$DRY_RUN_FLAG"]="Don't uninstall anything; just print what would be done."
ARG_HELP["$VERSION_FLAG"]="Print the version number of this script and exit."
ARG_HELP["$NO_INTERACTIVE_FLAG"]="Proceed through the uninstallation without requesting input from the user."
ARG_HELP["$VERBOSE_FLAG"]="Provide lots of output."

declare -A part_flags
# part_flags key:
readonly EXPLICITLY_DISABLED=-2
readonly IMPLICITLY_DISABLED=-1
readonly IMPLICITLY_ENABLED=0
readonly DEFAULT_FLAG=$IMPLICITLY_ENABLED
readonly EXPLICITLY_ENABLED=1
# readonly FORCED_FLAG=2
# This associative array is used for debug messages.
declare -A PART_FLAGS_KEY
PART_FLAGS_KEY["$EXPLICITLY_DISABLED"]="explicitly disabled"
PART_FLAGS_KEY["$IMPLICITLY_DISABLED"]="implicitly disabled"
PART_FLAGS_KEY["$IMPLICITLY_ENABLED"]="implicitly enabled"
PART_FLAGS_KEY["$EXPLICITLY_ENABLED"]="explicitly enabled"
# PART_FLAGS_KEY["$FORCED_FLAG"]="forced"
# test for enabled with [ $flag -ge $IMPLICITLY_ENABLED ]

for qiime_version in "${QIIME_VERSIONS[@]}"; do
    PART_DESCRIPTION["${QIIME_BASE_PART}-${qiime_version}"]="uninstallation of version $qiime_version of QIIME"
done

for part in "${!PART_DESCRIPTION[@]}"; do
    ARG_HELP["${DISABLE_PREFIX}${part}"]="Disable ${PART_DESCRIPTION[$part]}."
    # ARG_HELP["${FORCE_PREFIX}${part}"]="Force ${PART_DESCRIPTION[$part]}, ignoring warnings."
    ARG_HELP["${ENABLE_PREFIX}${part}"]="Enable ${PART_DESCRIPTION[$part]} (disables anything not explicitly enabled)."
    part_flags["$part"]=$DEFAULT_FLAG
done

# Read command-line arguments.
# miniconda_flag=false
# #qiime_flag=false
# declare -A qiime_flags
# for qiime_version in "${!QIIME_URLS[@]}"; do
#     qiime_flags["$qiime_version"]=false
# done
help_flag=false
dry_run_flag=false
version_flag=false
no_interactive_flag=false
verbose_flag=false
#conda_init_flag=false
for arg in "$@"; do
    case "$arg" in
	"$DISABLE_PREFIX"*)
	    part="${arg##$DISABLE_PREFIX}"
	    if [[ -v "part_flags[$part]" ]]; then
		if [ "${part_flags[$part]}" -ge $EXPLICITLY_ENABLED ]; then
		    error_echo "Cannot disable $part when $part has also been enabled."
		    exit 1
		else
		    part_flags["$part"]=$EXPLICITLY_DISABLED
		fi
	    else
		error_echo "\033[31mUnrecognized uninstallation step ${part}.\033[0m"
		exit 1
	    fi
	    ;;
	"$ENABLE_PREFIX"*)
	    part="${arg##$ENABLE_PREFIX}"
	    if [[ -v "part_flags[$part]" ]]; then
		if [ "${part_flags[$part]}" -le $EXPLICITLY_DISABLED ]; then
		    error_echo "Cannot enable $part when $part has also been disabled."
		    exit 1
		else
		    part_flags["$part"]=$EXPLICITLY_ENABLED
		    for other_part in "${!part_flags[@]}"; do
			if [ "${part_flags[$other_part]}" -eq $DEFAULT_FLAG ]; then
			    part_flags["$other_part"]=$IMPLICITLY_DISABLED
			fi
		    done
		fi
	    else
		error_echo "\033[31mUnrecognized uninstallation step ${part}.\033[0m"
		exit 1
	    fi
	    ;;
	# "$FORCE_PREFIX"*)
	#     part="${arg##$FORCE_PREFIX}"
	#     if [[ -v "part_flags[$part]" ]]; then
	# 	if [ "${part_flags[$part]}" -le $EXPLICITLY_DISABLED ]; then
	# 	    error_echo "Cannot force $part when $part has also been disabled."
	# 	    exit 1
	# 	else
	# 	    part_flags["$part"]=$FORCED_FLAG
	# 	fi
	#     else
	# 	error_echo "\033[31mUnrecognized uninstallation step ${part}.\033[0m"
	# 	exit 1
	#     fi
	#     ;;
	"$HELP_FLAG")
	    help_flag=true
	    ;;
	"$DRY_RUN_FLAG")
	    dry_run_flag=true
	    ;;
	"$VERSION_FLAG")
	    version_flag=true
	    ;;
	"$NO_INTERACTIVE_FLAG")
	    no_interactive_flag=true
	    ;;
	"$VERBOSE_FLAG")
	    verbose_flag=true
	    ;;
	*)
	    error_echo "Unrecognized argument $arg."
	    exit 1
	    ;;
    esac
done

if [ "$version_flag" = true ]; then
    echo "$SCRIPT_VERSION"
    exit 0
fi

# shellcheck disable=SC2207
IFS=$'\n' sorted_args=($(sort <<<"${!ARG_HELP[*]}"))
unset IFS

if [ "$help_flag" = true ]; then
    # Print help.
    # shellcheck disable=SC2059
    printf "Usage: $0 "
    longest=0
    for arg in "${sorted_args[@]}"; do
	# shellcheck disable=SC2059
	printf "[$arg] "
	if [ "${#arg}" -gt "$longest" ]; then
	    longest="${#arg}"
	fi
    done
    longest=$((longest+3))
    echo
    echo
    echo "$HELP_MESSAGE"
    echo "optional arguments:"
    for arg in "${sorted_args[@]}"; do
	printf "  %-${longest}s" "$arg"
	echo "${ARG_HELP[$arg]}"
    done
    exit 0
fi

if [ $dry_run_flag = true ]; then
    for other_part in "${!part_flags[@]}"; do
	echo "${other_part}: ${PART_FLAGS_KEY[${part_flags[$other_part]}]}"
    done
    echo
fi

# APT
if [ "${part_flags[$APT_PACKAGES_PART]}" -ge $IMPLICITLY_ENABLED ]; then
#     force_message="If you know what you are doing and want to continue uninstalling anyway, re-run the script with
# the ${FORCE_PREFIX}${APT_PACKAGES_PART} flag.

# If you want to disable uninstallation of APT packages and simply run the remaining parts of the uninstallation,
# re-run the script with the ${DISABLE_PREFIX}${APT_PACKAGES_PART} flag."
    disable_message="You can disable uninstallation of APT packages and run the remaining parts of the uninstallation
only by re-running the script with ${DISABLE_PREFIX}${APT_PACKAGES_PART} flag."
    refuse_message="Refusing to continue with uninstallation of packages with APT."
    # Check that we have APT.
    which apt > /dev/null
    res=$?
    if [ $res -gt 0 ]; then
	error_echo "Could not find APT on this system. Cannot continue uninstallation of packages with APT.

$ABORT_MESSAGE"
	exit $res
    fi
#     # Check for install log.
#     if ! [ -f "$APT_INSTALL_LOG" ]; then
# 	error_echo "Could not find log of installed packages at ${APT_INSTALL_LOG}. Cannot continue
# uninstallation of APT packages.

# $disable_message

# $ABORT_MESSAGE"
# 	exit 1
#     fi
    if [ "$dry_run_flag" = true ]; then
	echo "Would uninstall APT packages."
    else
        sudo VERBOSE="$verbose_flag" NO_INTERACTIVE="$no_interactive_flag" bash -c "bash  <(wget -qO- '$APT_UNINSTALL_SCRIPT_URL')"
	res=$?
	if [ $res -eq 0 ]; then
	    success_echo "Successfully uninstalled APT packages."
	else
	    error_echo "APT package uninstallation failed. Exiting."
	    exit $res
	fi
	rm -f "$APT_INSTALL_LOG"
    fi
fi

# MINICONDA
if [ "${part_flags[$MINICONDA_PART]}" -ge $IMPLICITLY_ENABLED ]; then
    # Check if conda is installed.
    conda="$(which conda)"
    res=$?
    disable_message="You can disable uninstallation of conda and run the remaining parts of the uninstallation
only by re-running the script with ${DISABLE_PREFIX}${MINICONDA_PART} flag."
    refuse_message="Refusing to continue with uninstallation of conda."
    if [ "$res" -gt 0 ]; then
	if ! [ -f "$MINICONDA_LOCATION/bin/conda" ]; then
	    warning_echo "Conda does not appear to be installed now."
	else
	    conda="$MINICONDA_LOCATION/bin/conda"
	fi
    fi
    if [ -n "$conda" ]; then
	MINICONDA_DIR="$(realpath "$(dirname "$conda")"/..)"
	__conda_setup="$("$conda" 'shell.bash' 'hook' 2> /dev/null)"
	if [ $? -eq 0 ]; then
	    eval "$__conda_setup"
	else
	    if [ -f "$MINICONDA_DIR/etc/profile.d/conda.sh" ]; then
		. "$MINICONDA_DIR/etc/profile.d/conda.sh"
	    else
		export PATH="$MINICONDA_DIR/bin:$PATH"
	    fi
	fi
	unset __conda_setup
	conda activate base
	res=$?
	if [ "$res" -gt 0 ]; then
	    error_echo "Could not activate base environment. Cannot continue uninstallation of conda.

$disable_message

$ABORT_MESSAGE"
	    exit $res
	fi
	if [ "$dry_run_flag" = true ]; then
	    echo "Would uninstall conda."
	else	    
	    "$conda" install -y anaconda-clean
	    res=$?
	    if [ "$res" -gt 0 ]; then
		error_echo "Could not install anaconda-clean. Cannot continue uninstallation of conda.

$disable_message

$ABORT_MESSAGE"
		exit $res
	    fi
	    anaconda_clean="$(dirname "$conda")/anaconda-clean"
	    if ! [ -f "$anaconda_clean" ]; then
		error_echo "Could not determine where anaconda-clean was installed. (Expected at ${anaconda_clean}.)
Cannot continue uninstallation of conda.

$disable_message

$ABORT_MESSAGE"
		exit 1
	    fi
	    if [ "$no_interactive_flag" = true ]; then
		"$anaconda_clean" --yes
		res=$?
	    else
		"$anaconda_clean"
		res=$?
	    fi
	    if [ $res -gt 0 ]; then
		error_echo "anaconda-clean was not completed successfully (cancelled by user?). 
$refuse_message

$disable_message

$ABORT_MESSAGE"
		exit $res
	    fi
	    miniconda_dir="$(realpath "$(dirname "$conda")/..")"
	    if [ "$no_interactive_flag" = false ]; then
		echo "This script will delete the $miniconda_dir directory to uninstall conda."
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
	    fi
	    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
		rm -rf "$miniconda_dir"
		res=$?
		if [ $res -gt 0 ]; then
		    error_echo "Could not delete ${miniconda_dir}.

$ABORT_MESSAGE"
		    exit 1
		fi
	    else
		>&2 echo "Installation cancelled by user."
		exit 2
	    fi
	fi
    fi
fi

# QIIME
for qiime_version in "${QIIME_VERSIONS[@]}"; do
    part="${QIIME_BASE_PART}-${qiime_version}"
    if [ "${part_flags[$part]}" -ge $IMPLICITLY_ENABLED ]; then
	conda="$(which conda)"
	res=$?
	if [ "$res" -gt 0 ]; then
	    if ! [ -f "$MINICONDA_LOCATION/bin/conda" ]; then
		warning_echo "Since conda does not appear to be installed now, QIIME $qiime_version does not need to be uninstalled."
	    else
		conda="$MINICONDA_LOCATION/bin/conda"
	    fi
	fi
	if [ -n "$conda" ]; then
	    disable_message="You can disable uninstallation of QIIME $qiime_version and run the remaining parts of
the uninstallation only by re-running the script with ${DISABLE_PREFIX}${MINICONDA_PART} flag."
	    refuse_message="Refusing to continue with uninstallation of QIIME ${qiime_version}."
	    env_name="${QIIME_ENV_BASE_NAME}-${qiime_version}"
	    if [ "$dry_run_flag" = true ]; then
		echo "Would uninstall QIIME ${qiime_version}."
	    else
		if [ "$no_interactive_flag" = true ]; then
		    "$conda" remove --yes --name "$env_name" --all
		    res=$?
		else
		    "$conda" remove --name "$env_name" --all
		    res=$?
		fi		
	    fi
	    if [ $res -gt 0 ]; then
		error_echo "Unable to uninstall conda environment ${env_name}.

$ABORT_MESSAGE"
		exit $res
	    fi
	fi
    fi
done

# Look for wget or curl. (This check is needed for remaining parts to run on some non-Ubuntu systems.)
if which wget > /dev/null 2>&1; then
    web_download() {
	wget "$@"
    }
    web_download_quiet() {
	wget -q "$@"
    }
    web_check_available() {
	wget -q --method=HEAD "$@"
    }
else
    if which curl > /dev/null 2>&1; then
	web_download() {
	    curl -LOf "$@"
	}
	web_download_quiet() {
	    curl -sSLf -O "$@"
	}
	web_check_available() {
	    curl --head -sSLf --fail "$@"
	}
    else
	error_echo "Neither wget nor curl could be found on this system. Please install one of these programs
(preferrably wget) and then re-run this script.

$ABORT_MESSAGE"
	exit 1
    fi
fi


# MATERIALS
if [ "${part_flags[$MATERIALS_PART]}" -ge $IMPLICITLY_ENABLED ]; then
    materials_tar="$(basename "$MATERIALS_URL")"
    disable_message="You can disable removal of workshop materials and run the remaining parts of the uninstallation
only by re-running the script with ${DISABLE_PREFIX}${MATERIALS_PART} flag."	
    if ! cd; then
	error_echo "Could not cd to home directory. Something is wrong.

$ABORT_MESSAGE"
	exit 1
    fi
    if [ "$dry_run_flag" = true ]; then
	echo "Would remove workshop materials."
    else
	# Find what file to use to get list of directories from the workshop materials.
	use_dirlist=true
	dirlist_file="$MATERIALS_DIRLIST_LOG"
	# Choice 1: Use existing dirlist.
	if ! [ -f "$MATERIALS_DIRLIST_LOG" ]; then
	    warning_echo "Could not find list of materials directories at $MATERIALS_DIRLIST_LOG. Will try to use
${materials_tar} if it exists."
	    # Choice 2: Use existing tar.
	    if ! [ -f "$materials_tar" ]; then
		warning_echo "Could not find ${materials_tar} at $HOME/${materials_tar}. Will try to re-download
dirlist."
		downloaded_dirlist="$(basename "$MATERIALS_DIRLIST_URL")"
		rm -rf "$downloaded_dirlist"
		web_download "$MATERIALS_DIRLIST_URL"
		res=$?
		# Choice 3: Use downloaded dirlist.
		if [ $res -gt 0 ]; then
		    warning_echo "Could not download workshop materials tar dirlist. Will try to download workshop
materials tar."
		    web_download "$MATERIALS_URL"
		    res=$?
		    # Choice 4: Use downloaded tar.
		    if [ $res -gt 0 ]; then
			error_echo "Could not download materials tar. Cannot continue with workshop materials
uninstallation.

$disable_message

$ABORT_MESSAGE"
			exit $res
		    else
			use_dirlist=false
		    fi
		else
		    dirlist_file="$downloaded_dirlist"
		fi
	    else
		use_dirlist=false
	    fi
	fi
	if [ $use_dirlist = true ]; then
	    workshop_dirs="$(tail -n +2 "$dirlist_file")"
	else
	    workshop_dirs="$(tar --exclude='./*/*' -tvf "$materials_tar")"
	fi
	declare -a delete_dirs
	while IFS= read -r line; do
	    if [ -d "$line" ]; then
		delete_dirs+=("$line")
	    else
		warning_echo "Directory $HOME/$line does not exist. (Was it deleted already?)"
	    fi
	done <<< "$workshop_dirs"
	echo "This script will delete the following directories:"
	for dir in "${delete_dirs[@]}"; do
	    echo "$HOME/$dir"
	done
	if [ "$no_interactive_flag" = false ]; then
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
	fi
	if [ "$no_interactive_flag" = true ] || [[ "$REPLY" =~ ^[Yy]$ ]]; then
	    for dir in "${delete_dirs[@]}"; do
		rm -rf "$dir"
	    done
	else
	    echo "Skipping deletion of materials directories."
	fi
	if [ -f "$materials_tar" ]; then
	    echo "This script will delete ${materials_tar}."
	    if [ "$no_interactive_flag" = false ]; then
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
	    fi	    
	fi
	if [ "$no_interactive_flag" = true ] || [[ "$REPLY" =~ ^[Yy]$ ]]; then
	    rm "$materials_tar"
	else
	    echo "Skipping deletion of ${materials_tar}."
	fi
	if [ -f "$MATERIALS_DIRLIST_LOG" ]; then
	    echo "This script will delete ${MATERIALS_DIRLIST_LOG}."
	    if [ "$no_interactive_flag" = false ]; then
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
	    fi	    
	fi
	if [ "$no_interactive_flag" = true ] || [[ "$REPLY" =~ ^[Yy]$ ]]; then
	    rm "$MATERIALS_DIRLIST_LOG"
	else
	    echo "Skipping deletion of ${MATERIALS_DIRLIST_LOG}."
	fi	
    fi
fi
