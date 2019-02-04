#!/bin/bash
#
# Launch a single short experiment, which us useful for testing configutation

JULIA_PROJECT=`pwd` julia -p1  experiments/atari.jl --frames 100 --total_evals 10 --seed 1 --log quick1.log
