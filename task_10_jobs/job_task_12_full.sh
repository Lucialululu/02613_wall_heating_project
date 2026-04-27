#!/bin/bash
#BSUB -J task12_full_run
#BSUB -q gpua100
#BSUB -gpu "num=1:mode=exclusive_process"
#BSUB -n 4
#BSUB -R "span[hosts=1]"
#BSUB -W 04:00
#BSUB -R "rusage[mem=6GB]"
#BSUB -o out_task_12_full.txt
#BSUB -B
#BSUB -N

source /dtu/projects/02613_2025/conda/conda_init.sh
conda activate 02613_2026

echo "Running Full Task 12 generation using optimized CuPy"
date

# Sletter gammel fil hvis den findes
rm -f final_results_task12.csv

# Vi bruger simulate_task_9.py da den indeholder din optimerede CuPy-løsning
python simulate_task_10.py 4571 > final_results_task12.csv

date