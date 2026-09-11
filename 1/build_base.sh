#!/bin/bash
#
# build_base.sh
#
# Builds the base Apptainer container.
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
Usage: $0 [--ntasks/-n N] [--help/-h]

Builds the base container.

  --ntasks, -n  (OPTIONAL) Number of build tasks. Default: ${DEFAULT_NTASKS}

  --help, -h    (OPTIONAL) Show this help message and exit. No build is
                performed.

Examples:
  $0
  $0 --ntasks 4
  $0 -n 8
  $0 --help
EOF
}

# ---------------------------------------------------------------------------
# Parse command line
# ---------------------------------------------------------------------------
NTASKS="$DEFAULT_NTASKS"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
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

# --ntasks must be a positive integer
if ! [[ "$NTASKS" =~ ^[0-9]+$ ]] || [[ "$NTASKS" -lt 1 ]]; then
    printf "  ERROR :: --ntasks/-n must be a positive integer (got: %s).\n\n" "$NTASKS"
    usage
    exit 1
fi

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
printf "   The container base.sif will be built with %s ntasks\n" "$NTASKS"

set +e
apptainer build \
    --build-arg BUILD_DATE="$(date +%Y-%m-%d)" \
    --build-arg NTASKS="$NTASKS" \
      base.sif base.def
BUILD_STATUS=$?
set -e

if [[ "$BUILD_STATUS" -eq 0 ]]; then
    printf "\n   OK! :: base.sif build succeeded.\n"
else
    printf "\n   ERROR :: base.sif build failed (exit code %s).\n" "$BUILD_STATUS"
fi

END_DATE="$(date)"
printf "   End     : %s\n\n" "$END_DATE"

exit "$BUILD_STATUS"
