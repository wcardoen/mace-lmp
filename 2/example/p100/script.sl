#!/bin/bash
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=6
#SBATCH --mem=60GB
#SBATCH --cluster=kingspeak
#SBATCH --account=owner-gpu-guest
#SBATCH --partition=kingspeak-gpu-guest
#SBATCH --gres=gpu:p100:1
#SBATCH --job-name=mace-p100
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=<--


ts=$(date +%s%N)
# --------------------- SETUP ----------------------
export WORKDIR=$HOME/TestBench/Chem/lammps-mace/p100
export INPUTFILE=$WORKDIR/in.mace_off23.lammps
export OMP_NUM_THREADS=$SLURM_NTASKS
# --------------------------------------------------

# --------------------- TOOLS ----------------------------------------
format_walltime() {
    local ns=$1
    local ms=$(( (ns / 1000000) % 1000 ))
    local total_sec=$(( ns / 1000000000 ))
    local sec=$(( total_sec % 60 ))
    local total_min=$(( total_sec / 60 ))
    local min=$(( total_min % 60 ))
    local total_hour=$(( total_min / 60 ))
    local hour=$(( total_hour % 24 ))
    local day=$(( total_hour / 24 ))

    printf "%dd %dh %dm %ds %dms\n" "$day" "$hour" "$min" "$sec" "$ms"
}
# --------------------------------------------------------------------



# ---------------------------- LAMMPS JOB ----------------------------
module load mace-lmp/0.3.16.g.b

printf "Job started at %s\n"  "$(date)"
printf "  Job Id: %s\n"       "$SLURM_JOBID"
printf "  Hostname: %s\n"     "$(hostname)"
printf "  Input file: %s\n"   "$INPUTFILE"
printf "  #Threads: %s\n"     "$OMP_NUM_THREADS"
printf "  mpirun:\n%s\n"      "$(which mpirun)"

# In order to run (with MPI) , I invoked --cleanenv  
# To make the OMP_NUM_THREADS again visible within the container
# use the following construct 
# APPTAINERENV_<name of env variable>=value
export APPTAINERENV_OMP_NUM_THREADS=$OMP_NUM_THREADS

# MACE-LAMMPS run
mpirun -np 1 lmp-dispatch -in $INPUTFILE >& log.$SLURM_JOBID.lammps

printf "Job ended at %s\n" "$(date)"

te=$(date +%s%N)
elapsed_ns=$((te - ts))
out=$(format_walltime $elapsed_ns)
printf "Elapsed time:%s\n" "$out"
