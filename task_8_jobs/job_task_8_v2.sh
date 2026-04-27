#!/bin/bash
#BSUB -J task8_full_run
#BSUB -q gpua100              # <--- SKIFTET FRA gpuv100 TIL gpua100
#BSUB -gpu "num=1:mode=exclusive_process"
#BSUB -n 4
#BSUB -R "span[hosts=1]"
#BSUB -W 04:00
#BSUB -R "rusage[mem=6GB]"
#BSUB -o out_task_8_full.txt
#BSUB -B
#BSUB -N

source /dtu/projects/02613_2025/conda/conda_init.sh
conda activate 02613_2026

echo "Running Task 8 for all buildings (Task 12 data generation)"
date

# Sletter gammel fil hvis den findes, så vi er sikre på et rent resultat
rm -f final_results_task12.csv

python simulate_task_8.py 4571 > final_results_task12.csv

date