#!/bin/bash

FILEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ "$1" != "--only-venv" ]];
then
    HN=`hostname -f`
    if [[ $HN == *".triton.aalto.fi" ]];
    then
    	>&2 echo "Loading modules.."
        # assume we are in triton
        module load Python/3.5.1-goolf-triton-2016a
        module list
    fi
fi

if [[ "$1" != "--only-modules" ]];
then
    >&2 echo "Activating virtualenv.."
    source ${FILEDIR}/../.venv/bin/activate
fi

