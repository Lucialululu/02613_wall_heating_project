#!/bin/bash
#BSUB -J profiling_test
#BSUB -q hpc
#BSUB -n 1
#BSUB -W 00:20
#BSUB -R "rusage[mem=2GB]"
#BSUB -o out_task_4.txt

cd $LS_SUBCWD

echo "Starting job"
date

echo "CPU model:"
grep "model name" /proc/cpuinfo | head -n 1

echo "Running kernprof now!!!"

~/.local/bin/kernprof -l simulate_profile.py 5

echo "Profiling results:"
python3 -m line_profiler simulate_profile.py.lprof

date
echo "Finished job"