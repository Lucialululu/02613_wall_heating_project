#!/bin/bash
#BSUB -J task10_nsys
#BSUB -q gpuv100
#BSUB -gpu "num=1:mode=exclusive_process"
#BSUB -n 4
#BSUB -R "span[hosts=1]"
#BSUB -W 00:30
#BSUB -R "rusage[mem=6GB]"
#BSUB -o out_task_10.txt
#BSUB -B
#BSUB -N

source /dtu/projects/02613_2025/conda/conda_init.sh
conda activate 02613_2026

echo "Running Task 10 (Profiling with nsys)"
date

nsys profile -o profile_task_10 --stats=true python simulate_task_10.py 10

date