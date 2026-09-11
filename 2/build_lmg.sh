#!/bin/bash
#
# Author: Wim R.M. Cardoen
# Last update: 09/11/2026
#    --def (REQUIRED)
#    --test (Dry-run)
# 
#
# Builds the lmg (LAMMPS MACE GPU) Apptainer container.
# NOTE: This container only builds for GPU architectures.
#
# The valid GPU architectures are NOT hardcoded: they are discovered
# from whichever --def/-d file is supplied, by scanning the
# lmp-dispatch heredoc for lines of the form:
#     75) ARCHDIR=TURING75     ;;
# and pulling out the ARCHDIR values. This lets the same script drive
# lmg_older.def, lmg_modern.def, or any future split, as long as the
# def file follows that dispatcher convention.
#
set -euo pipefail

START_DATE="$(date)"
ORIG_ARGS=("$@")

DEFAULT_NTASKS="1"

# ---------------------------------------------------------------------------
# usage
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $0 --def/-d <def_file> --arch/-a [ALL | ARCH1 ARCH2 ...] \\
           [--ntasks/-n N] [--test/-t] [--help/-h]

Builds the lmg (LAMMPS MACE GPU) container. This container only builds
for GPU architectures.

  --def, -d     (MANDATORY) Path to the Apptainer .def file to build
                (e.g. lmg_older.def, lmg_modern.def). The set of valid
                GPU architectures is derived from this file's
                lmp-dispatch case statement (ARCHDIR=... entries).

  --arch, -a    (MANDATORY) Either the keyword ALL, or a space-separated
                list of one or more GPU architectures to build. Case
                insensitive. Valid choices depend on the --def file
                given (see --help output printed after --def is known,
                or pass an invalid arch to see the list).

  --ntasks, -n  (OPTIONAL) Number of build tasks. Default: ${DEFAULT_NTASKS}

  --test, -t    (OPTIONAL) Dry run. Print the apptainer build command
                that would be executed, but do not actually run it.

  --help, -h    (OPTIONAL) Show this help message and exit. No build is
                performed.

Examples:
  $0 --def lmg_modern.def --arch ALL
  $0 -d lmg_older.def -a maxwell50 pascal60 --ntasks 4
  $0 --def lmg_modern.def --arch HOPPER90 -n 8 --test
  $0 --help
EOF
}

# extract_valid_arches DEF_FILE
# Scans DEF_FILE's lmp-dispatch case statement for lines like:
#     75) ARCHDIR=TURING75     ;;
# and prints the unique ARCHDIR values, one per line, in file order.
extract_valid_arches() {
    local def_file="$1"
    grep -oP 'ARCHDIR=\K[A-Za-z0-9_]+' "$def_file" | awk '!seen[$0]++'
}

# is_valid_gpu_arch ARCH
# Returns 0 (true) if ARCH is a recognized GPU architecture, 1 otherwise.
is_valid_gpu_arch() {
    local arch="${1:-}"
    local a
    for a in "${VALID_GPU_ARCHES[@]}"; do
        [[ "$arch" == "$a" ]] && return 0
    done
    return 1
}

# arch_to_sm ARCH
# Derives the CUDA sm_XX value from a GPU architecture name, e.g.
# AMPERE80 -> sm_80, BLACKWELL120 -> sm_120.
arch_to_sm() {
    local arch="${1:-}"
    local digits="${arch//[!0-9]/}"
    printf "sm_%s" "$digits"
}

# ---------------------------------------------------------------------------
# Parse command line
# ---------------------------------------------------------------------------
SEL_ARCH_INPUT=()
NTASKS="$DEFAULT_NTASKS"
ARCH_SET=false
DEF_FILE=""
DEF_SET=false
TEST_MODE=false

is_flag() {
    case "$1" in
        --def|-d|--arch|-a|--ntasks|-n|--test|-t|--help|-h) return 0 ;;
        *) return 1 ;;
    esac
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --def|-d)
            shift
            if [[ $# -eq 0 ]]; then
                printf "  ERROR :: --def/-d requires a value.\n\n"
                usage
                exit 1
            fi
            DEF_FILE="$1"
            DEF_SET=true
            shift
            ;;
        --arch|-a)
            shift
            ARCH_SET=true
            # Consume all following args until the next recognized flag.
            while [[ $# -gt 0 ]] && ! is_flag "$1"; do
                SEL_ARCH_INPUT+=("$1")
                shift
            done
            ;;
        --ntasks|-n)
            shift
            if [[ $# -eq 0 ]]; then
                printf "  ERROR :: --ntasks/-n requires a value.\n\n"
                usage
                exit 1
            fi
            NTASKS="$1"
            shift
            ;;
        --test|-t)
            TEST_MODE=true
            shift
            ;;
        *)
            printf "  ERROR :: Unrecognized argument: %s\n\n" "$1"
            usage
            exit 1
            ;;
    esac
done

# --def/-d is mandatory
if [[ "$DEF_SET" != true ]]; then
    printf "  ERROR :: --def/-d is mandatory.\n\n"
    usage
    exit 1
fi

if [[ ! -f "$DEF_FILE" ]]; then
    printf "  ERROR :: def file not found: %s\n\n" "$DEF_FILE"
    exit 1
fi
if [[ ! -r "$DEF_FILE" ]]; then
    printf "  ERROR :: def file not readable: %s\n\n" "$DEF_FILE"
    exit 1
fi

# --arch/-a is mandatory
if [[ "$ARCH_SET" != true || ${#SEL_ARCH_INPUT[@]} -eq 0 ]]; then
    printf "  ERROR :: --arch/-a is mandatory and requires at least one value.\n\n"
    usage
    exit 1
fi

# --ntasks must be a positive integer
if ! [[ "$NTASKS" =~ ^[0-9]+$ ]] || [[ "$NTASKS" -lt 1 ]]; then
    printf "  ERROR :: --ntasks/-n must be a positive integer (got: %s).\n\n" "$NTASKS"
    usage
    exit 1
fi

# ---------------------------------------------------------------------------
# Derive valid GPU architectures from the given --def file
# ---------------------------------------------------------------------------
mapfile -t VALID_GPU_ARCHES < <(extract_valid_arches "$DEF_FILE")

if [[ ${#VALID_GPU_ARCHES[@]} -eq 0 ]]; then
    printf "  ERROR :: Could not discover any GPU architectures (ARCHDIR=...) in %s\n\n" "$DEF_FILE"
    exit 1
fi

# ---------------------------------------------------------------------------
# Resolve requested architectures
# ---------------------------------------------------------------------------
SEL_ARCH=()

if [[ ${#SEL_ARCH_INPUT[@]} -eq 1 && "${SEL_ARCH_INPUT[0]^^}" == "ALL" ]]; then
    SEL_ARCH=("${VALID_GPU_ARCHES[@]}")
else
    for raw in "${SEL_ARCH_INPUT[@]}"; do
        upper="${raw^^}"
        if [[ "$upper" == "ALL" ]]; then
            printf "  ERROR :: ALL cannot be combined with other architectures.\n\n"
            usage
            exit 1
        fi
        if ! is_valid_gpu_arch "$upper"; then
            printf "  ERROR :: %s is not a valid GPU architecture for %s.\n" "$raw" "$DEF_FILE"
            printf "    Valid choices: %s\n\n" "${VALID_GPU_ARCHES[*]}"
            usage
            exit 1
        fi
        SEL_ARCH+=("$upper")
    done
fi

# De-duplicate while preserving order
declare -A _seen=()
UNIQ_ARCH=()
for a in "${SEL_ARCH[@]}"; do
    if [[ -z "${_seen[$a]:-}" ]]; then
        UNIQ_ARCH+=("$a")
        _seen[$a]=1
    fi
done
SEL_ARCH=("${UNIQ_ARCH[@]}")

ARCH="${SEL_ARCH[*]}"

# ---------------------------------------------------------------------------
# Derive output .sif name from the .def file (e.g. lmg_modern.def -> lmg_modern.sif)
# ---------------------------------------------------------------------------
DEF_BASENAME="$(basename -- "$DEF_FILE")"
SIF_FILE="${DEF_BASENAME%.def}.sif"

# ---------------------------------------------------------------------------
# Report and build
# ---------------------------------------------------------------------------
printf "   Command : %s" "$0"
if [[ ${#ORIG_ARGS[@]} -gt 0 ]]; then
    printf " %q" "${ORIG_ARGS[@]}"
fi
printf "\n"
printf "   Start   : %s\n\n" "$START_DATE"

printf "   CLI Checks passed!\n"
printf "   Def file: %s\n" "$DEF_FILE"
printf "   The container %s (LAMMPS MACE GPU) will be built with %s ntasks\n" "$SIF_FILE" "$NTASKS"
printf "   for the following architectures:\n"
for arch in $ARCH
do
    sm_value="$(arch_to_sm "$arch")"
    printf "      arch:%15s   %s\n" "$arch" "$sm_value"
done

BUILD_CMD=(apptainer build
    --build-arg "BUILD_DATE=$(date +%Y-%m-%d)"
    --build-arg "NTASKS=$NTASKS"
    --build-arg "ARCH=$ARCH"
    "$SIF_FILE" "$DEF_FILE"
)

if [[ "$TEST_MODE" == true ]]; then
    printf "\n   TEST MODE :: the following command would be executed:\n\n"
    printf "      "
    printf "%q " "${BUILD_CMD[@]}"
    printf "\n\n"
    exit 0
fi

set +e
"${BUILD_CMD[@]}"
BUILD_STATUS=$?
set -e

if [[ "$BUILD_STATUS" -eq 0 ]]; then
    printf "\n   OK! :: %s build succeeded.\n" "$SIF_FILE"
else
    printf "\n   ERROR :: %s build failed (exit code %s).\n" "$SIF_FILE" "$BUILD_STATUS"
fi

END_DATE="$(date)"
printf "   End     : %s\n\n" "$END_DATE"

exit "$BUILD_STATUS"
