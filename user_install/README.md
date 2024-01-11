# Installing the NGS Workshop environment with the user-friendly install scripts

The instructions below describe how to install the UK/INBRE NGS Workshop
environment using the (relatively) user-friendly install scripts we developed
to allow participants to more easily perform the installation on their own
hardware.

## Requirements

Ideally, you should have a new ("clean") installation of Ubuntu 20.04 or 22.04
running on the x86_64 processor architecture. On such a system, these scripts
should be able to install the full UK/INBRE NGS Workshop environment.

Unlike the [standard install script](../standard_setup/), this script should
also be able to handle installation on some "dirty" systems where much software
has already been installed. Of course, we cannot test on all such
configurations, so the script may not always work on existing installations of
Ubuntu 20.04 or 22.04.

This script can also attempt a full or partial installations on other systems if
the appropriate command-line flags are provided to the script. This may be
useful, for example, if you wish to only work on the QIIME exercises on another
system like macOS.

## Basic install process

1. Download the scripts. For example,

```bash
git clone https://github.com/actapia/uky-ngs-workshop-user-install
cd uky-ngs-workshop-user-install/user_install
```
	
2. Run the setup script.

```bash
bash ngs_setup.sh
```
	
## Basic uninstall process

1. (Optional) Download the scripts if you haven't already.

```bash
git clone https://github.com/actapia/uky-ngs-workshop-user-install
cd uky-ngs-workshop-user-install/standard_setup
```
	
2. Run the uninstall script.

```bash
bash ngs_uninstall.sh
```
	
## Command-line options

Most of the command-line flags understood by the `ngs_setup.sh` and
`ngs_uninstall.sh` scripts change the behavior when attempting to install
certain components. The components installed by the current version of the
user-friendly script are

| Component name  | Description                                                |
|-----------------|------------------------------------------------------------|
| `apt-packages`  | Software installable through APT, Ubuntu's package manager |
| `materials`     | Files used in workshop exercises (normally in `~/`)        |
| `miniconda`     | Miniconda Python package and environment manager           |
| `qiime2-2019.4` | QIIME 2019.4                                               |
| `qiime2-2022.2` | QIIME 2022.2                                               |

For each component, up to three possible options change the behavior of the
component's installation.

| Level     | Description                                                      |
|-----------|------------------------------------------------------------------|
| `disable` | Disables (un)installation of the component.                      |
| `enable`  | Enables (un)installation of the component only, disabling others |
| `force`   | Forces installation of the component, ignoring warnings          |

A command line argument to change the level for a certain component begins with
`--` followed by the level, a hyphen `-`, and, finally, the component name.

For example, to disable installation of `apt-packages`, you can run the
`ngs_setup.sh` with the `--disable-apt-packages` flag.

### Other flags

The flags described in the table below do not pertain to a specific component.

| Long name          | Description                                        |
|--------------------|----------------------------------------------------|
| `--dry-run`        | Don't make changes; print what would've been done. |
| `--help`           | Show a help message.                               |
| `--verbose`        | Provide additional output for troubleshooting.     |
| `--version`        | Display the version number of the script.          |
| `--no-interactive` | Don't ask for input from the user.                 |

Additionally, you can see information about all flags accepted by a script by
passing the script the `--help` option.
