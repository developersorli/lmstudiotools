#!/bin/bash
#===============================================================================
# duplicates.sh
#-------------------------------------------------------------------------------
# PURPOSE:    Find .gguf files with identical names in both model directories.
# USAGE:      ./duplicates.sh
# DESCRIPTION: Compares the base names (without paths) of all *.gguf files from
#              directories A and B; for every common match it prints the full
#              paths and sizes. Since only file names are compared, files with
#              the same name in different subdirectories (e.g. Qwen/x.gguf vs
#              Meta/x.gguf) also appear on the list - check the full path for
#              each hit. Temp files are created in a private mktemp directory
#              and cleaned up automatically after the run.
# REQUIREMENTS: Both directories (A and B) must exist.
# EXIT CODES: 0 = success (also when there are no duplicates), 1 = missing dir
#===============================================================================

set -u

DIR_A="/mnt/ssd/lmstudio"
DIR_B="/mnt/s2n/lmstudio"

# Check that both directories exist
for D in "$DIR_A" "$DIR_B"; do
    if [ ! -d "$D" ]; then
        echo "Error: directory $D does not exist." >&2
        exit 1
    fi
done

# Temp files in a private directory; cleaned up on exit (also on error)
TMP_DIR=$(mktemp -d) || { echo "Error: cannot create temporary directory." >&2; exit 1; }
trap 'rm -rf "$TMP_DIR"' EXIT

# Build the list of file names from both directories
find "$DIR_A" -type f -name "*.gguf" -printf "%f\n" | sort > "$TMP_DIR/a_names.txt"
find "$DIR_B" -type f -name "*.gguf" -printf "%f\n" | sort > "$TMP_DIR/b_names.txt"

# Find the common names
comm -12 "$TMP_DIR/a_names.txt" "$TMP_DIR/b_names.txt" > "$TMP_DIR/duplicates.txt"

echo "=== Duplicated file names: ==="
if [ -s "$TMP_DIR/duplicates.txt" ]; then
    cat "$TMP_DIR/duplicates.txt"
else
    echo "(no duplicated names)"
fi

# For each duplicated name print the full paths and sizes
while IFS= read -r NAME; do
    [ -n "$NAME" ] || continue
    echo ""
    echo "Name: $NAME"
    find "$DIR_A" -type f -name "$NAME" -printf "  A: %p (%s bytes)\n"
    find "$DIR_B" -type f -name "$NAME" -printf "  B: %p (%s bytes)\n"
done < "$TMP_DIR/duplicates.txt"

COUNT=$(wc -l < "$TMP_DIR/duplicates.txt")
echo ""
echo "=== Done. Duplicated names: $COUNT ==="