#!/bin/bash
#
# Launch a number of Atari experiments on the current machine.
# There are (num games * num seeds) concurrent executions.
#
# Usage:
#   $ cd CGP.jl
#   $ ./scripts/local-spawn.sh > spawn-`date +%Y%m%dZ%H%M%S`.out

SEEDS=( 1  2 3 4 )
GAMES=( "space_invaders" "asteroids" )

MAX_FRAMES=18000  # Control number of frames in each game
TOTAL_EVALS=10000 # Number of evaluations to perform on a given tournament

LOG_DIR="logs"
mkdir -p ${LOG_DIR}

echo "Starting `pwd` $0 at `TZ=UTC date`"
echo "Host: `hostname`"
echo "Arch: `uname -a`"
echo "Julia: `julia --version`"
echo "Git revision: `git log -1 --oneline`"

echo " "
echo "atari.yaml:"
echo ">>"
cat cfg/atari.yaml
echo "<<"
echo " "

echo "Launching:"
for game in ${GAMES[@]} 
do
  for seed in ${SEEDS[@]}
  do
    base=${LOG_DIR}/${game}_${seed}
    echo "- ${base}"
    nohup julia --project=. experiments/atari.jl --frames ${MAX_FRAMES} --total_evals ${TOTAL_EVALS} --seed $seed --log ${base}.log 1> ${base}.out 2> ${base}.err &
  done
done

