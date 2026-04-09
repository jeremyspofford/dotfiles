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

# ─── Package manager helper ─────────────────────────────────────────
pkg_install() {
  case "$PLATFORM" in
    macos) brew install "$@" ;;
    wsl|linux)
      if command -v apt-get &>/dev/null; then
        sudo apt-get install -y "$@"
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$@"
      elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm "$@"
      else
        echo "No supported package manager. Install manually: $*"
        return 1
      fi
      ;;
  esac
}

# ─── Install base packages ──────────────────────────────────────────
install_base() {
  local needs_install=false
  for cmd in stow curl unzip zsh; do
    command -v "$cmd" &>/dev/null || { needs_install=true; break; }
  done

  if $needs_install; then
    echo "Installing base packages..."
    if command -v apt-get &>/dev/null; then
      sudo apt-get update -qq
    fi
    pkg_install stow curl unzip zsh
  fi
}

install_base

# ─── Install neovim ─────────────────────────────────────────────────
NVIM_VERSION="v0.11.0"

install_neovim() {
  if command -v nvim &>/dev/null; then
    local ver minor
    ver=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
    minor=${ver#*.}
    if [ "${ver%%.*}" -gt 0 ] 2>/dev/null || [ "$minor" -ge 11 ] 2>/dev/null; then
      return
    fi
    echo "Neovim $ver too old (need >= 0.11), upgrading..."
  fi

  case "$PLATFORM" in
    macos)
      brew install neovim
      ;;
    wsl|linux)
      if command -v apt-get &>/dev/null && [ "$(uname -m)" = "x86_64" ]; then
        echo "Installing Neovim $NVIM_VERSION from GitHub releases..."
        local tmp
        tmp=$(mktemp -d)
        trap "rm -rf '$tmp'" RETURN
        curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" \
          -o "$tmp/nvim.tar.gz"
        tar xzf "$tmp/nvim.tar.gz" -C "$tmp"
        sudo cp -r "$tmp"/nvim-linux-x86_64/* /usr/local/
      else
        pkg_install neovim
      fi
      ;;
  esac
  echo "Neovim installed: $(nvim --version | head -1)"
}

install_neovim

# ─── Install delta ──────────────────────────────────────────────────
install_delta() {
  command -v delta &>/dev/null && return

  case "$PLATFORM" in
    macos)
      brew install git-delta
      ;;
    wsl|linux)
      if command -v apt-get &>/dev/null; then
        echo "Installing delta from GitHub releases..."
        local tmp tag arch
        tmp=$(mktemp -d)
        trap "rm -rf '$tmp'" RETURN
        tag=$(curl -fsSI https://github.com/dandavison/delta/releases/latest \
          | grep -i '^location:' | sed 's|.*/||' | tr -d '\r\n')
        arch=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
        curl -fsSL "https://github.com/dandavison/delta/releases/download/${tag}/git-delta_${tag}_${arch}.deb" \
          -o "$tmp/delta.deb"
        sudo dpkg -i "$tmp/delta.deb"
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y git-delta
      elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm git-delta
      fi
      ;;
  esac
}

install_delta

# ─── Install mise ───────────────────────────────────────────────────
install_mise() {
  command -v mise &>/dev/null && return
  echo "Installing mise..."
  if [ "$PLATFORM" = "macos" ]; then
    brew install mise
  else
    curl https://mise.run | sh
  fi
}

install_mise

# ─── SSH directory setup ────────────────────────────────────────────
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# ─── SSH known hosts bootstrap ────────────────────────────────────
bootstrap_known_hosts() {
  local hosts="github.com gitlab.com"

  local needs_scan=false
  for host in $hosts; do
    if ! grep -q "^$host " "$HOME/.ssh/known_hosts" 2>/dev/null; then
      needs_scan=true
      break
    fi
  done

  if $needs_scan; then
    echo "Adding SSH host keys to ~/.ssh/known_hosts..."
    ssh-keyscan $hosts >> "$HOME/.ssh/known_hosts" 2>/dev/null
  fi

  if [ "$PLATFORM" = "wsl" ]; then
    local win_user
    win_user="$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')"
    local win_known_hosts="/mnt/c/Users/$win_user/.ssh/known_hosts"
    mkdir -p "$(dirname "$win_known_hosts")"

    local win_needs_scan=false
    for host in $hosts; do
      if ! grep -q "^$host " "$win_known_hosts" 2>/dev/null; then
        win_needs_scan=true
        break
      fi
    done

    if $win_needs_scan; then
      echo "Adding SSH host keys to Windows known_hosts..."
      ssh-keyscan $hosts >> "$win_known_hosts" 2>/dev/null
    fi
  fi
}

bootstrap_known_hosts

# ─── Create .stowrc on first run ───────────────────────────────────
if [ ! -f "$STOWRC" ]; then
  cat > "$STOWRC" << EOF
--dir=$DOTFILES_DIR
--target=$HOME
EOF
  echo "Created ~/.stowrc"
fi

# ─── Back up conflicting files and stow packages ───────────────────
# Directories that are not stow packages (docs, examples, etc.)
NO_STOW="examples"

for dir in "$DOTFILES_DIR"/*/; do
  pkg="$(basename "$dir")"
  # Skip non-stow directories
  echo "$NO_STOW" | grep -qw "$pkg" && continue

  # Move aside any real files that would conflict with symlinks
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

  echo "Stowing $pkg..."
  stow -R -v -d "$DOTFILES_DIR" -t "$HOME" "$pkg" 2> >(grep -v "BUG in find_stowed_path" >&2)
done

if [ -d "$BACKUP_DIR" ]; then
  echo "Originals saved to ~/.dotfiles_backup/"
fi

# ─── Install global mise tools ──────────────────────────────────────
# mise config is now stowed — install everything declared in config.toml
_mise_bin="$(command -v mise 2>/dev/null || echo "$HOME/.local/bin/mise")"
if [ -x "$_mise_bin" ]; then
  echo "Installing global mise tools..."
  "$_mise_bin" install --yes 2>/dev/null || true
fi
unset _mise_bin

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

  if [ "$PLATFORM" = "linux" ] && command -v fc-cache &>/dev/null; then
    fc-cache -f "$font_dir"
  fi

  # Auto-register fonts on WSL (per-user, no admin needed)
  if [ "$PLATFORM" = "wsl" ]; then
    local win_font_dir
    win_font_dir="$(wslpath -w "$font_dir")"
    powershell.exe -NoProfile -Command "
      \$regPath = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
      if (-not (Test-Path \$regPath)) { New-Item -Path \$regPath -Force | Out-Null }
      Get-ChildItem '${win_font_dir}' -Filter '*.ttf' | ForEach-Object {
        Set-ItemProperty -Path \$regPath -Name (\$_.BaseName + ' (TrueType)') -Value \$_.FullName
      }
    " 2>/dev/null && echo "Fonts registered in Windows." || true
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
  if [ "$PLATFORM" = "wsl" ]; then
    echo "Nerd Font was registered but may need a terminal restart to take effect."
    echo "Set your terminal font to 'JetBrainsMono Nerd Font Mono'."
    echo "If icons still don't render, install the fonts manually:"
  else
    echo "JetBrainsMono Nerd Font Mono is downloaded but not registered."
    echo "Install it for Neovim icons to render correctly:"
  fi
  echo "  Search for: JetBrainsMonoNerdFontMono-"
  echo "  Select all matches, right-click, and install them."
  echo "  Then set your terminal font to 'JetBrainsMono Nerd Font Mono'."
  local yn=""
  if [ -t 0 ]; then
    read -rp "Open the font directory now? [y/N] " yn
  fi
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

# ─── Set zsh as default shell ───────────────────────────────────────
if command -v zsh &>/dev/null && [ "$(basename "$SHELL")" != "zsh" ]; then
  echo "Setting zsh as default shell..."
  sudo chsh -s "$(which zsh)" "$USER"
fi

echo ""
echo "Done. Restart your shell to pick up changes."
