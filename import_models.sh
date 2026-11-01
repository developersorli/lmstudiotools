#!/bin/bash
#===============================================================================
# import_models.sh
#-------------------------------------------------------------------------------
# PURPOSE:    Import .gguf models from multiple directories into LM Studio via
#             symbolic links (files stay on their source drives, no copying).
# USAGE:      ./import_models.sh [--dry-run] [-h|--help]
# OPTIONS:    --dry-run, -n   Print what would be imported without importing.
#             -h, --help      Show this description and exit.
# DESCRIPTION: Iterates over the directories in DIRS, finds all *.gguf files
#              (including subdirectories) and runs for each one:
#                  lms import <path> --symbolic-link --user-repo <publisher/name>
#              The publisher is the first subdirectory of the relative path; if
#              the file lies directly in the directory, "local" is used.
#              Duplicate user-repo values (same name in different folders) are
#              reported with a warning.
# REQUIREMENTS: LM Studio CLI (lms command) must be in PATH, except for --dry-run.
# EXIT CODES: 0 = success, 1 = startup error/missing lms/unknown option,
#             2 = at least one import failed
#===============================================================================

set -u

usage() {
    cat <<'EOF'
Usage: ./import_models.sh [--dry-run] [-h|--help]

Imports all .gguf models from the DIRS directories into LM Studio via symbolic links.

Options:
  --dry-run, -n   Print what would be imported, without importing.
  -h, --help      Show this help and exit.
EOF
}

#--- Parse arguments ------------------------------------------------------------
DRY_RUN=0
for ARG in "$@"; do
    case "$ARG" in
        --dry-run|-n) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Error: unknown option '$ARG'." >&2; echo "" >&2; usage >&2; exit 1 ;;
    esac
done

# Target directories containing models (adjust to your installation)
DIRS=(
    "/mnt/ssd/lmstudio"
    "/mnt/s2n/lmstudio"
)

# Check that the lms command exists (not required for --dry-run)
if [ "$DRY_RUN" -eq 0 ] && ! command -v lms &>/dev/null; then
    echo "Error: lms command not found. Check your LM Studio CLI installation." >&2
    exit 1
fi

#--- Collect and import models --------------------------------------------------
declare -A SEEN_REPOS=()   # user-repo -> path of the first file (for collision warnings)
TOTAL=0
OK=0
FAILED=0

if [ "$DRY_RUN" -eq 1 ]; then
    echo "=== DRY RUN: no import will be performed ==="
fi

# Iterate over each directory
for DIR in "${DIRS[@]}"; do
    if [ ! -d "$DIR" ]; then
        echo "Warning: directory $DIR does not exist, skipping." >&2
        continue
    fi

    echo ""
    echo "=== Scanning: $DIR ==="

    # Find all .gguf files (including subdirectories)
    while IFS= read -r -d '' FILE; do
        TOTAL=$((TOTAL + 1))

        # Get the path relative to DIR, e.g. Qwen/Qwen-7B.gguf
        REL_PATH="${FILE#$DIR/}"

        # Split into publisher and model name.
        # Assumed structure is DIR/publisher/.../file.gguf; without a
        # publisher subdirectory, "local" is used.
        if [[ "$REL_PATH" == */* ]]; then
            PUBLISHER="${REL_PATH%%/*}"
        else
            PUBLISHER="local"
        fi
        MODEL_NAME="${FILE##*/}"; MODEL_NAME="${MODEL_NAME%.gguf}"

        # Build the --user-repo value in publisher/model-name form
        USER_REPO="${PUBLISHER}/${MODEL_NAME}"

        if [ -n "${SEEN_REPOS[$USER_REPO]:-}" ]; then
            echo "  Warning: user-repo '$USER_REPO' is already taken by:" >&2
            echo "    first:  ${SEEN_REPOS[$USER_REPO]}" >&2
            echo "    next:   $FILE" >&2
        fi
        SEEN_REPOS["$USER_REPO"]="$FILE"

        if [ "$DRY_RUN" -eq 1 ]; then
            echo "[dry-run] would import: $FILE -> --user-repo $USER_REPO"
            continue
        fi

        echo "Importing: $FILE"
        echo "  -> --user-repo $USER_REPO"

        # Import using a symbolic link
        if lms import "$FILE" --symbolic-link --user-repo "$USER_REPO"; then
            OK=$((OK + 1))
        else
            FAILED=$((FAILED + 1))
            echo "  Error during import: $FILE" >&2
        fi
    done < <(find "$DIR" -type f -name "*.gguf" -print0)
done

#--- Summary ---------------------------------------------------------------------
echo ""
if [ "$DRY_RUN" -eq 1 ]; then
    echo "=== Dry run finished. Files to import: $TOTAL ==="
else
    echo "=== Import finished. Total: $TOTAL, OK: $OK, failed: $FAILED ==="
fi

if [ "$DRY_RUN" -eq 0 ] && [ "$FAILED" -gt 0 ]; then
    exit 2
fi
exit 0