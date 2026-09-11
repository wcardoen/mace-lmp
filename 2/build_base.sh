#!/bin/bash
#
# Author: Wim R.M. Cardoen
# Update: 09/11/2026
# build_base.sh : extension of 1/
#   i.e. .def file is MANDATORY
#
# Builds a base Apptainer container from a given .def file
# (e.g. base_modern.def, base_old.def).
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
Usage: $0 --def/-d DEF_FILE [--ntasks/-n N] [--help/-h]

Builds a base container from DEF_FILE. The resulting image name is derived
from DEF_FILE by replacing the .def extension with .sif (e.g.
base_modern.def -> base_modern.sif).

  --def, -d     (REQUIRED) Path to the .def file to build (e.g. base_modern.def,
                base_old.def).

  --ntasks, -n  (OPTIONAL) Number of build tasks. Default: ${DEFAULT_NTASKS}

  --help, -h    (OPTIONAL) Show this help message and exit. No build is
                performed.

Examples:
  $0 --def base_modern.def
  $0 -d base_old.def --ntasks 4
  $0 -d base_modern.def -n 8
  $0 --help
EOF
}

# ---------------------------------------------------------------------------
# Parse command line
# ---------------------------------------------------------------------------
NTASKS="$DEFAULT_NTASKS"
DEF_FILE=""

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
            shift
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

# --def/-d is required
if [[ -z "$DEF_FILE" ]]; then
    printf "  ERROR :: --def/-d is required.\n\n"
    usage
    exit 1
fi

# DEF_FILE must exist and end in .def
if [[ ! -f "$DEF_FILE" ]]; then
    printf "  ERROR :: def file not found: %s\n\n" "$DEF_FILE"
    usage
    exit 1
fi

if [[ "$DEF_FILE" != *.def ]]; then
    printf "  ERROR :: --def/-d must point to a .def file (got: %s).\n\n" "$DEF_FILE"
    usage
    exit 1
fi

# --ntasks must be a positive integer
if ! [[ "$NTASKS" =~ ^[0-9]+$ ]] || [[ "$NTASKS" -lt 1 ]]; then
    printf "  ERROR :: --ntasks/-n must be a positive integer (got: %s).\n\n" "$NTASKS"
    usage
    exit 1
fi

# Derive the .sif output name from the .def file (e.g. base_modern.def -> base_modern.sif)
SIF_FILE="${DEF_FILE%.def}.sif"

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
printf "   The container %s will be built from %s with %s ntasks\n" "$SIF_FILE" "$DEF_FILE" "$NTASKS"

set +e
apptainer build \
    --build-arg BUILD_DATE="$(date +%Y-%m-%d)" \
    --build-arg NTASKS="$NTASKS" \
      "$SIF_FILE" "$DEF_FILE"
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
