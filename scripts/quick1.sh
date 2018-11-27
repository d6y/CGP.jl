#!/bin/bash
#
# Launch a single short experiment, which us useful for testing configutation

julia --project=. experiments/atari.jl --frames 100 --total_evals 10 --seed 1 --log quick1.log
