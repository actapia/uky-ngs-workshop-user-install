# Installing the NGS Workshop environment with the standard setup scripts

The instructions below describe how to install the UK/INBRE NGS Workshop
environment using roughly the same setup process used for setting up the VMs
for the workshop.

## Requirements

You need to be running Ubuntu 20.04, 22.04, or a compatible system in order for
this setup process to work. Note that while new versions of Ubuntu may 
eventually be supported, older versions of Ubuntu most likely will *never* be
compatible with this setup script.

Ideally, your installation of Ubuntu should be "clean"&mdash;i.e., you should
have minimal software installed beyond the basic packages that come preinstalled
on Ubuntu.

The system must be running on the x86_64 architecture; the install script does
not provide a way to install any software for other processors.

## Basic setup process

1. Download the script. For example,

```bash
git clone https://github.com/actapia/uky-ngs-workshop-user-install
cd uky-ngs-workshop-user-install/standard_setup
```

2. Run the setup script with `sudo` to install the necessary software.

```bash
sudo bash vm_soft_setup.sh
```

3. Download the workshop materials to a suitable location. For example, to
   install to your home directory,
   
```bash
cd
wget https://www.cs.uky.edu/~acta225/CS485/workshop-materials.tar.xz
```
   
4. Extract the workshop materials.

```bash
tar xJvf workshop-materials.tar.xz
```
	
5. (Optional) Delete the workshop materials tar file.

```bash
rm workshop-materials.tar.xz
```

## Command-line options

The `vm_soft_setup.sh` script detects when components are already installed and
doesn't attempt to reinstall any components by default. By passing command-line
flags to the setup script, however, you may force (re)installation of certain
components.

The command-line arguments accepted by the `vm_soft_setup.sh` script are
summarized in the table below.

| Long name         | Description                           |
|-------------------|---------------------------------------|
| `--busco`         | Force installation of BUSCO.          |
| `--conda-init`    | Force initialization of `conda`.      |
| `--help`          | Show a help message.                  |
| `--mamba`         | Force installation of `mamba`.        |
| `--miniconda`     | Force installation of Miniconda.      |
| `--qiime2-2019.4` | Force installation of QIIME 2 2019.4. |
| `--qiime2-2022.2` | Force installation of QIIME 2 2022.2. |

You can see this information at the command-line by passing the `--help` option
to the `vm_soft_setup.sh` script.
