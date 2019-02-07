#!/bin/bash
#
SEED=1 
GAME="space_invaders"

NUM_WORKERS=10
MAX_FRAMES=18000  # Control number of frames in each game
TOTAL_EVALS=10000 # Number of evaluations to perform on a given tournament

LOG_DIR="logs"
mkdir -p ${LOG_DIR}

echo "Starting `pwd` $0 at `TZ=UTC date`"
echo "Host: `hostname`"
echo "Arch: `uname -a`"
echo "Julia: `julia --version`"
echo "CPUs: `julia -e 'Sys.cpu_summary()'`"
echo "Git revision: `git log -1 --oneline`"

echo " "
echo "atari.yaml:"
echo ">>"
cat cfg/atari.yaml
echo "<<"
echo " "

base=${LOG_DIR}/${GAME}_${SEED}
echo "- ${base}"
JULIA_PROJECT=`pwd` nohup julia -p${NUM_WORKERS} experiments/atari.jl --id ${GAME} --frames ${MAX_FRAMES} --total_evals ${TOTAL_EVALS} --seed $SEED --log ${base}.log 1> ${base}.out 2> ${base}.err &
