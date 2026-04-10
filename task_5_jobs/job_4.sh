#!/bin/bash
#BSUB -J task5_8w
#BSUB -q hpc
#BSUB -n 8
#BSUB -W 00:30
#BSUB -R "rusage[mem=6GB]"
#BSUB -o out_8w.txt
#BSUB -B
#BSUB -N

echo "Running with 8 workers"
echo "LSF cores: $LSB_DJOB_NUMPROC"
date

python simulate_task_5.py 50 8

date