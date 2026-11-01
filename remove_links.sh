#!/bin/bash
#===============================================================================
# remove_links.sh
#-------------------------------------------------------------------------------
# PURPOSE:    Remove symbolic links from the LM Studio models directory; the
#             original files are left untouched.
# USAGE:      ./remove_links.sh [-y|--yes]
# OPTIONS:     -y, --yes   Do not ask for confirmation; remove immediately.
# DESCRIPTION: First prints all found links (including subdirectories) with
#              their targets (dry run); after confirmation it removes only the
#              links themselves, never their targets.
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

# Directory where LM Studio stores models (adjust if different)
MODELS_DIR="/mnt/s2n/lmstudio/"

if [ ! -d "$MODELS_DIR" ]; then
    echo "Error: directory $MODELS_DIR does not exist." >&2
    exit 1
fi

echo "=== Searching for symbolic links in: $MODELS_DIR ==="

# Collect all symbolic links (including subdirectories)
LINKS=()
while IFS= read -r -d '' LINK; do
    LINKS+=("$LINK")
done < <(find "$MODELS_DIR" -type l -print0)

if [ "${#LINKS[@]}" -eq 0 ]; then
    echo "No symbolic links found. Nothing to remove."
    exit 0
fi

# First print what would be removed (dry run)
echo "--- Symbolic links that will be removed: ---"
for LINK in "${LINKS[@]}"; do
    echo "  $LINK -> $(readlink "$LINK")"
done
echo ""

if [ "$ASSUME_YES" -eq 0 ]; then
    read -p "Remove these links? (y/N): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Perform the removal (only the links, never their targets)
COUNT=0
for LINK in "${LINKS[@]}"; do
    if rm -f "$LINK"; then
        COUNT=$((COUNT + 1))
    else
        echo "Warning: link not removed: $LINK" >&2
    fi
done

echo "=== Done. Links removed: $COUNT ==="
