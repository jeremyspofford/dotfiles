#!/usr/bin/env bash
set -euo pipefail

# Stow (or restow) dotfiles packages.
#
#   ./stow.sh                  # restow every package under packages/
#   ./stow.sh shell claude     # restow only the named packages
#   ./stow.sh -n               # dry-run preview, no filesystem changes
#
# Re-runnable: real files in $HOME that would conflict with a symlink
# get moved to ~/.dotfiles_backup/ first. Already-stowed packages are
# refreshed via `stow -R`, which prunes dead symlinks left by deleted
# tracked files. Called by install.sh on fresh setups.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOWRC="$HOME/.stowrc"
BACKUP_DIR="$HOME/.dotfiles_backup"

DRY_RUN=false
PACKAGES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=true; shift ;;
    -h|--help)
      sed -n '3,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    --) shift; PACKAGES+=("$@"); break ;;
    -*) echo "stow.sh: unknown flag: $1" >&2; exit 2 ;;
    *)  PACKAGES+=("$1"); shift ;;
  esac
done

# Default to every directory under packages/ when none specified.
if [ ${#PACKAGES[@]} -eq 0 ]; then
  for dir in "$DOTFILES_DIR"/packages/*/; do
    PACKAGES+=("$(basename "$dir")")
  done
fi

# ─── Ensure ~/.stowrc points at the current packages dir ───────────
# Pins stow's --dir/--target so plain `stow <pkg>` works from any cwd.
# On machines bootstrapped before the packages/ restructure, back up
# the stale file before rewriting so nothing is silently lost.
ensure_stowrc() {
  local stow_dir="$DOTFILES_DIR/packages"
  local expected
  expected="$(printf -- '--dir=%s\n--target=%s\n' "$stow_dir" "$HOME")"

  if [ -f "$STOWRC" ] && [ "$(cat "$STOWRC")" = "$expected" ]; then
    return 0
  fi

  if $DRY_RUN; then
    echo "[dry-run] would write ~/.stowrc (--dir=$stow_dir)"
    return 0
  fi

  if [ -f "$STOWRC" ]; then
    local backup
    backup="$BACKUP_DIR/stowrc.$(date +%Y%m%dT%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp "$STOWRC" "$backup"
    echo "  Backed up existing ~/.stowrc -> $backup"
  fi

  printf '%s' "$expected" > "$STOWRC"
  echo "Wrote ~/.stowrc (--dir=$stow_dir)"
}

ensure_stowrc

# ─── Conflict-resolution disclaimer ────────────────────────────────
# Heads-up to the user before we touch their $HOME on a fresh machine.
# Skipped under --dry-run since nothing mutates.
if ! $DRY_RUN; then
  echo "Resolving conflicts at managed dotfile paths:"
  echo "  - Regular files will be MOVED to ~/.dotfiles_backup/ (preserving structure)."
  echo "  - Foreign symlinks (older dotfiles tools, oh-my-zsh, etc.) will be REMOVED."
  echo "  - Paths already linked to this dotfiles repo are left alone."
fi

# ─── Stow each package ────────────────────────────────────────────
# -v on real runs surfaces what got linked; under -n it floods output
# with UNLINK/LINK pairs that cancel out (stow's restow simulation),
# so we drop it for previews and only show net warnings.
if $DRY_RUN; then
  stow_flags=(-n -R -d "$DOTFILES_DIR/packages" -t "$HOME")
else
  stow_flags=(-v -R -d "$DOTFILES_DIR/packages" -t "$HOME")
fi

for pkg in "${PACKAGES[@]}"; do
  dir="$DOTFILES_DIR/packages/$pkg/"
  if [ ! -d "$dir" ]; then
    echo "stow.sh: skipping '$pkg' — no such package" >&2
    continue
  fi

  # Resolve conflicts before stow runs. Three cases per file:
  #   - target -ef source → already linked to our source (possibly
  #     via a tree-folded parent symlink). Skip; the -ef test prevents
  #     re-runs from moving our own source files into $BACKUP_DIR.
  #   - any other symlink → foreign (older dotfiles tool, oh-my-zsh,
  #     broken link). Remove it; user was warned at the top of the run.
  #   - regular file → move to $BACKUP_DIR preserving structure.
  # Skipped under --dry-run since it mutates.
  if ! $DRY_RUN; then
    while IFS= read -r -d '' file; do
      rel="${file#"$dir"}"
      target="$HOME/$rel"
      if [ "$target" -ef "$file" ]; then
        continue
      elif [ -L "$target" ]; then
        link_target="$(readlink "$target")"
        rm "$target"
        echo "  Removed foreign symlink: ~/$rel (was -> $link_target)"
      elif [ -f "$target" ]; then
        backup_path="$BACKUP_DIR/$rel"
        mkdir -p "$(dirname "$backup_path")"
        mv "$target" "$backup_path"
        echo "  Backed up: ~/$rel -> ~/.dotfiles_backup/$rel"
      fi
    done < <(find "$dir" -type f -print0)
  fi

  echo "Stowing $pkg..."
  # Filter the cosmetic "BUG in find_stowed_path" warning that fires
  # when tree-folding interacts with already-stowed parents.
  stow "${stow_flags[@]}" "$pkg" 2> >(grep -v "BUG in find_stowed_path" >&2)
done

if [ -d "$BACKUP_DIR" ] && ! $DRY_RUN; then
  echo "Originals saved to ~/.dotfiles_backup/"
fi
