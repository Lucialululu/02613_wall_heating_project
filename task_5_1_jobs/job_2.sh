#!/bin/bash
#BSUB -J task5_1_2w
#BSUB -q hpc
#BSUB -n 2
#BSUB -W 00:30
#BSUB -R "rusage[mem=3GB]"
#BSUB -o out_2w.txt
#BSUB -B
#BSUB -N

echo "Running with 2 workers"
echo "LSF cores: $LSB_DJOB_NUMPROC"
date

python simulate_task_5_1.py 50 2

date