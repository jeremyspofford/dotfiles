#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/workspace/dotfiles"
REPO="https://github.com/jeremyspofford/dotfiles.git"

echo "==> Installing prerequisites..."
sudo apt-get update -qq
sudo apt-get install -y -qq git stow zsh curl unzip

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

if [ "$(basename "$SHELL")" != "zsh" ]; then
  echo "==> Setting zsh as default shell..."
  sudo chsh -s "$(which zsh)" "$USER"
fi

echo ""
echo "Done. Run 'exec zsh' to start your new shell."
