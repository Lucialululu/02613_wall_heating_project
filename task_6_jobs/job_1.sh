#!/bin/bash
#BSUB -J task6_1w
#BSUB -q hpc
#BSUB -n 1
#BSUB -W 00:30
#BSUB -R "rusage[mem=2GB]"
#BSUB -o out_1w.txt
#BSUB -B
#BSUB -N

echo "Running with 1 worker"
echo "LSF cores: $LSB_DJOB_NUMPROC"
date

python simulate_task_6.py 50 1

date