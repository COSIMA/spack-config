# COSIMA Spack Configuration

This repository contains the spack configuration and the spack environments used
by COSIMA to deploy software on gadi.

## Installation instructions

Clone this repository and its submodules to some appropriate location (e.g.,
`/g/data/ik11/spack/0.20.1`):
```bash
$ git clone --recursive https://github.com/COSIMA/spack-config.git /g/data/ik11/spack/0.20.1
```
Next, create the python virtual environment:
```bash
$ cd /g/data/ik11/spack/0.20.1
$ ./bootstrap_venv.sh
```
Finally, to use this spack installation one just needs to activate the python
environment:
```bash
$  . /g/data/ik11/spack/0.20.1/venv/bin/activate
$ which spack
spack ()
{ 
    : this is a shell function from: /g/data/ik11/spack/0.20.1/spack/share/spack/setup-env.sh;
    : the real spack script is here: /g/data/ik11/spack/0.20.1/spack/bin/spack;
    _spack_shell_wrapper "$@";
    return $?
}
```

## Installing software

It is recommended that all software be installed using spack
environments. Currently the following environments are provided (the names
should be self-explanatory):
1. `access-om3-0_1_0`
2. `access-om3-devel`
3. `cesm-0_1_0`
4. `common_tools_and_libraries`

Installation of a spack environment is usually quite straightforward, but
because this can be a CPU intensive operation and take quite some time, it is
best to do this in parallel and to use an interactive job. 

### Step-by-step instructions:

 1. Activate spack environment

First activate the spack environment
```bash
$ spack env activate <env>
```
where `<env>` by the actual name of the environment.

 2. Download the sources

As the compute nodes do not have internet access, one needs to download all the
necessary sources from the login node. This is done using a spack mirror.
```bash
$ spack mirror create -d sources -a
```
Here `sources` is the name of a mirror that has already been configured.

 3. Submit interactive job

This should not use more than a single node. Also, make sure to add `gdata/ik11`
and `scratch/ik11` to the storage options.

 4. Install software

Once the job has started, because it starts a completely new shell session, one
needs to activate again both the python and the spack environments:
```bash
$  . /g/data/ik11/spack/0.20.1/venv/bin/activate
$ spack env activate <env>
```
Then one can simply do
```bash
$ spack install 
```
In this case, although each individual build will use some level of parallelism,
spack will proceed through the installation of the packages sequentially. To
fully use parallelism one needs to tell spack to create a Makefile and use this
to install the software:
```bash
$ spack env depfile -o Makefile
$ make -j
```

In the end, all the packages should be available in some subdirectory of
`/g/data/ik11/spack/0.20.1/opt/` and the corresponding environment modules are
installed under a subdirectory of `/g/data/ik11/spack/0.20.1/modules`. The
actual subdirectories depend on the selected environement.
