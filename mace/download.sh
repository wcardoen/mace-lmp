#!/bin/bash

# Scripts written by Wim R.M. Cardoen on 09/03/2026
# The main page: 
#     https://github.com/ACEsuit/mace-foundations
# MACE pre-trained foundation models for materials chemistry, 
# parameterised for 89 chemical elements.
# The models are:
#  MACE_MP_0a           (small/medium/large)
#  MACE_MP_0b           (small/medium)
#  MACE_MP_0b2          (small/medium/large)
#  MACE_MP_0b3          (medium)
#  MACE_MPA-0           (medium)
#  MACE_OMAT-0          (small/medium)
#  MACE-MATPES-PBE-0    (medium)
#  MACE-MATPES-r2SCAN-0 (medium)
#  MACE-OMOL-0          (extra-large/extra-large (4M))
#  MACE-MH-{0/1}        (https://huggingface.co/mace-foundations/mace-mh-1)
#  --- Other ---
#  MACE-MDP             (https://chemrxiv.org/doi/full/10.26434/chemrxiv.15000716)


set -eou | pipefail
TOTNUMBER=19
count=0
printf "You are currently in directory:%s\n"  "$(pwd)"
printf "Start:%s\n\n"  "$(date)"

# Download all the models
# MACE-MP-Oa
printf "   Downloading MACE_MP-Oa (small/medium/large) ...\n\n"
# --- small
wget https://github.com/ACEsuit/mace-mp/releases/download/mace_mp_0/2023-12-10-mace-128-L0_energy_epoch-249.model
# --- medium
wget https://github.com/ACEsuit/mace-mp/releases/download/mace_mp_0/2023-12-03-mace-128-L1_epoch-199.model
# --- large
wget https://github.com/ACEsuit/mace-mp/releases/download/mace_mp_0/2024-01-07-mace-128-L2_epoch-199.model
count=$((count +3))


# MACE_MP_0b
printf "   Downloading MACE_MP_Ob (small/medium) ...\n\n"
# --- medium
wget https://github.com/ACEsuit/mace-foundations/releases/download/mace_mp_0b/mace_agnesi_medium.model
# --- small
wget https://github.com/ACEsuit/mace-foundations/releases/download/mace_mp_0b/mace_agnesi_small.model
count=$((count +2))


# MACE_MP_0b2
printf "   Downloading MACE_MP-Ob2 (large/medium/small) ...\n\n"
# --- large
wget https://github.com/ACEsuit/mace-foundations/releases/download/mace_mp_0b2/mace-large-density-agnesi-stress.model
# --- medium
wget https://github.com/ACEsuit/mace-foundations/releases/download/mace_mp_0b2/mace-medium-density-agnesi-stress.model
# --- small
wget https://github.com/ACEsuit/mace-foundations/releases/download/mace_mp_0b2/mace-small-density-agnesi-stress.model
count=$((count +3))


# MACE_MP_0b3
printf "   Downloading MACE_MP-Ob3 (medium) ...\n\n"
# --- medium
wget https://github.com/ACEsuit/mace-foundations/releases/download/mace_mp_0b3/mace-mp-0b3-medium.model
count=$((count +1))


# MACE MPA-0
printf "   Downloading MPA-0 (medium) ...\n\n"
# --- medium
wget https://github.com/ACEsuit/mace-mp/releases/download/mace_mpa_0/mace-mpa-0-medium.model
count=$((count +1))


# MACE OMAT-0
printf "   Downloading MACE_OMAT-0 (medium/small) ...\n\n"
# --- medium
wget https://github.com/ACEsuit/mace-mp/releases/download/mace_omat_0/mace-omat-0-medium.model
# --- small
wget https://github.com/ACEsuit/mace-foundations/releases/download/mace_omat_0/mace-omat-0-small.model
count=$((count +2))


# MACE-MATPES-PBE-0
printf "   Downloading MACE-MATPES-PBE-0 (medium) ...\n\n"
# --- medium
wget https://github.com/ACEsuit/mace-foundations/releases/download/mace_matpes_0/MACE-matpes-pbe-omat-ft.model
count=$((count +1))


# MACE-MATPES-r2SCAN-0
printf "   Downloading MACE-MATPES-r2SCAN-0 (medium) ...\n\n"
# -- medium
wget https://github.com/ACEsuit/mace-foundations/releases/download/mace_matpes_0/MACE-matpes-r2scan-omat-ft.model
count=$((count +1))


# MACE-OMOL-0
printf "   Downloading MACE-OMOL-0 (extra-large/extra-large (4M) ...\n\n"
# --- extra-large
wget https://github.com/ACEsuit/mace-foundations/releases/download/mace_omol_0/MACE-omol-0-extra-large-1024.model
# --- extra-large (4M subset)
wget https://github.com/ACEsuit/mace-foundations/releases/download/mace_omol_0/mace-omol-0-extra-large-4M.model
count=$((count +2))


# MACE-MH-{0/1}
printf "   Downloading MACE-MH-{0/1} ...\n\n"
# --- mh-0
wget https://github.com/ACEsuit/mace-foundations/releases/download/mace_mh_1/mace-mh-0.model
# --- mh-1
wget https://github.com/ACEsuit/mace-foundations/releases/download/mace_mh_1/mace-mh-1.model
count=$((count +2))


# MACE-MDP
printf "   Downloading MACE-MDP ...\n\n"
wget https://raw.githubusercontent.com/Nilsgoe/MACE-MDP/main/models/MACE-MDP.model
count=$((count +1))

printf "  #Models to be downloaded:%s\n", "$TOTNUMBER"
printf "  #Models downloaded:%s\n", "$count"
printf "End:%s\n"  "$(date)"
