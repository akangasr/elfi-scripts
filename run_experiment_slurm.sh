#!/bin/bash
#
# This script is called with the experiment identifier as a parameter
# and in the case of a MPI run with the number of processes as the
# second parameter.
#

HN=`hostname -f`
if [[ $HN != *".triton.aalto.fi" ]];
then
    echo "Not on Triton (hostname ${HN}), exiting."
    exit
fi

# default values
TIME="1-00:00:00"
MEM="1000"
DATETIME=`date +%F_%T`
JOBID="run_at_${DATETIME}"
JOBFILE="job.py"
NPROC=1
PORT=9786  # dask default port
SEED=12345

# process command line parameters
# http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ $# > 1 ]]
do
key="$1"

case $key in
    -t|--time)
    TIME="$2"
    shift
    ;;
    -m|--mem)
    MEM="$2"
    shift
    ;;
    -i|--jobid)
    JOBID="$2"
    shift
    ;;
    -n|--nproc)
    NPROC="$2"
    shift
    ;;
    -j|--jobfile)
    JOBFILE="$2"
    shift
    ;;
    -p|--port)
    PORT="$2"
    shift
    ;;
    -s|--seed)
    SEED="$2"
    shift
    ;;
    *)
    # unknown option
    echo "usage: ./run_experiment_slurm.sh -t <max_time> -m <max_mem> -i <job_identifier> -n <number_of_processes> -p <port> -j <job_file> -s <seed>"
    exit
    ;;
esac
shift
done

if [ $PORT -gt 65535 ];
then
    echo "Port must be in range 0-65535"
    exit -1
fi

IDENTIFIER="${JOBID}"

# location where results will be stored
PROJ_DIR=`readlink -f -- .`
DATA_DIR="${PROJ_DIR}/slurm_data/${IDENTIFIER}"
if [ -d $DATA_DIR ];
then
    echo "Folder already exists! Press 'y' to continue."
    read -n 1 cont
    if [ "$cont" != "y" ]; then
        echo " terminating"
        exit 0
    fi
    echo " continuing experiment"
fi
mkdir -p $DATA_DIR

echo "Running experiment with"
echo "* TIME:      ${TIME}"
echo "* MEMORY:    ${MEM}"
echo "* JOBID:     ${JOBID}"
echo "* NPROC:     ${NPROC}"
echo "* DIR:       ${DATA_DIR}"
echo "* DASK PORT: ${PORT}"
echo "* SEED:      ${SEED}"

# create job script file and param file
SLURM_FILE="${DATA_DIR}/${JOBID}.sh"
JOB_FILE="${DATA_DIR}/job.py"
OUT_FILE="${DATA_DIR}/out.txt"
ERR_FILE="${DATA_DIR}/err.txt"
cp "${PROJ_DIR}/${JOBFILE}" ${JOB_FILE}
cat elfi-scripts/slurm_job_template.sh |
    sed "s;_TIME_;${TIME};g" |
    sed "s;_MEM_;${MEM};g" |
    sed "s;_PROJ_DIR_;${PROJ_DIR};g" |
    sed "s;_DATA_DIR_;${DATA_DIR};g" |
    sed "s;_SLURM_FILE_;${SLURM_FILE};g" |
    sed "s;_JOB_FILE_;${JOB_FILE};g" |
    sed "s;_OUT_FILE_;${OUT_FILE};g" |
    sed "s;_ERR_FILE_;${ERR_FILE};g" |
    sed "s;_JOBID_;${JOBID};g" |
    sed "s;_PORT_;${PORT};g" |
    sed "s;_SEED_;${SEED};g" |
    sed "s;_NPROC_;${NPROC};g" > $SLURM_FILE
chmod ugo+x $SLURM_FILE
echo "Saving results to ${DATA_DIR}"

GIT_FILE="${DATA_DIR}/git.txt"
echo "Current commit:" > ${GIT_FILE}
git log -n 1 >> ${GIT_FILE}
echo "----" >> ${GIT_FILE}
echo "Git status:" >> ${GIT_FILE}
git status >> ${GIT_FILE}
echo "----" >> ${GIT_FILE}
echo "Local changes:" >> ${GIT_FILE}
git diff >> ${GIT_FILE}
echo "----" >> ${GIT_FILE}
echo "Cached local changes:" >> ${GIT_FILE}
git diff --cached >> ${GIT_FILE}
echo "----" >> ${GIT_FILE}
echo "end." >> ${GIT_FILE}

# add job to slurm queue
cd $DATA_DIR
sbatch $SLURM_FILE

