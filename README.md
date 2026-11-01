# LM Studio Tools

[Slovenščina](README.sl.md)

## The problem

AI model files are huge. A single `.gguf` file commonly takes 4–8 GB, a large
high-quality model can exceed 40 GB, and a useful collection of models quickly
adds up to hundreds of gigabytes or more.

LM Studio manages its library from **a single models directory**, so the whole
collection has to live on one drive — typically the small, expensive NVMe SSD —
even though most of your models do not need that kind of speed.

## The solution

The scripts import your models into LM Studio through **symbolic links**, so the
library physically spans several disks at once (nothing is copied or duplicated).
You can place every model where it makes sense:

- **smaller, less frequently used models** → slower or cheaper drives (SATA SSD,
  HDD, external USB disk);
- **large, actively used models** → the fastest and largest drive (NVMe SSD).

LM Studio shows everything in one combined list of models and loads each model
from the disk where it actually lives. Reorganizing later is cheap: remove the
links, move files between disks, import again.

In this setup the library spans two directories:

- `/mnt/ssd/lmstudio` (directory A)
- `/mnt/s2n/lmstudio` (directory B, which is also the LM Studio models directory)

## Tools

The available tools cover these operations:

| Script | Purpose |
|---|---|
| `import_models.sh` | Imports all `.gguf` models from both directories into LM Studio via symbolic links |
| `duplicates.sh` | Finds `.gguf` files with identical names in both directories (with full paths and sizes) |
| `remove_links.sh` | Removes symbolic links from the models directory; source files are left untouched |
| `remove_empty_dirs.sh` | Removes empty subdirectories from the models directory; non-empty ones remain |

## Typical workflow

1. **Check for duplicate models:**
   ```sh
   ./duplicates.sh
   ```
   Decide which disk will be the source for each model (e.g. frequently used ones on SSD).

2. **(Optional) Dry-run preview of the import — no side effects:**
   ```sh
   ./import_models.sh --dry-run
   ```

3. **Build the combined library** (symbolic links into LM Studio):
   ```sh
   ./import_models.sh
   ```
   Prints a summary `Total / OK / failed`; if any import fails, the exit code is `2`.

4. **Reset** (remove links and clean up empty folders):
   ```sh
   ./remove_links.sh -y
   ./remove_empty_dirs.sh -y
   ```

## Usage by script

### import_models.sh

```sh
./import_models.sh [--dry-run] [-h|--help]
```

| Option | Meaning |
|---|---|
| `--dry-run`, `-n` | Prints what would be imported, without actually importing (does not require the `lms` command) |
| `-h`, `--help` | Shows help and exits |

Adjust the directories in the `DIRS` list at the top of the script.

**user-repo naming rules:**
- Publisher = first subdirectory of the relative path (`Qwen/Qwen-7B.gguf` → `Qwen/Qwen-7B`).
- File directly in the directory root → publisher is `local`.
- Repeated user-repo values (same file name producing the same user-repo) are warned about; a later import can abort or overwrite an earlier one.

**Exit codes:** `0` success · `1` startup error / missing `lms` / unknown option · `2` at least one import failed.

### duplicates.sh

```sh
./duplicates.sh
```

Compares the **base names** (without paths) of all `.gguf` files from both directories and,
for every common match, prints the full paths and sizes. Because only names are compared,
files with the same name in different subdirectories (e.g. `Qwen/x.gguf` and
`Meta/x.gguf`) also appear on the list — check the full path for each hit.

**Exit codes:** `0` success (also when there are no duplicates) · `1` missing directory.

### remove_links.sh

```sh
./remove_links.sh [-y|--yes]
```

First prints all found links with their targets (dry-run), then, after confirmation,
removes only the links themselves — their targets remain untouched.

| Option | Meaning |
|---|---|
| `-y`, `--yes` | Do not ask for confirmation; remove immediately |

**Exit codes:** `0` success/aborted · `1` error (directory missing / unknown option).

### remove_empty_dirs.sh

```sh
./remove_empty_dirs.sh [-y|--yes]
```

First prints all empty subdirectories (dry-run), then removes them after confirmation.
Directories are collected once and removed from that list, so exactly the listed
directories are removed. Non-empty directories remain untouched.

| Option | Meaning |
|---|---|
| `-y`, `--yes` | Do not ask for confirmation; remove immediately |

**Exit codes:** `0` success/aborted · `1` error (directory missing / unknown option).

## History / notes

- The scripts originally carried the `_fixed` suffix because they were created from
  CRLF (Windows line-ending) originals:
  ```sh
  tr -d '\r' < import_models.sh > import_models_fixed.sh
  chmod +x import_models_fixed.sh
  ```
  They have since been renamed to their current names without the suffix.
- All scripts now use LF line endings and carry in-file documentation headers.