#!/bin/bash

FILEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ "$1" != "--only-venv" ]];
then
    HN=`hostname -f`
    if [[ $HN == *".triton.aalto.fi" ]];
    then
    	echo "Loading modules.."
        # assume we are in triton
        module load Python/3.5.1-goolf-triton-2016a
        echo "----------MODULES-----------"
        module list
        echo "----------MODULES-----------"
        echo " "
    fi
fi

if [[ "$1" != "--only-modules" ]];
then
    echo "Activating virtualenv.."
    source ${FILEDIR}/../.venv/bin/activate
fi

