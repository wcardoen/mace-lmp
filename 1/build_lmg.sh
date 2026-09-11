#!/bin/bash
#
# build_lmg.sh
#
# Builds the lmg (LAMMPS MACE GPU) Apptainer container.
# NOTE: This container only builds for GPU architectures.
#
set -euo pipefail

START_DATE="$(date)"
ORIG_ARGS=("$@")

VALID_GPU_ARCHES=(
    MAXWELL50 MAXWELL52 MAXWELL53
    PASCAL60 PASCAL61
    VOLTA70
    TURING75
    AMPERE80 AMPERE86
    ADA89
    HOPPER90
    BLACKWELL100 BLACKWELL120
)

DEFAULT_NTASKS="1"

# ---------------------------------------------------------------------------
# usage
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $0 --arch/-a [ALL | ARCH1 ARCH2 ...] [--ntasks/-n N] [--help/-h]

Builds the lmg (LAMMPS MACE GPU) container. This container only builds
for GPU architectures.

  --arch, -a    (MANDATORY) Either the keyword ALL, or a space-separated
                list of one or more GPU architectures to build. Case
                insensitive.

                Valid choices: ${VALID_GPU_ARCHES[*]}

  --ntasks, -n  (OPTIONAL) Number of build tasks. Default: ${DEFAULT_NTASKS}

  --help, -h    (OPTIONAL) Show this help message and exit. No build is
                performed.

Examples:
  $0 --arch ALL
  $0 -a ampere80 hopper90 --ntasks 4
  $0 --arch VOLTA70 -n 8
  $0 --help
EOF
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

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --arch|-a)
            shift
            ARCH_SET=true
            # Consume all following args until the next recognized flag.
            while [[ $# -gt 0 && "$1" != "--ntasks" && "$1" != "-n" && "$1" != "--help" && "$1" != "-h" ]]; do
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
        *)
            printf "  ERROR :: Unrecognized argument: %s\n\n" "$1"
            usage
            exit 1
            ;;
    esac
done

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
            printf "  ERROR :: %s is not a valid GPU architecture.\n" "$raw"
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
# Report and build
# ---------------------------------------------------------------------------
printf "   Command : %s" "$0"
if [[ ${#ORIG_ARGS[@]} -gt 0 ]]; then
    printf " %q" "${ORIG_ARGS[@]}"
fi
printf "\n"
printf "   Start   : %s\n\n" "$START_DATE"

printf "   CLI Checks passed!\n"
printf "   The container lmg.sif (LAMMPS MACE GPU) will be built with %s ntasks\n" "$NTASKS"
printf "   for the following architectures:\n"
for arch in $ARCH
do
    sm_value="$(arch_to_sm "$arch")"
    printf "      arch:%15s   %s\n" "$arch" "$sm_value"
done

set +e
apptainer build \
    --build-arg BUILD_DATE="$(date +%Y-%m-%d)" \
    --build-arg NTASKS="$NTASKS" \
    --build-arg ARCH="$ARCH" \
      lmg.sif lmg.def
BUILD_STATUS=$?
set -e

if [[ "$BUILD_STATUS" -eq 0 ]]; then
    printf "\n   OK! :: lmg.sif build succeeded.\n"
else
    printf "\n   ERROR :: lmg.sif build failed (exit code %s).\n" "$BUILD_STATUS"
fi

END_DATE="$(date)"
printf "   End     : %s\n\n" "$END_DATE"

exit "$BUILD_STATUS"
