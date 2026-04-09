#!/bin/bash
#BSUB -J timing_test
#BSUB -q hpc
#BSUB -n 1
#BSUB -W 00:10
#BSUB -R "rusage[mem=2GB]"
#BSUB -o out_task_1.txt

echo "Starting job"
date

python simulate.py 10

date
echo "Finished job"