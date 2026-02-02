#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}Installing dotfiles from ${DOTFILES_DIR}${NC}"

# Check for stow
if ! command -v stow &> /dev/null; then
    echo -e "${RED}GNU Stow is required but not installed.${NC}"
    echo "Install it with:"
    echo "  sudo apt install stow    # Debian/Ubuntu"
    echo "  brew install stow        # macOS"
    exit 1
fi

# Packages to install (directories that aren't hidden or special)
PACKAGES=($(find "$DOTFILES_DIR" -maxdepth 1 -type d \
    ! -name '.*' \
    ! -name 'scripts' \
    ! -path "$DOTFILES_DIR" \
    -printf '%f\n' | sort))

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No packages found to install.${NC}"
    exit 0
fi

echo -e "Found packages: ${PACKAGES[*]}"
echo ""

# Install each package
for pkg in "${PACKAGES[@]}"; do
    echo -e "${GREEN}Stowing ${pkg}...${NC}"
    
    # Use --adopt to handle existing files (moves them into the repo)
    # Remove --adopt if you want stow to fail on conflicts instead
    if stow -v -d "$DOTFILES_DIR" -t "$HOME" "$pkg" 2>&1; then
        echo -e "  ${GREEN}✓${NC} $pkg"
    else
        echo -e "  ${YELLOW}⚠${NC} $pkg (conflicts detected, resolve manually)"
    fi
done

echo ""
echo -e "${GREEN}Done!${NC}"
echo "Restart your shell or run: source ~/.bashrc"
