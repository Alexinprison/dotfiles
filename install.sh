#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./install.sh [--dry-run] [--target DIRECTORY] [PACKAGE ...]

Packages: bash git npm tmux vscode jupyter
Default: install all packages into HOME using GNU Stow.

  --dry-run           Preview links without changing files.
  --target DIRECTORY  Use an existing directory instead of HOME.
  -h, --help          Show this help message.

Existing conflicting files are never adopted or overwritten by this script.
Back up conflicts outside the repository, then run the script again.
EOF
}

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
target="$HOME"
stow_options=()
packages=()

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run)
            stow_options+=(--simulate)
            shift
            ;;
        --target)
            if [ "$#" -lt 2 ] || [ -z "$2" ]; then
                printf 'install.sh: --target requires a directory\n' >&2
                exit 2
            fi
            target="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        bash|git|npm|tmux|vscode|jupyter)
            packages+=("$1")
            shift
            ;;
        *)
            printf 'install.sh: unknown option or package: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if ! command -v stow >/dev/null 2>&1; then
    printf 'install.sh: GNU Stow is required (Ubuntu: sudo apt install stow)\n' >&2
    exit 1
fi
if [ ! -d "$target" ]; then
    printf 'install.sh: target directory does not exist: %s\n' "$target" >&2
    exit 1
fi
if [ "${#packages[@]}" -eq 0 ]; then
    packages=(bash git npm tmux vscode jupyter)
fi
target="$(cd -- "$target" && pwd -P)"

# Link individual files so application state cannot spill into the repository.
exec stow --dir="$repo_dir" --target="$target" --no-folding --verbose \
    "${stow_options[@]}" "${packages[@]}"
