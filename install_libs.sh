#!/bin/bash

FILEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && readlink -f -- . )"
cd $FILEDIR/..

if [[ "$1" == "--reinstall" ]];
then
    echo "Reinstall: removing current installation"
    rm -rf .venv
    make -f ${FILEDIR}/Makefile clean-venv
fi

source ${FILEDIR}/load_libs.sh --only-modules

if [ ! -d .venv ];
then
    command -v virtualenv >/dev/null 2>&1 ||
        { echo "Virtualenv is required but not installed. Try: sudo pip install virtualenv"; exit 1; }
    echo "No virtualenv found, creating.."
    virtualenv -p python3 .venv --system-site-packages
fi

source ${FILEDIR}/load_libs.sh --only-venv

piploc="`which pip`"
target="/.venv/bin/pip"
if [[ $piploc != *${target} ]];
then
    echo "Error: Pip is currently in ${piploc} instead of *${target}?"
    echo "Deactivating virtualenv.."
    deactivate
    echo "Aborted."
    exit 1
fi

echo "Removing old builds.."
rm -rf .venv/build

echo "Setting environment varibles.."
unset CFLAGS
unset CXXFLAGS
unset LDFLAGS

# Install abcpy
make -f ${FILEDIR}/Makefile all

echo ""
echo "Finding additional requirements.."
# Install requirements for possible submodules
for line in `find -L . | grep /requirements.txt$ | xargs cat`;
do
    if [[ "$line" != "#"* ]];
    then
        echo "Installing requirement (${line}).."
        pip install $line
    fi
done

source ${FILEDIR}/unload_libs.sh

echo "Done."
