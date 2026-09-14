#!/bin/bash
#SBATCH --time=16:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --account=notchpeak-gpu
#SBATCH --partition=notchpeak-gpu
#SBATCH --gres=gpu:v100:1
#SBATCH --job-name=mace-v100
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=wcardoen@gmail.com

export WORKDIR=$HOME/TestBench/Chem/lammps-mace/v100
export INPUTFILE=$WORKDIR/in.mace_off23.lammps
export OMP_NUM_THREADS=$SLURM_NTASKS

printf "Job started at %s\n"  "$(date)"
printf "  Job Id: %s\n"       "$SLURM_JOBID"
printf "  Hostname: %s\n"     "$(hostname)"
printf "  Input file: %s\n"   "$INPUTFILE"
printf "  #Threads: %s\n"     "$OMP_NUM_THREADS"

module load mace-lmp/0.3.16.g.b
# In order to run, I invoked --cleanenv  
# To make the OMP_NUM_THREADS again visible to LAMMPS
# use the following construct 
export APPTAINERENV_OMP_NUM_THREADS=$OMP_NUM_THREADS

mpirun -np 1 lmp-dispatch  -in $INPUTFILE


printf "Job ended at %s\n" "$(date)"

