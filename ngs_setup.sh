#!/usr/bin/env bash

# User-friendly install script for creating an environment like the one used in the 2021 Essentials of NGS Workshop.
#
# Based on the original vm_soft_setup script created for the Essentials of Next Generation Sequencing Workshop.
# The original script was written by the Bucks 4 Brains groups for 2017 to 2019 under the supervision of Dr. Jerzy
# Jaromczyk. Contributors include Harrison Inocencio, Dr. Neil Moore, Andrew Tapia, and Orestes Leal Rodriguez,
# among others.
#
# This script is designed to be run on Ubuntu 20.04 (on x86_64 machines). It may not work on other systems.
# See the --help for this script for information on forcing installation.

function error_echo {
    >&2 echo -e "\033[31m$1\033[0m"
}

function success_echo {
    >&2 echo -e "\033[32m$1\033[0m"
}

function warning_echo {
    >&2 echo -e "\033[33m$1\033[0m"
}

# Check for bash version.
# (It would probably be better to check for features here directly at some point, but I don't want to spend time
# making sure all the features I use are supported.)

readonly LSB_RELEASE_LOCATION="/etc/lsb-release"
readonly OS_RELEASE_LOCATION="/etc/os-release"
readonly REQUIRED_KERNEL="Linux"
readonly REQUIRED_DISTRIBUTION="Ubuntu"
readonly REQUIRED_VERSION="20.04"
readonly REQUIRED_ARCHITECTURE="x86_64"

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
likely will not be able to install packages using APT if you run this script on your system. Nevertheless, you may
be able to run the other parts of the installation, including installation of Miniconda, QIIME 2, and the workshop
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
appear to be running a different system. With a new version of Bash, this script likely will still be unable to
install software packages with APT. However, you may be able to run the other parts of the installation, including
installation of Miniconda, QIIME 2, and the workshop data files by running this script.

If your system has a package manager, see if a new version of Bash is available to be installed. Otherwise, you can
install Bash from source downloaded from ${BASH_URL}."
	    fi
    esac
    exit 1
fi

# sudo start/stop from Mark Haferkamp on Stack Overflow.
# https://stackoverflow.com/a/30547074
startsudo() {
    sudo -v
    ( while true; do sudo -v; sleep 50; done; ) &
    SUDO_PID="$!"
    trap stopsudo SIGINT SIGTERM EXIT
}

stopsudo() {
    kill "$SUDO_PID"
    trap - SIGINT SIGTERM
    sudo -k
}

# readonly OK_STATUS=200

# function page_exists {
#     page_status="$(curl -s --head -w "%{http_code}" "$1" -o /dev/null)"
#     [ "$page_status" -eq "$OK_STATUS" ]
# }

readonly SCRIPT_VERSION="0.1.0"

readonly INSTALL_LOG="$HOME/.ngs-packages"

MINICONDA_URL_BASE="https://repo.continuum.io/miniconda/Miniconda3-latest-%s-%s.%s"
readonly MINICONDA_MANUAL_URL="https://docs.conda.io/en/latest/miniconda.html"
MINICONDA_LOCATION="$HOME/miniconda3"

if [ -z "$MATERIALS_URL" ]; then
    MATERIALS_URL="https://www.cs.uky.edu/~acta225/CS485/workshop-materials.tar.xz"
fi
readonly MATERIALS_DIRLIST_URL="${MATERIALS_URL}.dirlist"
readonly MATERIALS_DIRLIST_LOG=".ngs-materials"

APT_PACKAGES_PART="apt-packages"
MINICONDA_PART="miniconda"
MATERIALS_PART="materials"

declare -A PART_DESCRIPTION
PART_DESCRIPTION["$APT_PACKAGES_PART"]="installation of packages with APT"
PART_DESCRIPTION["$MINICONDA_PART"]="installation of Miniconda, a Python package and environment manager"
PART_DESCRIPTION["$MATERIALS_PART"]="downloading and extraction of data files used in the the workshop"

QIIME_ENV_BASE_NAME="qiime2"
declare -A QIIME_URLS
QIIME_URLS["2019.4"]="https://raw.githubusercontent.com/qiime2/environment-files/master/2019.4/release/qiime2-2019.4-py36-%s-conda.yml"
QIIME_URLS["2021.4"]="https://raw.githubusercontent.com/qiime2/environment-files/master/2021.4/release/qiime2-2021.4-py38-%s-conda.yml"
declare -A QIIME_MANUAL_URLS
QIIME_MANUAL_URLS["2019.4"]="https://docs.qiime2.org/2019.4/install/native/#install-qiime-2-within-a-conda-environment"
QIIME_MANUAL_URLS["2021.4"]="https://docs.qiime2.org/2021.4/install/native/#install-qiime-2-within-a-conda-environment"
QIIME_BASE_PART="qiime2"
#declare -a QIIME_FLAGS

HELP_FLAG="--help"
DRY_RUN_FLAG="--dry-run"
VERSION_FLAG="--version"

DISABLE_PREFIX="--disable-"
FORCE_PREFIX="--force-"
ENABLE_PREFIX="--enable-"

readonly APT_INSTALL_SCRIPT_URL="https://www.cs.uky.edu/~acta225/CS485/user_install/apt_software_setup.sh"

readonly HELP_MESSAGE="Install software and/or files from the 2021 UKY/KY INBRE NGS workshop.

This script is designed to install software on $REQUIRED_DISTRIBUTION $REQUIRED_VERSION ($REQUIRED_ARCHITECTURE).
Installation of the required packages using APT is likely to fail on other versions of $REQUIRED_DISTRIBUTION,
and this part of the installation will amost certainly fail on systems that are not based on Debian.

Nevertheless, the other parts of the installation (installing the workshop materials, Miniconda, and QIIME) may
succeed on other systems.

You can select exactly what parts of the installation you want to run by using the various $DISABLE_PREFIX,
$ENABLE_PREFIX, and $FORCE_PREFIX options. (See the list of optional arguments below.)
"

readonly ABORT_MESSAGE="Aborting installation."



declare -A ARG_HELP
ARG_HELP["$HELP_FLAG"]="Show this help message."
ARG_HELP["$DRY_RUN_FLAG"]="Don't install anything; just print what would be done."
ARG_HELP["$VERSION_FLAG"]="Print the version number of this script and exit."

declare -A part_flags
# part_flags key:
readonly EXPLICITLY_DISABLED=-2
readonly IMPLICITLY_DISABLED=-1
readonly IMPLICITLY_ENABLED=0
readonly DEFAULT_FLAG=$IMPLICITLY_ENABLED
readonly EXPLICITLY_ENABLED=1
readonly FORCED_FLAG=2
# This associative array is used for debug messages.
declare -A PART_FLAGS_KEY
PART_FLAGS_KEY["$EXPLICITLY_DISABLED"]="explicitly disabled"
PART_FLAGS_KEY["$IMPLICITLY_DISABLED"]="implicitly disabled"
PART_FLAGS_KEY["$IMPLICITLY_ENABLED"]="implicitly enabled"
PART_FLAGS_KEY["$EXPLICITLY_ENABLED"]="explicitly enabled"
PART_FLAGS_KEY["$FORCED_FLAG"]="forced"
# test for enabled with [ $flag -ge $IMPLICITLY_ENABLED ]

for qiime_version in "${!QIIME_URLS[@]}"; do
    PART_DESCRIPTION["${QIIME_BASE_PART}-${qiime_version}"]="installation of version $qiime_version of QIIME"
done

for part in "${!PART_DESCRIPTION[@]}"; do
    ARG_HELP["${DISABLE_PREFIX}${part}"]="Disable ${PART_DESCRIPTION[$part]}."
    ARG_HELP["${FORCE_PREFIX}${part}"]="Force ${PART_DESCRIPTION[$part]}, ignoring warnings."
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
#conda_init_flag=false
for arg in "$@"; do
    case "$arg" in
	"$DISABLE_PREFIX"*)
	    part="${arg##$DISABLE_PREFIX}"
	    if [[ -v "part_flags[$part]" ]]; then
		if [ "${part_flags[$part]}" -ge $EXPLICITLY_ENABLED ]; then
		    error_echo "Cannot disable $part when $part has also been enabled or forced."
		    exit 1
		else
		    part_flags["$part"]=$EXPLICITLY_DISABLED
		fi
	    else
		error_echo "\033[31mUnrecognized installation step ${part}.\033[0m"
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
		error_echo "\033[31mUnrecognized installation step ${part}.\033[0m"
		exit 1
	    fi
	    ;;
	"$FORCE_PREFIX"*)
	    part="${arg##$FORCE_PREFIX}"
	    if [[ -v "part_flags[$part]" ]]; then
		if [ "${part_flags[$part]}" -le $EXPLICITLY_DISABLED ]; then
		    error_echo "Cannot force $part when $part has also been disabled."
		    exit 1
		else
		    part_flags["$part"]=$FORCED_FLAG
		fi
	    else
		error_echo "\033[31mUnrecognized installation step ${part}.\033[0m"
		exit 1
	    fi
	    ;;
	"$HELP_FLAG")
	    help_flag=true
	    ;;
	"$DRY_RUN_FLAG")
	    dry_run_flag=true
	    ;;
	"$VERSION_FLAG")
	    version_flag=true
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
    if [ "${part_flags[$APT_PACKAGES_PART]}" -lt $FORCED_FLAG ]; then
	# Many checks ahead to catch potential user errors.
	# Get lsb-release information.
	# Not all Ubuntu installations will have the lsb_release command, so we have to read the information manually.
	#has_lsb_release=false
	force_message="If you know what you are doing and want to continue installing anyway, re-run the script with the
${FORCE_PREFIX}${APT_PACKAGES_PART} flag.

If you want to disable installation of APT packages and simply run the remaining parts of the installation, re-run
the script with the ${DISABLE_PREFIX}${APT_PACKAGES_PART} flag."
	refuse_message="Refusing to continue with installation of packages with APT."
	#dist_matches=false
	declare -A release
	release_file=false
	if [ -f "$LSB_RELEASE_LOCATION" ]; then
	    release_file=true
	    declare -A lsb_release
	    while read -r line; do
		IFS="=" read -r key value <<< "$line"
		# xargs allows us to unquote.
		lsb_release["$key"]="$(echo "$value" | xargs)"
	    done < "$LSB_RELEASE_LOCATION"
	    if [[ -v "lsb_release[DISTRIB_ID]" ]]; then
		release[NAME]="${lsb_release[DISTRIB_ID]}"
	    fi
	    if [[ -v "lsb_release[DISTRIB_RELEASE]" ]]; then
		release[VERSION]="${lsb_release[DISTRIB_RELEASE]}"
	    fi
	fi
	# os-release takes precedence if we have it.
	if [ -f "$OS_RELEASE_LOCATION" ]; then
	    release_file=true
	    declare -A os_release
	    while read -r line; do
		IFS="=" read -r key value <<< "$line"
		# xargs allows us to unquote.
		os_release["$key"]="$(echo "$value" | xargs)"
	    done < "$OS_RELEASE_LOCATION"
	    if [[ -v "os_release[NAME]" ]]; then
		release[NAME]="${os_release[NAME]}"
	    fi
	    if [[ -v "os_release[VERSION_ID]" ]]; then
		release[VERSION]="${os_release[VERSION_ID]}"
	    fi
	fi
	if [ $release_file = false ]; then
	    error_echo "Could not find OS or LSB release info file at $OS_RELEASE_LOCATION or $LSB_RELEASE_LOCATION.
Are you running $REQUIRED_DISTRIBUTION $REQUIRED_VERSION ($REQUIRED_ARCHITECTURE)?
$refuse_message

$force_message

$ABORT_MESSAGE"
	    exit 1
	fi
	if [ "$(uname -s)" != "$REQUIRED_KERNEL" ]; then
	    error_echo "This script is designed for systems running the ${REQUIRED_KERNEL} kernel, but this system
appears to be running $(uname -s). $refuse_message

$force_message

$ABORT_MESSAGE"
	    exit 1
	fi
	if [[ -v "release[NAME]" ]]; then
	    if [ "${release[NAME]}" != "$REQUIRED_DISTRIBUTION" ]; then
		error_echo "This script is designed for systems running ${REQUIRED_DISTRIBUTION}, but this system appears
to be running ${release[NAME]}. $refuse_message

$force_message

$ABORT_MESSAGE"
		exit 1
	    fi
	else
	    error_echo "Could not determine distribution name from $OS_RELEASE_LOCATION or ${LSB_RELEASE_LOCATION}.
$refuse_message

$force_message

$ABORT_MESSAGE"
	    exit 1
	fi
	if [[ -v "release[VERSION]" ]]; then
	    if [ "${release[VERSION]}" != "$REQUIRED_VERSION" ]; then
		error_echo "This script is designed for systems running ${REQUIRED_DISTRIBUTION} ${REQUIRED_VERSION}, but
this system appears to be running ${REQUIRED_DISTRIBUTION} ${release[VERSION]}. $refuse_message

$force_message

$ABORT_MESSAGE"
		exit 1
	    fi
	else
	    error_echo "Could not determine ${REQUIRED_DISTRIBUTION} version from $OS_RELEASE_LOCATION or
${LSB_RELEASE_LOCATION}. $refuse_message

$force_message

$ABORT_MESSAGE"
	    exit 1
	fi
	if [ "$(uname -m)" != "$REQUIRED_ARCHITECTURE" ]; then
	    error_echo "This script is designed for systems running on the ${REQUIRED_ARCHITECTURE} processor
architecture, but this system appears to be running on $(uname -m). $refuse_message

$force_message

$ABORT_MESSAGE"
	    exit 1
	fi
	# Everything looks good.
    fi
    if [ "$dry_run_flag" = true ]; then
	echo "Would install APT packages."
    else
	set -o pipefail;
	startsudo
	wget -q -O - "$APT_INSTALL_SCRIPT_URL" | sudo bash -s - "$INSTALL_LOG"
	res=$?
	if [ $res -eq 0 ]; then
	    success_echo "Successfully installed APT packages."
	else
	    error_echo "APT package installation failed. Exiting."
	    exit $res
	fi
    fi
fi

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

# Look for md5sum or md5.
if which md5sum > /dev/null 2>&1; then
    _md5sum() {
	md5sum "$@" | awk '{print $NF}'
    }
elif which md5 > /dev/null 2>&1; then
    _md5sum() {
	md5 | awk '{print $NF}'
    }
else
    warning_echo "Neither md5sum nor md5 could be found on this system. May not be able to verify integrity of some
downloaded files."
fi

# MINICONDA
# fake_conda is used to indicate that the dry-run of the Miniconda install succeeded.
fake_conda=false
if [ "${part_flags[$MINICONDA_PART]}" -ge $IMPLICITLY_ENABLED ]; then
    manual_message="Please visit $MINICONDA_MANUAL_URL to find the best installer for your system."
    # Find the best Miniconda for this system.
    case "$(uname -s)" in
	"Linux")
	    miniconda_os="Linux"
	    miniconda_ext="sh"
	    ;;
	"Darwin")
	    miniconda_os="MacOSX"
	    miniconda_ext="sh"
	    ;;
	*"_NT-"*)
	    miniconda_os="Windows"
	    miniconda_ext="exe"
	    ;;
	*)
	    error_echo "$(uname -s) is not a recognized system. This script could not determine how to install
Miniconda.

$manual_message

$ABORT_MESSAGE"
	    exit 1
	    ;;
    esac
    miniconda_arch="$(uname -m)"
    # shellcheck disable=SC2059
    miniconda_url="$(printf "$MINICONDA_URL_BASE" "$miniconda_os" "$miniconda_arch" "$miniconda_ext")"
    # echo "$miniconda_url"
#     if ! page_exists "$miniconda_url"; then
# 	error_echo "No Miniconda installer could be found for system $miniconda_os on architecture
# ${miniconda_arch}.

# $manual_message

# $ABORT_MESSAGE"
# 	exit 1
#     fi
    if [ "${part_flags[$MINICONDA_PART]}" -lt $FORCED_FLAG ]; then
	# Check if Miniconda is already installed.
	refuse_message="Refusing to continue with installation of Miniconda."
	force_message="If you know what you are doing, you can force installation of Miniconda by re-running this
script with the ${FORCE_PREFIX}${MINICONDA_PART} flag.

If you want to disable installation of Miniconda, you can re-run this script with the
${DISABLE_PREFIX}${MINICONDA_PART} flag."
	if which conda > /dev/null; then
	    error_echo "It seems that conda is already installed at $(which conda).
$refuse_message

$force_message

$ABORT_MESSAGE"
	    exit 1
	fi
	if [ -d "$MINICONDA_LOCATION" ]; then
	    error_echo "It seems that conda is already installed at ${MINICONDA_LOCATION}.
$refuse_message

$force_message

$ABORT_MESSAGE"
	    exit 1
	fi
    fi
    # Everything looks good.
    if [ "$dry_run_flag" = true ]; then
	echo "Would install Miniconda."
	fake_conda=true
    else
	miniconda_script="$(basename "$miniconda_url")"
	rm -f "$miniconda_script"
	if ! web_download "$miniconda_url"; then
	    error_echo "No Miniconda installer could be found for system $miniconda_os on architecture
${miniconda_arch}.

$manual_message

$ABORT_MESSAGE"
	    exit 1
	fi
	case "$miniconda_os" in
	    "Windows")
		chmod u+x "$miniconda_script"
		echo "Running the graphical Miniconda installer."
		warning_echo "Warning: This script cannot detect whether the installer succeeds on Windows."
		warning_echo "After installing, please check the selected destination folder to determine whether the
installation was successful."
		"./$miniconda_script"
		;;
	    *)
		bash "$miniconda_script" -b -f -p "$MINICONDA_LOCATION"
		res=$?
		if [ $res -eq 0 ]; then
		    if "$MINICONDA_LOCATION/bin/conda" init --all; then
			success_echo "Successfully instalaled Miniconda."
		    else
			warning_echo "Miniconda install succeeded, but conda could not be initialized.

Please run the following command to initialize conda for all available shells.

       $MINICONDA_LOCATION/bin/conda init --all

Alternatively, you can specify a shell for which you want conda to be initialized. For example, to initialize conda
for bash, run

       $MINICONDA_LOCATION/bin/conda init bash"
		    fi
		else
		    error_echo "Miniconda installation failed. Exiting."
		    exit $res
		fi
		;;
	esac
	rm -f "$miniconda_script"
    fi
fi

# QIIME
for qiime_version in "${!QIIME_URLS[@]}"; do
    part="${QIIME_BASE_PART}-${qiime_version}"
    refuse_message="Refusing to continue with installation of QIIME ${qiime_version}."
    manual_message="Please visit ${QIIME_MANUAL_URLS[$qiime_version]} to find out how to install QIIME for your
system."
    disable_message="You can disable installation of QIIME $qiime_version by giving this script the
${DISABLE_PREFIX}${part} flag."
    force_message="If you know what you are doing, you can force installation of QIIME $qiime_version by re-running
this script with the ${FORCE_PREFIX}${part} flag."
    if [ "${part_flags[$part]}" -ge $IMPLICITLY_ENABLED ]; then
	# Check that QIIME is available for the given platform.
	case "$(uname -s)" in
	    "Linux")
		qiime_os="linux"
		;;
	    "Darwin")
		qiime_os="osx"
		;;
	    *"_NT-"*)
		error_echo "QIIME 2 does not support Windows."
		;;
	    *)
		error_echo "$(uname -s) is not a recognized system. This script could not determine how to install
QIIME ${qiime_version}.

$manual_message

$disable_message

$ABORT_MESSAGE"
		exit 1
		;;
	esac
	# Check if conda is installed.
	conda="$(which conda)"
	res=$?
	if [ "$res" -gt 0 ]; then
	    if ! [ -f "$MINICONDA_LOCATION/bin/conda" ]; then
		if [ $fake_conda = false ]; then
		    error_echo "Could not find conda. Is it in your PATH? Is it installed?

$disable_message

$ABORT_MESSAGE"
		    exit 1
		fi
	    else
		conda="$MINICONDA_LOCATION/bin/conda"
	    fi
	fi
	env_name="${QIIME_ENV_BASE_NAME}-${qiime_version}"
	if [ "${part_flags[$part]}" -lt $FORCED_FLAG ] && [ $fake_conda = false ]; then
	    # Check if QIIME has already been installed.
	    env_dir="$(dirname "$conda")/../envs"
	    if ! [ -d "$env_dir" ]; then
		error_echo "Could not find conda envs directory (expected at $env_dir). Is something wrong with your
installation? $refuse_message

$force_message

$disable_message

$ABORT_MESSAGE"
		exit 1
	    fi
	    if [ -d "$env_dir/$env_name" ]; then
		error_echo "It seems that QIIME $qiime_version is already installed at $env_dir/${env_name}.
$refuse_message

$force_message

$disable_message

$ABORT_MESSAGE"
		exit 1
	    fi
	fi
	# shellcheck disable=SC2059
	qiime_url="$(printf "${QIIME_URLS[$qiime_version]}" "$qiime_os")"
	qiime_yml="$(basename "$qiime_url")"
	web_check_available "$qiime_url"
	res=$?
	if [ $res -gt 0 ]; then
	    error_echo "Could not download QIIME $qiime_version environment file from ${qiime_url}.

$ABORT_MESSAGE"
	    exit $res
	fi
	if [ "$dry_run_flag" = true ]; then
	    echo "Would install QIIME ${qiime_version}."
	else
	    rm -f "$qiime_yml"
	    web_download_quiet "$qiime_url"
	    res=$?
	    if [ $res -gt 0 ]; then
		error_echo "Could not download QIIME $qiime_version environment file from ${qiime_url}.

$ABORT_MESSAGE"
		exit $res
	    fi
	    "$conda" env create -n "$env_name" --file "$qiime_yml"
	    res=$?
	    if [ "$res" -eq 0 ]; then
		success_echo "Successfully installed QIIME ${qiime_version}."
	    else
		error_echo "QIIME ${qiime_version} installation failed. Exiting."
		exit $res
	    fi
	fi
	rm -f "$qiime_yml"
    fi
done

# MATERIALS
if [ "${part_flags[$MATERIALS_PART]}" -ge $IMPLICITLY_ENABLED ]; then
    refuse_message="Refusing to continue with installation of workshop materials."
    disable_message="To disable installation of workshop materials, re-run this script with the
${DISABLE_PREFIX}${MATERIALS_PART} flag."
    if ! cd; then
	error_echo "Could not cd to home directory. Something is wrong.

$ABORT_MESSAGE"
	exit 1
    fi
    materials_tar="$(basename "$MATERIALS_URL")"
    if [ -f "$materials_tar" ]; then
	if [ "${part_flags[$MATERIALS_PART]}" -ge $FORCED_FLAG ]; then
	    rm -f "$materials_tar"
	else
	    error_echo "Workshop materials tar file was found at $PWD/${materials_tar}. Workshop materials may
already be installed at ${PWD}. $refuse_message

If you know what you are doing, you can force installation of workshop materials with the
${FORCE_PREFIX}${MATERIALS_PART} flag. This will delete your $PWD/${materials_tar} file. (Alternatively, you can
delete the file manually.)

$disable_message

$ABORT_MESSAGE"
	    exit 1
	fi
    fi
    web_check_available "$MATERIALS_URL"
    res=$?
    if [ $res -gt 0 ]; then
	error_echo "$materials_tar is not available from ${MATERIALS_URL}.

$ABORT_MESSAGE"
	exit 1
    fi
    materials_dirlist="$(basename "$MATERIALS_DIRLIST_URL")"
    if [ "$dry_run_flag" = true ]; then
	if ! web_check_available "$MATERIALS_DIRLIST_URL"; then
	    warning_echo "$materials_dirlist is not available from ${MATERIALS_URL}."
	fi
	echo "Would download and extract workshop materials."
    else
	web_download "$MATERIALS_URL"
	res=$?
	if [ $res -gt 0 ]; then
	    error_echo "Could not download $materials_tar from ${MATERIALS_URL}.

$ABORT_MESSAGE"
	    exit 1
	fi
	create_log=false
	if [ "${part_flags[$MATERIALS_PART]}" -lt $FORCED_FLAG ]; then
	    rm -f "$materials_dirlist"
	    web_download "$MATERIALS_DIRLIST_URL"
	    res=$?
	    if [ $res -gt 0 ]; then
		warning_echo "Could not download $materials_dirlist from ${MATERIALS_DIRLIST_URL}. $materials_dirlist
is not essential but allows checking the $materials_tar integrity and reduces the time needeed to check for possible
installation issues."
		file_list="$(tar --exclude='./*/*' -tvf "$materials_tar")"
		create_log=true
	    else
		if [[ $(type -t _md5sum) == function ]]; then
		    materials_md5="$(_md5sum "$materials_tar")"
		    materials_check="$(head -n 1 "$materials_dirlist")"
		    if [ ! "$materials_md5" = "$materials_check" ]; then
			error_echo "MD5 sum of $materials_tar ($materials_md5) does not match sum from $materials_dirlist
($materials_check). $refuse_message

If you know what you are doing and believe this is a mistake, please contact the script maintainer about this issue
and re-run the script with the ${FORCE_PREFIX}${MATERIALS_PART} flag to continue the installation anyway.

$disable_message

$ABORT_MESSAGE"
			exit 1
		    fi
		    file_list="$(tail -n +2 "$materials_dirlist")"
		else
		    warning_echo "Could not verify integrity of downloaded tar $materials_tar and corresponding
dirlist $materials_dirlist because neither md5sum nor md5 is an available command on this system.

Genering dirlist manually."
		    file_list="$(tar --exclude='./*/*' -tvf "$materials_tar")"
		fi
	    fi
	    while IFS= read -r line; do
		if [ -d "$line" ]; then
		    error_echo "Directory $line already exists at ${PWD}.
$refuse_message

If you know what you are doing, you can force installation of the workshop materials with the
${FORCE_PREFIX}${MATERIALS_PREFIX} flag. This will extract over your existing, $line directory, possibly overwriting
your existing files. (Alternatively, you can delete the $line directory manually.)

$disable_message

$ABORT_MESSAGE"
		    exit 1
		fi
	    done <<< "$file_list"
	    mv "$materials_dirlist" "$MATERIALS_DIRLIST_LOG"
	fi
	# Everything looks good.
	if [ "$create_log" = true ]; then
	    _md5sum "$materials_tar" > "$MATERIALS_DIRLIST_LOG"
	    echo "$file_list" >> "$MATERIALS_DIRLIST_LOG"
	fi
	tar xJvpf "$materials_tar"
	res=$?
	if [ $res -gt 0 ]; then
	    error_echo "Workshop material extraction failed. Exiting."
	    exit $res
	else
	    success_echo "Successfully extracted workshop materials."
	fi
    fi
fi

if [ "$dry_run_flag" = false ]; then
    # Don't try to run updatedb if we don't have it.
    if which updatedb; then
	echo "Running updatedb."
	sudo updatedb
    fi
    success_echo "Installation complete."
fi
# stopsudo
