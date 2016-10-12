#!/bin/bash

FILEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && readlink -f -- . )"

if [ ! -f ${FILEDIR}/../.venv/bin/activate ];
then
    echo "You need to install libraries to the virtual environment first."
    echo "There is a script ready: execute ./scripts/install_libs.sh"
    exit
fi

source ${FILEDIR}/load_libs.sh

echo "Running experiment.."
export PYTHONPATH="${PYTHONPATH}:${FILEDIR}"
python3 "${@:1}"
echo "Experiment over."

source ${FILEDIR}/unload_libs.sh

echo "Done."

