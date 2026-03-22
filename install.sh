#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOWRC="$HOME/.stowrc"
BACKUP_DIR="$HOME/.dotfiles_backup"

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
  *) PLATFORM="unknown" ;;
esac

# ─── Install stow if missing ─────────────────────────────────────────
if ! command -v stow &>/dev/null; then
  echo "GNU Stow not found. Installing..."
  case "$PLATFORM" in
    macos)       brew install stow ;;
    wsl|linux)
      if command -v apt-get &>/dev/null; then
        sudo apt-get install -y stow
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y stow
      elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm stow
      else
        echo "Could not detect package manager. Install stow manually."
        exit 1
      fi
      ;;
    *)
      echo "Unsupported platform. Install stow manually."
      exit 1
      ;;
  esac
fi

# ─── SSH directory setup ────────────────────────────────────────────
mkdir -p "$HOME/.ssh/keys"
chmod 700 "$HOME/.ssh"

# ─── First run: back up conflicting files ───────────────────────────
if [ ! -f "$STOWRC" ]; then
  echo "First run — checking for existing files to back up..."

  for dir in "$DOTFILES_DIR"/*/; do
    pkg="$(basename "$dir")"
    while IFS= read -r -d '' file; do
      rel="${file#"$dir"}"
      target="$HOME/$rel"
      if [ -f "$target" ] && [ ! -L "$target" ]; then
        backup_path="$BACKUP_DIR/$rel"
        mkdir -p "$(dirname "$backup_path")"
        mv "$target" "$backup_path"
        echo "  Backed up: ~/$rel -> ~/.dotfiles_backup/$rel"
      fi
    done < <(find "$dir" -type f -print0)
  done

  if [ -d "$BACKUP_DIR" ]; then
    echo "Originals saved to ~/.dotfiles_backup/"
  fi

  # Create .stowrc with defaults for manual stow commands
  cat > "$STOWRC" << EOF
--dir=$DOTFILES_DIR
--target=$HOME
EOF
  echo "Created ~/.stowrc"
fi

# ─── Stow all packages ─────────────────────────────────────────────
for dir in "$DOTFILES_DIR"/*/; do
  pkg="$(basename "$dir")"
  echo "Stowing $pkg..."
  stow -R -v -d "$DOTFILES_DIR" -t "$HOME" "$pkg" 2> >(grep -v "BUG in find_stowed_path" >&2)
done

# ─── Nerd Font install ──────────────────────────────────────────────
install_nerd_font() {
  local font_dir

  case "$PLATFORM" in
    macos)  font_dir="$HOME/Library/Fonts" ;;
    wsl)
      local win_user
      win_user="$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')"
      font_dir="/mnt/c/Users/$win_user/AppData/Local/Microsoft/Windows/Fonts"
      ;;
    *)      font_dir="$HOME/.local/share/fonts" ;;
  esac

  # Skip if already installed
  if ls "$font_dir"/JetBrainsMonoNerd* &>/dev/null; then
    echo "Nerd Font already installed."
    return
  fi

  if ! command -v curl &>/dev/null; then
    echo "curl not found — skipping Nerd Font install."
    return
  fi
  if ! command -v unzip &>/dev/null; then
    echo "unzip not found — skipping Nerd Font install."
    return
  fi

  echo "Installing JetBrains Mono Nerd Font..."
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap "rm -rf '$tmp_dir'" RETURN

  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" \
    -o "$tmp_dir/font.zip"
  unzip -qo "$tmp_dir/font.zip" "*.ttf" -d "$tmp_dir/font"

  mkdir -p "$font_dir"
  cp "$tmp_dir"/font/*.ttf "$font_dir/"

  # Refresh font cache on native Linux
  if [ "$PLATFORM" = "linux" ] && command -v fc-cache &>/dev/null; then
    fc-cache -f "$font_dir"
  fi

  echo "Nerd Font installed to $font_dir"
}

install_nerd_font

# ─── Nerd Font registration check ──────────────────────────────────
check_font_registered() {
  case "$PLATFORM" in
    wsl)
      powershell.exe -NoProfile -Command \
        "(New-Object System.Drawing.Text.InstalledFontCollection).Families.Name" 2>/dev/null \
        | tr -d '\r' | grep -q "JetBrainsMono Nerd Font Mono"
      ;;
    macos)
      system_profiler SPFontsDataType 2>/dev/null | grep -q "JetBrainsMono Nerd Font Mono"
      ;;
    *)
      fc-list 2>/dev/null | grep -q "JetBrainsMono Nerd Font Mono"
      ;;
  esac
}

if ! check_font_registered; then
  echo ""
  echo "JetBrainsMono Nerd Font Mono is downloaded but not installed."
  echo "You need to install it for Neovim icons to render correctly."
  echo "  Search for: JetBrainsMonoNerdFontMono-"
  echo "  Select all matches, right-click, and install them."
  echo "  Then set your terminal font to 'JetBrainsMono Nerd Font Mono'."
  read -rp "Open the font directory now? [y/N] " yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    case "$PLATFORM" in
      wsl)
        win_user="$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')"
        font_path="/mnt/c/Users/$win_user/AppData/Local/Microsoft/Windows/Fonts"
        first_font="$(ls "$font_path"/JetBrainsMonoNerdFont-Regular.ttf 2>/dev/null || ls "$font_path"/JetBrainsMonoNerd* 2>/dev/null | head -1)"
        if [ -n "$first_font" ]; then
          explorer.exe /select,"$(wslpath -w "$first_font")" 2>/dev/null
        else
          explorer.exe "$(wslpath -w "$font_path")" 2>/dev/null
        fi
        ;;
      macos)
        first_font="$(ls "$HOME/Library/Fonts"/JetBrainsMonoNerdFont-Regular.ttf 2>/dev/null || ls "$HOME/Library/Fonts"/JetBrainsMonoNerd* 2>/dev/null | head -1)"
        if [ -n "$first_font" ]; then
          open -R "$first_font"
        else
          open "$HOME/Library/Fonts"
        fi
        ;;
      *)
        xdg-open "$HOME/.local/share/fonts" 2>/dev/null
        ;;
    esac
  fi
fi

echo ""
echo "Done. Restart your shell to pick up changes."
