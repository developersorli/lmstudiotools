#!/bin/bash
#===============================================================================
# remove_empty_dirs.sh
#-------------------------------------------------------------------------------
# PURPOSE:    Remove empty subdirectories from the LM Studio models directory;
#             non-empty directories are left untouched.
# USAGE:      ./remove_empty_dirs.sh [-y|--yes]
# OPTIONS:     -y, --yes   Do not ask for confirmation; remove immediately.
# DESCRIPTION: First prints all empty subdirectories (including deep ones, dry
#              run); after confirmation it removes them. The directories are
#              collected once and removed from that list, so exactly the listed
#              directories are removed (no second scan).
# REQUIREMENTS: The MODELS_DIR directory must exist.
# EXIT CODES: 0 = success/aborted, 1 = error (missing dir/unknown option)
#===============================================================================

set -u

ASSUME_YES=0
for ARG in "$@"; do
    case "$ARG" in
        -y|--yes) ASSUME_YES=1 ;;
        *) echo "Error: unknown option '$ARG'." >&2; exit 1 ;;
    esac
done

MODELS_DIR="/mnt/s2n/lmstudio/"

if [ ! -d "$MODELS_DIR" ]; then
    echo "Error: directory $MODELS_DIR does not exist." >&2
    exit 1
fi

echo "=== Searching for empty directories in: $MODELS_DIR ==="

# Collect all empty subdirectories (excluding the root MODELS_DIR itself)
EMPTY_DIRS=()
while IFS= read -r -d '' D; do
    EMPTY_DIRS+=("$D")
done < <(find "$MODELS_DIR" -mindepth 1 -type d -empty -print0)

if [ "${#EMPTY_DIRS[@]}" -eq 0 ]; then
    echo "No empty directories found. Nothing to remove."
    exit 0
fi

# First print what would be removed (dry run)
echo "--- Empty directories that will be removed: ---"
printf '  %s\n' "${EMPTY_DIRS[@]}"
echo ""

if [ "$ASSUME_YES" -eq 0 ]; then
    read -p "Remove these directories? (y/N): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Perform the removal; skip empty dirs that are already gone (e.g. with their parent)
COUNT=0
for D in "${EMPTY_DIRS[@]}"; do
    if [ -d "$D" ] && rmdir "$D"; then
        COUNT=$((COUNT + 1))
    else
        echo "Warning: directory not removed: $D" >&2
    fi
done

echo "=== Done. Empty directories removed: $COUNT ==="