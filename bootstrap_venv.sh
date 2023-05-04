#!/bin/bash

function usage() {
    cat <<EOF

    bootstrap_venv.sh  -  Script to generate a python virtual environment to use with Spack

    Usage: bootstrap_venv.sh [OPTION]...

    Options
     -h, --help     Help
     -p, --prefix   Prefix (default: ${PWD})
     --pyversion     Python version to use (default: 3.11.0)

EOF
  exit 0;
}

# read arguments
while (( "$#" )); do
    case "$1" in
	-h|--help)
	    usage
	    shift
	    ;;
	-p|--prefix)
	    if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
		PREFIX=$2
		shift 2
	    else
		echo "Error: Argument for $1 is missing" >&2
		exit 1
	    fi
	    ;;
        --pyversion)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
		PYVERSION=$2
		shift 2
	    else
		echo "Error: Argument for $1 is missing" >&2
		exit 1
	    fi
	    ;;
	-*|--*=) # unsupported flags
	    echo "Error: Unsupported flag $1" >&2
	    exit 1
	    ;;
    esac
done

if [ -z $PREFIX ]; then
    PREFIX=${PWD}
fi
echo "Prefix: $PREFIX"

if [ -z $PYVERSION ]; then
    PYVERSION="3.11.0"
fi
echo "Python version: $PYVERSION"

# check if directory exist
if [ ! -d $PREFIX ]; then
    echo "Error: $PREFIX directory does not exist"
    exit 1
fi

if [ ! -d $PREFIX/spack ]; then
    echo "Error: $PREFIX/spack directory does not exist"
    exit 1
fi

# Create virtual environments and install easybuild
pushd ${PREFIX}

module load python3/$PYVERSION
virtualenv venv --prompt spack -p /apps/python3/$PYVERSION/bin/python3

sed -i  "/^deactivate () {/a  \    unset -f spack\n    unset -f _spack_shell_wrapper\n    unset SPACK_ROOT\n    unset SPACK_LD_LIBRARY_PATH\n    unset SPACK_PYTHON\n    unset SPACK_SYSTEM_CONFIG_PATH\n    unset SPACK_USER_CACHE_PATH\n    module unload python3/$PYVERSION\n    module unuse $PREFIX/share/modules" venv/bin/activate

cat <<EOF >> venv/bin/activate

module load python3/$PYVERSION

export SPACK_PYTHON=/apps/python3/$PYVERSION/bin/python3
export SPACK_SYSTEM_CONFIG_PATH=$PREFIX/config/system/
export SPACK_USER_CACHE_PATH=$PREFIX/user_cache
module use $PREFIX/share/modules

. $PREFIX/spack/share/spack/setup-env.sh
EOF
popd

module unload python3/$PYTHONVER


