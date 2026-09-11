-- -*- lua -*-
help(
[[
    MACE LAMMPS (with GPU support)
      This is an experimental installation
]])

local version="0.3.16"
local base=pathJoin("/uufs/chpc.utah.edu/sys/installdir/r8/mace-lmp/", version)

-- text array of commands to alias from the container
local COMMANDS = {"mpirun"}
-- set to true if the container requires GPU(s)
local GPU = true
-- set to true if the container uses the COMMANDS internally - in that case the 
-- command aliases can not be passed into the container
local CLEANENV = true

whatis("Name         : mace-lmp ")
whatis("Version      : 0.3.16")
whatis("Category     : Molecular Dynamics, ML")
whatis("URL          : https://mace-docs.readthedocs.io/en/latest/guide/lammps.html")
whatis("Installed on : 09/11/2026")
whatis("Installed by : Wim R.M. Cardoen")

depends_on("apptainer")

-- ----------------------------------------------------------------------
-- GPU detection + compute-capability-based CUDA/container selection
-- ----------------------------------------------------------------------

-- 1. Check that an NVIDIA GPU is actually present.
local gpu_check = capture("nvidia-smi -L 2>/dev/null")

if gpu_check == nil or gpu_check == "" then
    LmodError("mace-lmp: No NVIDIA GPU was detected on this node. "..
              "This module requires a CUDA-capable NVIDIA GPU to run.")
end

-- 2. Query the compute capability of the (first) GPU.
--    nvidia-smi --query-gpu=name,compute_cap --format=csv | tail -n 1 | cut -d"," -f2
local cmd = 'nvidia-smi --query-gpu=name,compute_cap --format=csv | tail -n 1 | cut -d"," -f2'
local raw_cap = capture(cmd)

if raw_cap == nil or raw_cap == "" then
    LmodError("mace-lmp: Unable to determine the GPU compute capability "..
              "(nvidia-smi query returned no output).")
end

-- Trim whitespace/newlines from the captured output.
local compute_cap = raw_cap:gsub("%s+", "")

-- 3. Branch on compute capability.
--    Older versions of CUDA ARCHITECTURES at CHPC
local older_caps = {
    ["5.0"] = true,
    ["5.2"] = true,
    ["5.3"] = true,
    ["6.0"] = true,
    ["6.1"] = true,
    ["7.0"] = true,
}

local CONTAINER
if older_caps[compute_cap] then
    depends_on("cuda/12.6.3")
    CONTAINER = pathJoin(base, "lmg_older.sif")
else
    depends_on("cuda/12.8.1")
    CONTAINER = pathJoin(base, "lmg_modern.sif")
end

setenv("MACE_LMP_GPU_COMPUTE_CAP", compute_cap)

-- ----------------------------------------------------------------------

if GPU then
  nvswitch = '--nv '
  setenv("APPTAINER_NV","true")
  add_property("arch","gpu")
else
  nvswitch = ''
end


if CLEANENV then
  setenv("APPTAINER_CLEANENV","true")
  -- WRC: update on 09/11/2026
  -- --cleanenv strips almost all host env vars, including CUDA_VISIBLE_DEVICES
  -- which is how SLURM finds the allocated GPU(s).
  -- In order to make the CUDA_VISIBLE_DEVICES visible to the container
  -- it needs to be reinjected using the APPTAINERENV_ prefix.
  local cuda_visible_devices = os.getenv("CUDA_VISIBLE_DEVICES")
  if cuda_visible_devices then
     setenv("APPTAINERENV_CUDA_VISIBLE_DEVICES", cuda_visible_devices)
  end

  -- WRC: update on 09/11/2026 (2)
  -- If nvidia-container-cli is present on the host, Apptainer's --nv delegates
  -- GPU binding to it instead of doing a plain bind-mount. That tool gates
  -- device/driver-library exposure on NVIDIA_VISIBLE_DEVICES and
  -- NVIDIA_DRIVER_CAPABILITIES (not CUDA_VISIBLE_DEVICES), and defaults to
  -- binding nothing if they're unset and the image has no matching labels.
  -- --cleanenv strips these too, so forward them explicitly.
  setenv("APPTAINERENV_NVIDIA_VISIBLE_DEVICES", cuda_visible_devices or "all")
  setenv("APPTAINERENV_NVIDIA_DRIVER_CAPABILITIES", "compute,utility")
end


local run_shell = 'singularity shell ' .. nvswitch .. '-s /bin/bash ' .. CONTAINER
local run_cmd = 'singularity exec ' .. nvswitch .. ' ' .. CONTAINER
-- container is executable, so can run as "container.sif command"
local run_function = 'singularity exec ' .. nvswitch .. ' ' .. CONTAINER 
-- set shell access to the container with "containerShell" command
set_shell_function("containerShell", run_shell, run_shell)
set_shell_function("containerRun", run_cmd .. ' "$@"', run_cmd .. ' $*')

-- loop over COMMANDS array to create the shell functions
for ic,program in pairs(COMMANDS) do
  set_shell_function(program, run_function .. " " .. program .. " $@",run_function .. " " .. program .. " $*")
end

-- to export the shell function to a subshell
-- newer Lmod in bash sets/unsets this automatically
if (myShellType() == "csh") then
  execute{cmd="unalias containerShell",modeA={"unload"}}
  execute{cmd="unalias " .. table.concat(COMMANDS, " "),modeA={"unload"}}
  execute{cmd="unalias containerRun",modeA={"unload"}}
end
