#!/bin/bash
#BSUB -J task8_cuda
#BSUB -q gpuv100
#BSUB -gpu "num=1:mode=exclusive_process"
#BSUB -n 4
#BSUB -R "span[hosts=1]"
#BSUB -W 00:30
#BSUB -R "rusage[mem=6GB]"
#BSUB -o out_task_8.txt
#BSUB -B
#BSUB -N

# Aktiver det NYE miljø
source /dtu/projects/02613_2025/conda/conda_init.sh
conda activate 02613_2026

echo "Running Task 8 (Custom CUDA Kernel)"
date

# Vi kører for 10 bygninger
python simulate_task_8.py 10

date