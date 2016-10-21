#!/bin/bash

FILEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && readlink -f -- . )"

if [ ! -f ${FILEDIR}/../.venv/bin/activate ];
then
    echo "You need to install libraries to the virtual environment first."
    echo "There is a script ready: execute ./elfi-scripts/install_libs.sh"
    exit
fi

# default values
SLURM=0
MASTER=0
JOBFILE=""
IP=""
PORT=9786  # dask default port

# process command line parameters
# http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ $# > 1 ]]
do
key="$1"

case $key in
    --slurm)
    SLURM=1
    ;;
    --port)
    PORT=$2
    shift
    ;;
    --jobfile)
    JOBFILE=$2
    shift
    ;;
    *)
    # unknown option
    echo "usage: ./run_experiment.sh --slurm --port http_port --jobfile jobfile.py"
    exit
    ;;
esac
shift
done

if [[ "${JOBFILE}" == "" ]]; then
    echo "No jobfile given, exiting."
    exit 1
fi

source ${FILEDIR}/load_libs.sh

export PYTHONPATH="${PYTHONPATH}:${FILEDIR}"
if [ ! ${SLURM} -eq 1 ]; then
    echo "Running ${JOBFILE} locally.."
    python3 ${JOBFILE}
    echo "Done"
else
    # Get a list of hosts using python-hostlist
    NODES=`hostlist --expand ${SLURM_NODELIST} | xargs`
    # Determine current worker name
    ME=`hostname -s`
    # Determine master process (first node, id 0)
    MASTER_NODE=$(echo $NODES | cut -f 1 -d ' ')
    # SLURM_LOCALID contains task id for the local node
    LOCALID=${SLURM_LOCALID}
    MASTER_IP=`nslookup ${MASTER_NODE} | head -5 | tail -1 | sed 's_Address:\s*\(.*\)_\1_'`

    #echo "NODES ${NODES}"
    #echo "MASTER NODE ${MASTER_NODE}"
    #echo "ME ${ME}"
    #echo "LOCALID ${LOCALID}"
    #echo "MASTER IP ${MASTER_IP}"

    if [[ "${ME}" == "${MASTER_NODE}" && "${LOCALID}" -eq 0 ]]; then
        echo "Master ${ME}/${LOCALID}: Starting dask-scheduler at ${MASTER_IP}:${PORT}.."
        dask-scheduler --http-port ${PORT} --no-bokeh &
        SCHED=$!  # Scheduler process id
        sleep 20  # Let workers start before cotinuing
        echo "Master ${ME}/${LOCALID}: Executing job file.."
        echo "python3 ${JOBFILE}"
        python3 ${JOBFILE}
        echo "Master ${ME}/${LOCALID}: Terminating dask.."
        kill ${SCHED}
        echo "Master ${ME}/${LOCALID}: Scheduler terminated"
        source ${FILEDIR}/unload_libs.sh
        echo "Master ${ME}/${LOCALID}: Sending SIGHUP to terminate job.."  # TODO: find better way to do this
        kill -1 $$
    else
        echo "Worker ${ME}/${LOCALID}: Starting dask worker.."
        dask-worker --nthreads 1 --nprocs 1 ${MASTER_IP}:${PORT}
        echo "Worker ${ME}/${LOCALID}: Worker terminated"
    fi
fi

source ${FILEDIR}/unload_libs.sh

echo "Done."

