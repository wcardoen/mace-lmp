# Written by WRC on 08/28/2028 (wim.cardoen@utah.edu)
# Update: 09/11/2026

General idea:
============
The current version of the MACE-LMP was built for GPUs.
It has support for the following CUDA-GPU architectures (all available at CHPC):
    MAXWELL50 MAXWELL52 MAXWELL53
    PASCAL60 PASCAL61
    VOLTA70
    TURING75
    AMPERE80 AMPERE86
    ADA89
    HOPPER90
    BLACKWELL100 BLACKWELL120

In order to support all of these architectures I had to choose a CUDA Toolkit Version < 13.0
I opted for CUDA 12.8.1 which was already on the cluster.


Building the container:
======================
- The container was build in 2 steps:
  a. base.sif: common to all GPU based installations:
     - contains the following building blocks:
        CUDATOOLKIT 12.8 (GPU)
        LIBTORCH (GPU)
        INTEL MKL
        OPENMPI (with CUDA support)
     The base.sif file was generated using the build_base.sh script

  b. lmg.sif: requires the base.sif 
     - LAMMPS HAD to be built separately (Due to KOKKOS) for EACH of the aforementioned 
       GPU architectures. 
     - To be concrete:
       The LAMMPS installation for VOLTA70 will be found
       /opt/lammps/pkg/VOLTA70
       Its binary lmp will be found in /opt/lammps/pkg/VOLTA70/bin.
       The corresponding dynamic lib is to be found in /opt/lammps/pkg/VOLTA70/lib
       Mutatis mutandis for the other GPU architectures.
     - In the file lmg.def you will also find all the LAMMPS 'packages' I included in the build.

  c. The logical question to ask: how can we be sure that the correct lmp executable will 
     be called for a given architecture at runtime?

     Inside the lmg.sif I created a dispatcher.
     When one wants to launch the lammps job one MUST invoke 
          `lmp-dispatch` 
     instead of 
          `lmp`
     The lmp-dispatch will find the correct GPU architecture. It
     adjusts the env. variables PATH and LD_LIBRARY_PATH

     In that way the user does not have to know the underlying hardware nor the 'caprices'
     of the SLURM scheduler (case like --gres=gpu:1) 

I have written a corresponding slurm file:
To load on the cluster 
module load mace-lmp/0.3.16.g

To run:
------
mpirun -np $SLURM_NTASKS lmp-dispatch -h  
(I didn't have an input file, but if you were to have one e.g. mace.inp , you can use:
mpirun -np $SLURM_NTASKS lmp-dispatch -in mace.inp

To inspect the container:
------------------------
If you want to look into/inspect the sif file:
singularity inspect lmg.sif

