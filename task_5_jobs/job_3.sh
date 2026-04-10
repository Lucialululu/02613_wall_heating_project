#!/bin/bash
#BSUB -J task5_4w
#BSUB -q hpc
#BSUB -n 4
#BSUB -W 00:30
#BSUB -R "rusage[mem=4GB]"
#BSUB -o out_4w.txt
#BSUB -B
#BSUB -N

echo "Running with 4 workers"
echo "LSF cores: $LSB_DJOB_NUMPROC"
date

python simulate_task_5.py 50 4

date