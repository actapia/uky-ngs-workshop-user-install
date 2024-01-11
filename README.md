# Essentials of Next Generation Sequencing Setup/Installation Scripts

The scripts in this repository may be used to install the software and the
files ("materials") used in the UKY/INBRE Essentials of Next Generation
Sequencing Workshop.

We provide two options for installing the workshop software and
materials&mdash;see the section below for advice on which option will work best
for you.

## Choosing an installation method

The **standard script** we use for installing the workshop software on VMs for
the workshop may be found under the [standard_setup](./standard_setup)
directory along with instructions for manually downloading and unpacking the
workshop materials. This installation method reproduces the workshop
environment faithfully, but it requires more work from the user and is not
appropriate for use on systems that differ much from the VMs used in the
workshop.

**User-friendly scripts** for installing and uninstalling the workshop
environment may be found under the [user_install](./user_install) directory. The
user-friendly scripts install an environment that is slightly different than the
one used in the workshop, though the workshop exercises should still be possible
to complete in the installed environment. The user-friendly scripts should also
tolerate installation (or partial installation) on systems differing
dramatically from the system for which the NGS Workshop was designed, though we
cannot guarantee that all software will function as expected in such
environments.

You should use the [standard setup](./standard_setup) script if you

* Are installing on a *clean* Ubuntu 20.04 or 22.04 x86_64 system.
* Feel comfortable running multiple commands to perform the installation.
* Are able to recognize when the script has succeeded or failed without help.
* Do not expect to uninstall the software from the system at some point or do
  not need help doing so.
* Want a relatively simple and straightforward installation script.

You should use the [user-friendly scripts](./user_install) scripts if you

* Are installing on an existing Ubuntu 20.04 or 22.04 x86_64 system OR
* Are performing a partial installation on a different system (e.g., Ubuntu
  23.04, Cygwin, macOS).
* Would like to be able to uninstall any component of the environment easily.
* Don't care if the environment is exactly like that of the workshop.
* Would like automatic help recognizing and diagnosing installation errors.
* Would like finer-grained control over what components get installed.
