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
  for cmd in stow curl unzip zsh notify-send; do
    command -v "$cmd" &>/dev/null || { needs_install=true; break; }
  done

  if $needs_install; then
    echo "Installing base packages..."
    if command -v apt-get &>/dev/null; then
      sudo apt-get update -qq
      pkg_install stow curl unzip zsh libnotify-bin
    else
      pkg_install stow curl unzip zsh
    fi
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
        # Single-quoted trap so $tmp expands when the trap fires (at
        # function return), not now. shellcheck SC2064.
        trap 'rm -rf "$tmp"' RETURN
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
        trap 'rm -rf "$tmp"' RETURN
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

# ─── Install shellcheck ─────────────────────────────────────────────
# Required by the .githooks/pre-commit hook to lint shell scripts on
# commit. Hook degrades to a warning if shellcheck isn't installed, but
# we install it here so the hook is actually useful out of the box.
install_shellcheck() {
  command -v shellcheck &>/dev/null && return
  echo "Installing shellcheck..."
  case "$PLATFORM" in
    macos) brew install shellcheck ;;
    wsl|linux) pkg_install shellcheck ;;
  esac
}

install_shellcheck

# ─── Install wslu (WSL only) ────────────────────────────────────────
# Provides `wslview`, which opens URLs in the Windows default browser
# from inside WSL. packages/shell/.commonrc sets BROWSER=wslview on WSL, but
# without the package it silently falls back to a Linux-side browser
# (e.g. `aws sso login` launching a profile-less Linux Chrome).
install_wslu() {
  [ "$PLATFORM" = "wsl" ] || return 0
  command -v wslview &>/dev/null && return 0
  echo "Installing wslu..."
  pkg_install wslu
}

install_wslu

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

# ─── Install zsh-autosuggestions ────────────────────────────────────
# Fish-style grey ghost-text suggestions while typing. Shipped as a
# sourceable script (not a binary), so we check the known install paths
# instead of `command -v`.
install_zsh_autosuggestions() {
  for f in /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
           /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
           /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
    [ -r "$f" ] && return
  done
  echo "Installing zsh-autosuggestions..."
  case "$PLATFORM" in
    macos) brew install zsh-autosuggestions ;;
    wsl|linux) pkg_install zsh-autosuggestions ;;
  esac
}

install_zsh_autosuggestions

# ─── SSH directory setup ────────────────────────────────────────────
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# ─── SSH known hosts bootstrap ────────────────────────────────────
bootstrap_known_hosts() {
  # Array form so we can quote-expand cleanly. shellcheck SC2086.
  local hosts=(github.com gitlab.com)

  local needs_scan=false
  for host in "${hosts[@]}"; do
    if ! grep -q "^$host " "$HOME/.ssh/known_hosts" 2>/dev/null; then
      needs_scan=true
      break
    fi
  done

  if $needs_scan; then
    echo "Adding SSH host keys to ~/.ssh/known_hosts..."
    ssh-keyscan "${hosts[@]}" >> "$HOME/.ssh/known_hosts" 2>/dev/null
  fi

  if [ "$PLATFORM" = "wsl" ]; then
    local win_user
    win_user="$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')"
    local win_known_hosts="/mnt/c/Users/$win_user/.ssh/known_hosts"
    mkdir -p "$(dirname "$win_known_hosts")"

    local win_needs_scan=false
    for host in "${hosts[@]}"; do
      if ! grep -q "^$host " "$win_known_hosts" 2>/dev/null; then
        win_needs_scan=true
        break
      fi
    done

    if $win_needs_scan; then
      echo "Adding SSH host keys to Windows known_hosts..."
      ssh-keyscan "${hosts[@]}" >> "$win_known_hosts" 2>/dev/null
    fi
  fi
}

bootstrap_known_hosts

# ─── Mirror SSH config to Windows side (WSL only) ─────────────────
# On WSL, GIT_SSH_COMMAND=ssh.exe in .commonrc routes git through
# Windows' OpenSSH. ssh.exe reads %USERPROFILE%\.ssh\config — it does
# NOT read the Linux-side file that stow links into ~/.ssh/config. So
# we copy our dotfiles ssh config into the Windows user profile too.
#
# The copy is filtered: `Match exec "uname..."` blocks are stripped.
# They select Linux/macOS 1Password agent sockets that don't exist on
# Windows (Windows uses the named-pipe agent service), and ssh.exe
# evaluates `Match exec` by spawning CMD.EXE — producing UNC-path and
# missing-`uname` warnings on every git operation. Stripping them
# eliminates the noise without changing the auth path.
#
# Copy (not symlink) because NTFS symlinks created from WSL aren't
# reliably followed by Windows apps like ssh.exe. Re-running install.sh
# re-copies, keeping the two sides in sync; the dotfiles file remains
# the source of truth.
#
# First run on a given machine backs up any pre-existing Windows ssh
# config to $BACKUP_DIR so nothing is silently lost.
mirror_ssh_to_windows() {
  [ "$PLATFORM" = "wsl" ] || return 0

  local src="$DOTFILES_DIR/packages/ssh/.ssh/config"
  [ -f "$src" ] || return 0

  local win_user
  win_user="$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')"
  if [ -z "$win_user" ]; then
    echo "Could not resolve Windows username; skipping SSH mirror to Windows."
    return 0
  fi

  local dest="/mnt/c/Users/$win_user/.ssh/config"
  mkdir -p "$(dirname "$dest")"

  local filtered
  filtered="$(mktemp)"
  awk '
    /^Match exec "uname/ { skipping = 1; next }
    skipping {
      if (/^[[:space:]]+[^[:space:]]/) next
      skipping = 0
    }
    { print }
  ' "$src" > "$filtered"

  if [ -f "$dest" ] && ! cmp -s "$filtered" "$dest"; then
    local backup
    backup="$BACKUP_DIR/windows-ssh-config.$(date +%Y%m%dT%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp "$dest" "$backup"
    echo "  Backed up existing Windows SSH config: $dest -> $backup"
  fi

  cp -f "$filtered" "$dest"
  rm -f "$filtered"
  echo "SSH config mirrored to $dest"
}

mirror_ssh_to_windows

# ─── Ensure ~/.stowrc points at the current packages dir ───────────
# Every stow package lives under packages/. ~/.stowrc pins stow's
# --dir so `stow <pkg>` from any cwd finds the right tree. On fresh
# machines we write it; on machines bootstrapped before the packages/
# restructure we back up the stale file and rewrite — same backup
# pattern as mirror_ssh_to_windows so nothing is silently lost.
ensure_stowrc() {
  local stow_dir="$DOTFILES_DIR/packages"
  local expected
  expected="$(printf -- '--dir=%s\n--target=%s\n' "$stow_dir" "$HOME")"

  if [ -f "$STOWRC" ] && [ "$(cat "$STOWRC")" = "$expected" ]; then
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

# ─── Back up conflicting files and stow packages ───────────────────
# Every directory under packages/ is a stow package by convention.
# Non-package repo content (docs, examples, cursor, mcp-servers) lives
# at the repo root and is invisible to this loop.
for dir in "$DOTFILES_DIR"/packages/*/; do
  pkg="$(basename "$dir")"

  # Move aside any real files that would conflict with symlinks.
  # The -ef test skips files whose target resolves (through an
  # already-stowed parent directory symlink — stow tree folding) to
  # the source file itself; without it, a re-run would mv our source
  # files out of the repo and into $BACKUP_DIR.
  while IFS= read -r -d '' file; do
    rel="${file#"$dir"}"
    target="$HOME/$rel"
    if [ -f "$target" ] && [ ! -L "$target" ] && ! [ "$target" -ef "$file" ]; then
      backup_path="$BACKUP_DIR/$rel"
      mkdir -p "$(dirname "$backup_path")"
      mv "$target" "$backup_path"
      echo "  Backed up: ~/$rel -> ~/.dotfiles_backup/$rel"
    fi
  done < <(find "$dir" -type f -print0)

  echo "Stowing $pkg..."
  stow -R -v -d "$DOTFILES_DIR/packages" -t "$HOME" "$pkg" 2> >(grep -v "BUG in find_stowed_path" >&2)
done

if [ -d "$BACKUP_DIR" ]; then
  echo "Originals saved to ~/.dotfiles_backup/"
fi

# ─── Configure git hooks for the dotfiles repo ──────────────────────
# Tracked hooks live in .githooks/ but git won't run them until we
# point core.hooksPath at that directory. core.hooksPath is per-repo
# (lives in .git/config, not tracked) so a fresh clone needs this.
setup_git_hooks() {
  local hooks_dir="$DOTFILES_DIR/.githooks"
  [ -d "$hooks_dir" ] || return 0

  # Make all hooks executable. write_file from MCP doesn't preserve the
  # executable bit, so this is the safety net.
  find "$hooks_dir" -maxdepth 1 -type f ! -name 'README*' -exec chmod +x {} +

  # Configure the dotfiles repo to use the tracked hooks dir.
  if git -C "$DOTFILES_DIR" rev-parse --git-dir &>/dev/null; then
    local current
    current="$(git -C "$DOTFILES_DIR" config --get core.hooksPath || true)"
    if [ "$current" != ".githooks" ]; then
      git -C "$DOTFILES_DIR" config core.hooksPath .githooks
      echo "Git hooks: configured dotfiles repo to use .githooks/"
    fi
  fi
}

setup_git_hooks

# ─── Install global mise tools ──────────────────────────────────────
# mise config is now stowed — install everything declared in config.toml
_mise_bin="$(command -v mise 2>/dev/null || echo "$HOME/.local/bin/mise")"
if [ -x "$_mise_bin" ]; then
  echo "Installing global mise tools..."
  "$_mise_bin" install --yes 2>/dev/null || true
fi
unset _mise_bin

# ─── Register Claude Code MCP servers ───────────────────────────────
# Sync mcp-servers/manifest.json into ~/.claude.json's user-scope
# mcpServers. See mcp-servers/README.md for the design. Gated on the
# claude CLI being present — mise installs it above, but bail cleanly
# if it's somehow missing so install.sh still completes.
register_mcp_servers() {
  local register="$DOTFILES_DIR/mcp-servers/register.sh"
  [ -x "$register" ] || return 0
  if ! command -v claude >/dev/null 2>&1; then
    echo "Skipping MCP registration — claude CLI not on PATH."
    return 0
  fi
  for dep in jq envsubst; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      echo "Skipping MCP registration — missing $dep."
      return 0
    fi
  done
  echo "Registering MCP servers from manifest..."
  "$register" || echo "MCP registration exited non-zero; continuing."
}

register_mcp_servers

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

  local files_present=false
  if ls "$font_dir"/JetBrainsMonoNerd* &>/dev/null; then
    files_present=true
  fi

  # Download + install only if the .ttfs aren't already on disk.
  # Registration (below) runs unconditionally on WSL so a stale state
  # — files present but not in HKCU — self-heals on the next run.
  if ! $files_present; then
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
    trap 'rm -rf "$tmp_dir"' RETURN

    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" \
      -o "$tmp_dir/font.zip"
    unzip -qo "$tmp_dir/font.zip" "*.ttf" -d "$tmp_dir/font"

    mkdir -p "$font_dir"
    cp "$tmp_dir"/font/*.ttf "$font_dir/"

    if [ "$PLATFORM" = "linux" ] && command -v fc-cache &>/dev/null; then
      fc-cache -f "$font_dir"
    fi

    echo "Nerd Font installed to $font_dir"
  else
    echo "Nerd Font already installed."
  fi

  # Auto-register fonts on WSL (per-user, no admin needed). Idempotent
  # via Set-ItemProperty, so it runs every time install.sh executes —
  # this is what self-heals the "files on disk but not in HKCU" case
  # left behind by older versions of this script that early-returned
  # before reaching the registration block.
  if [ "$PLATFORM" = "wsl" ]; then
    local win_font_dir registered=true
    win_font_dir="$(wslpath -w "$font_dir")"
    powershell.exe -NoProfile -Command "
      \$regPath = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
      if (-not (Test-Path \$regPath)) { New-Item -Path \$regPath -Force | Out-Null }
      Get-ChildItem '${win_font_dir}' -Filter '*.ttf' | ForEach-Object {
        Set-ItemProperty -Path \$regPath -Name (\$_.BaseName + ' (TrueType)') -Value \$_.FullName
      }
    " 2>/dev/null || registered=false
    if $registered && ! $files_present; then
      echo "Fonts registered in Windows."
    fi
  fi
}

install_nerd_font

# ─── Nerd Font registration check ──────────────────────────────────
# On macOS, fonts dropped into ~/Library/Fonts are auto-registered for the
# user. system_profiler is unreliable right after install (caches lag), so
# we check the filesystem first and only fall back to system_profiler.
check_font_registered() {
  # All branches capture output and pattern-match in bash rather than
  # piping into `grep -q`. With `set -o pipefail`, `grep -q` exits on
  # first match and closes its stdin; the upstream (`tr`, `fc-list`,
  # `system_profiler`) then dies with SIGPIPE (exit 141), which
  # pipefail propagates as the pipeline's status — falsely flipping
  # the result to "not found" even on a successful match. Capturing
  # into a variable removes the pipe-close race entirely.
  #
  # The pattern is `JetBrainsMono NFM` (the short-form family name
  # shipped by current Nerd Fonts releases). The long form
  # (`Nerd Font Mono`) was retired to fit Windows' font-name length
  # cap and is no longer present in the .ttf metadata that any of
  # these tools surface.
  case "$PLATFORM" in
    wsl)
      # Query the user-scope font registry directly — same path
      # install_nerd_font writes to. The previous .NET-based check
      # (`InstalledFontCollection`) silently failed because
      # System.Drawing isn't loaded by default in modern PowerShell;
      # `2>/dev/null` masked the assembly-not-loaded error and the
      # branch always returned non-zero.
      local registry_props=""
      registry_props="$(powershell.exe -NoProfile -Command \
        "(Get-Item 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts').Property" \
        2>/dev/null | tr -d '\r')" || true
      [[ "$registry_props" == *"JetBrainsMono NFM"* ]]
      ;;
    macos)
      # Filesystem check is authoritative on macOS — if the .ttf is in
      # ~/Library/Fonts it IS registered for the user.
      if ls "$HOME/Library/Fonts"/JetBrainsMonoNerdFontMono-* &>/dev/null; then
        return 0
      fi
      local font_list=""
      font_list="$(system_profiler SPFontsDataType 2>/dev/null)" || true
      [[ "$font_list" == *"JetBrainsMono NFM"* ]]
      ;;
    *)
      local fc_output=""
      fc_output="$(fc-list 2>/dev/null)" || true
      [[ "$fc_output" == *"JetBrainsMono NFM"* ]]
      ;;
  esac
}

if ! check_font_registered; then
  echo ""
  if [ "$PLATFORM" = "wsl" ]; then
    echo "JetBrainsMono NFM does not appear to be registered with Windows."
    echo "Install it for terminal/Neovim icons to render correctly:"
  else
    echo "JetBrainsMono NFM is downloaded but not registered."
    echo "Install it for Neovim icons to render correctly:"
  fi
  echo "  Search for: JetBrainsMonoNerdFontMono-"
  echo "  Select all matches, right-click, and install them."
  echo "  Then set your terminal font to 'JetBrainsMono NFM'."
  yn=""
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
