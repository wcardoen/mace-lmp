# Written by Wim R.M. Cardoen (wcardoen@gmail.com)
#   Audentes fortuna iuvat!


- Please read 1/README.txt for the general gist
- What's new?
  The base.def has been split been split up into:
  * base_older.def: covers the CUDA ARCH=50,52,53,60,61,70
                     The libtorch was compiled with cuda126 
  * base_modern.def: covers the CUDA_ARCH=75,80,86,89,89,100,120
                     The libtorch was compiled with cuda128

  The lmg.def has been split up into:
  * lmg_older.def: covers the CUDA ARCH=50,52,53,60,61,70
                     The lmg_older.def is dependent on base_older.def
  * lmg_modern.def: covers the CUDA_ARCH=75,80,86,89,89,100,120
                     The lm_modern.def is dependent on base_modern.def

- Building, in praxi:
  * OLDER Build: (from Maxwell -> Volta)
    1. Build OLDER base:
       bash ./build_base.sh -d base_older.def -n 10 >& base_older.out

    2. Build of lmg_older.sif
       - Dry-run/Test-run
         bash ./build_lmg.sh -d lmg_older.def -a ALL -n 10 -t
       - Build as such
         bash ./build_lmg.sh -d lmg_older.def -a ALL -n 10 >& build_lmp_older.out


  * MODERN Build: (from Turing -> Blackwell)
    1. Build MODERN base:
       bash ./build_base.sh -d base_modern.def -n 10 >& base_modern.out

    2. Build of lmg_modern.sif
       - Dry-run/Test-run
         bash ./build_lmg.sh -d lmg_modern.def -a ALL -n 10 -t
       - Build as such
         bash ./build_lmg.sh -d lmg_modern.def -a ALL -n 10 >& build_lmp_modern.out

- To Run:
  I had to modify the existing .lua file.
  The module detects at run-time which .sif file and cuda version needs to be loaded.
  Note: this setup will not allow to use GPU cards with GPU cards (from base_old and base_modern).
        If you want to go that route, you MUST recompile libtorch from source with cuda/12.8 or cuda/12.9
        (a serious job on itself)
 
  If you want to use multiple threads inside a calculation you need to set OMP_NUM_THREADS as
  follows in the SLURM script:
  export APPTAINERENV_OMP_NUM_THREADS=$OMP_NUM_THREADS
  (this originates because I had to use --cleanenv for the MPI part)

  I have added an example. 


- Possible improvements:
  - I have compiled with SSE4.2 (lowest common denominator on our cluster).
    For the base_modern this could be scaled up to AVX.
  
