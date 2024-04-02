# COSIMA Spack Configuration

This repository contains the spack configuration and the spack environments used
by COSIMA to deploy software on gadi.

<!-- TOC -->

- [Installation instructions](#installation-instructions)
- [Installing software](#installing-software)
  - [Step-by-step instructions](#step-by-step-instructions)
- [Updating to a new spack version](#updating-to-a-new-spack-version)
- [Design notes](#design-notes)
  - [Package installation path](#package-installation-path)
  - [Environment modules](#environment-modules)
  - [Python virtual environment](#python-virtual-environment)
  - [Repository structure](#repository-structure)
  - [Git branches](#git-branches)

<!-- TOC -->


## Installation instructions

Clone this repository and its submodules to some appropriate location (e.g.,
`/g/data/ik11/spack/0.21.2`):
```console
$ git clone --recursive https://github.com/COSIMA/spack-config.git /g/data/ik11/spack/0.21.2
```
Next, create the python virtual environment:
```console
$ cd /g/data/ik11/spack/0.21.2
$ ./bootstrap_venv.sh
```
Finally, to use this spack installation one just needs to activate the python
environment:
```console
$  . /g/data/ik11/spack/0.21.2/venv/bin/activate
$ which spack
spack ()
{ 
    : this is a shell function from: /g/data/ik11/spack/0.21.2/spack/share/spack/setup-env.sh;
    : the real spack script is here: /g/data/ik11/spack/0.21.2/spack/bin/spack;
    _spack_shell_wrapper "$@";
    return $?
}
```

Most of the paths in the Spack configurations files in this repository are
relative to the Spack location (e.g.,
`/g/data/ik11/spack/0.21.2/spack`). Unfortunately this is not the case for the
global source's mirror defined in `config/system/mirror.yaml`, so the URL in
this file needs to be updated if usage of a mirror is planned (see next
section).

At this point it might be worth reviewing the compilers and packages defined in
`config/system/compilers.yaml` and `config/system/packages.yaml` and update them
if necessary.


## Installing software

It is recommended that all software be installed using spack
environments. Currently the following environments are provided (the names
should be self-explanatory):
1. `access-om3-0_1_0`
2. `access-om3-0_2_0`
3. `access-om3-0_x_0`
4. `cesm-0_1_0`
5. `common_tools_and_libraries`

Installation of a spack environment is usually quite straightforward, but
because this can be a CPU intensive operation and take quite some time, it is
best to do this in parallel and to use an interactive job. 

### Step-by-step instructions

 1. Activate spack environment

First activate the spack environment
```console
$ spack env activate <env>
```
where `<env>` by the actual name of the environment.

 2. Download the sources

As the compute nodes do not have internet access, one needs to download all the
necessary sources from the login node. This is done using a spack mirror.
```console
$ spack mirror create -d sources -a
```
Here `sources` is the name of a mirror that has already been configured.

Note that the spack environment must have been concretized before creating the
mirror, otherwise spack will not know which files need downloading. To
concretize an environment, one uses the following command:
```console
$ spack concretize
```

 3. Submit interactive job

This should not use more than a single node. Also, make sure to add `gdata/ik11`
and `scratch/ik11` to the storage options.

 4. Install software

Once the job has started, because it starts a completely new shell session, one
needs to activate again both the python and the spack environments:
```console
$ . /g/data/ik11/spack/0.21.2/venv/bin/activate
$ spack env activate <env>
```
Then one can simply do
```console
$ spack install 
```
In this case, although each individual build will use some level of parallelism,
spack will proceed through the installation of the packages sequentially. To
fully use parallelism one needs to tell spack to create a Makefile and use this
to install the software:
```console
$ spack env depfile -o Makefile
$ make -j
```

In the end, all the packages should be available in some subdirectory of
`/g/data/ik11/spack/0.21.2/opt/` and the corresponding environment modules are
installed under a subdirectory of `/g/data/ik11/spack/0.21.2/modules`. The
actual subdirectories depend on the selected environment.


## Updating to a new spack version

The way this repository is set up assumes that no update of spack will take
place within a given instance. This is to make sure all packages available
within a given instance are installed with the same version of spack and are
fully reproducible. This means that, in order to update spack, one needs to
create a new instance. Most of the process is therefore very similar to what is
described in the [Installation instructions](#installation-instructions)
section, with a few modifications.

Start by cloning this repository and its submodules to some appropriate location
(e.g., `/g/data/ik11/spack/0.21.2`):
```console
$ git clone --recursive https://github.com/COSIMA/spack-config.git /g/data/ik11/spack/0.21.2
```

Next, create and checkout a new branch in the repository, using the spack
version as branch name:
```console
$ cd /g/data/ik11/spack/0.21.2
$ git checkout -b 0.21.2
```
This is not mandatory, but it helps keeping all the different configurations and
environments clearly separated. It also allows to update instances that are
using different versions of spack independently.

Then we proceed with updating the spack submodule:
```console
$ cd spack
$ git fetch --tags
$ git checkout v0.21.2
$ cd ..
$ git commit spack -m "Update spack to 0.21.2 tag."
```
Note that the `git fetch` step is only strictly necessary if you want to use a
tag from the spack repository (which is recommended).

Finally, just follow the remaining instructions in the [Installation
instructions](#installation-instructions) section to create the python virtual
environment.


## Design notes

This section describes some of the design decisions and their rationale.

### Package installation path

In this repository, spack is configured to install the packages to a path of the
following form:

`opt/{architecture}/{compiler.name}-{compiler.version}/{name}-{version}-{hash:7}`

By adding the architecture, compiler name, and compiler version to the path,
installations of packages built with different compilers on different
architectures are allowed to coexist without any clashes. The inclusion of part
of the spack hash also allows for the same version of a given package to be
compiled with different options. Note that there is nothing specific to the
spack environments, as this is not necessary (two environments that require
exactly the same package built in exactly the same way will share the
corresponding installation).


### Environment modules

By default, the TCL environment modules use the following naming scheme:

`{name}/{version}-{compiler.name}-{compiler.version}-{hash:7}``

This ensures that there are no clashes, but unfortunately the inclusion of the
spack hash makes the use of the modules a bit cumbersome. To avoid the use of
the hash, one can set the modules installation path and naming scheme at the
level of the spack environments. The existing environments include the following
definitions in their `spack.yaml` file:
```yaml
  modules:
    default:
      roots:
        tcl: $spack/../modules/<env path>
      tcl:
        naming_scheme: '{name}/{version}'
```
where `<env path>` is a user-defined path for the environment in question. No
compiler information is used, as our environments only use one compiler. We
recommend to follow this scheme in all environments. Note that spack will
automatically append the architecture to the root path. This allows to install
the same environment on two different architectures without clashes.


### Python virtual environment

Using a python virtual environment for the spack installation has several
advantages. Besides the usual advantages of using such environments (stability,
portability and reproducibility), it allows to automatically perform a few tasks
when activating the environment, thus providing a more user-friendly
experience. These tasks include:
- Sourcing the `spack/share/spack/setup-env.sh` file that takes care of setting
up several environment variables and functions necessary to use spack.
- Loading the appropriate Gadi python environment module.
- Setting up some environment variables to customize the behavior of spack.


### Repository structure

This git repository contains the following directories:
- `config`: the spack configuration files.
- `environments`: spack environment definitions.
- `repos`: several repositories of spack package definitions.
- `spack`: the spack sources, included as a git submodule.

The following directories will be created by spack:
- `modules`: environment modules created by spack.
- `sources`: mirror for package sources.
- `opt`: path where packages are installed.
- `user_cache` and `var/cache`: several caches used by spack.


### Git branches

Each branch in this git repository corresponds to a spack version and is named
after that version (e.g. branch `0.21.2` corresponds to the `v0.21.2` spack
release). Note that there is no `main` branch. Instead, the default branch is
the latest spack version supported. This means that the default branch should be
changed whenever support for a newer version of spack is added.
