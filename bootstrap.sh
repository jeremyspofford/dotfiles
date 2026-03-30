#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/workspace/dotfiles"
REPO="https://github.com/jeremyspofford/dotfiles.git"

# ─── Platform detection ─────────────────────────────────────────────
case "$(uname -s)" in
  Darwin) PLATFORM="macos" ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      PLATFORM="wsl"
    else
      PLATFORM="linux"
    fi
    ;;
  *) echo "Unsupported platform: $(uname -s)"; exit 1 ;;
esac

echo "==> Installing prerequisites ($PLATFORM)..."
case "$PLATFORM" in
  macos)
    if ! command -v brew &>/dev/null; then
      echo "Homebrew not found. Install it first: https://brew.sh"
      exit 1
    fi
    brew install git stow zsh curl unzip
    ;;
  wsl|linux)
    if command -v apt-get &>/dev/null; then
      sudo apt-get update -qq
      sudo apt-get install -y -qq git stow zsh curl unzip
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y git stow zsh curl unzip
    elif command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm git stow zsh curl unzip
    else
      echo "No supported package manager found."
      exit 1
    fi
    ;;
esac

if [ -d "$DOTFILES_DIR" ]; then
  echo "==> Dotfiles already cloned, pulling latest..."
  git -C "$DOTFILES_DIR" pull --ff-only
else
  echo "==> Cloning dotfiles..."
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone "$REPO" "$DOTFILES_DIR"
fi

echo "==> Running install..."
"$DOTFILES_DIR/install.sh"

echo ""
echo "Done. Run 'exec zsh' to start your new shell."
