#!/bin/bash
#SBATCH -n _NPROC_
#SBATCH --time=_TIME_
#SBATCH --mem-per-cpu=_MEM_
#SBATCH --constraint=[ivb|wsm]
#SBATCH -p batch
#SBATCH -o _OUT_FILE_
#SBATCH -e _ERR_FILE_

# WRKDIR this should work from all nodes in Triton
WORKDIR="${WRKDIR}/elfi/slurm_data/_JOBID_"
DB_FILE="${WORKDIR}/_JOBID_.db"
HOSTNAME=`hostname`
mkdir -p $WORKDIR

env > _ERR_FILE_

echo "Starting job at ${HOSTNAME}"
echo "* job id:     _JOBID_"
echo "* processes:  _NPROC_"
echo "* work dir:   ${WORKDIR}"
echo "* slurm file: _SLURM_FILE_"
echo "* job file:   _JOB_FILE_"
echo "* out file:   _OUT_FILE_"
echo "* err file:   _ERR_FILE_"
echo "---------------------------------------"

srun bash _PROJ_DIR_/elfi-scripts/run_experiment.sh --slurm --port _PORT_ --jobfile _JOB_FILE_ --errfile _ERR_FILE_

echo "---------------------------------------"
echo "Job ended"



