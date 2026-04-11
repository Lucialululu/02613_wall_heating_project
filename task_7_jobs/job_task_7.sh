#!/bin/bash
#BSUB -J task7_jit
#BSUB -q hpc
#BSUB -n 1
#BSUB -W 00:30
#BSUB -R "rusage[mem=6GB]"
#BSUB -o out_task_7.txt
#BSUB -B
#BSUB -N

# Aktiver miljøet
source /dtu/projects/02613_2025/conda/conda_init.sh
conda activate 02613

echo "Running Task 7 (Numba JIT)"
echo "LSF cores: $LSB_DJOB_NUMPROC"
date

# Vi kører her for 10 bygninger, som opgaven foreskriver for reference-sammenligning
python simulate_task_7.py 10

date