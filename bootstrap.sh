#!/bin/sh
# Bring this machine to the Workbench baseline. Safe to re-run: every config
# change goes through a reviewed Workbench plan with a checkpoint, and nothing
# is downloaded or installed without asking first (or --yes).
set -eu

REPO=$(cd "$(dirname "$0")" && pwd -P)
MISE_CONFIG="$REPO/chezmoi/dot_config/mise/config.toml"
LOCAL_GITCONFIG="$HOME/.config/git/local.gitconfig"
YES=0
NAME=
EMAIL=
EXISTING=

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [--yes] [--name NAME] [--email EMAIL] [--existing skip|replace]

  --yes        Accept every prompt (installs packages, applies the plan).
  --name       Git user.name for ~/.config/git/local.gitconfig (first run only).
  --email      Git user.email for ~/.config/git/local.gitconfig (first run only).
  --existing   How to treat config files that already exist. Default: ask;
               with --yes, replace (originals are checkpointed).
EOF
}

while [ $# -gt 0 ]; do
  case $1 in
    --yes) YES=1 ;;
    --name) NAME=${2:?--name needs a value}; shift ;;
    --email) EMAIL=${2:?--email needs a value}; shift ;;
    --existing) EXISTING=${2:?--existing needs skip or replace}; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done
case $EXISTING in ''|skip|replace) ;; *) usage >&2; exit 2 ;; esac

step() { printf '\n==> %s\n' "$*"; }
die() { printf 'bootstrap: %s\n' "$*" >&2; exit 1; }
confirm() {
  [ "$YES" = 1 ] && return 0
  printf '%s [y/N] ' "$1"
  read -r answer || return 1
  case $answer in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}
ask() {
  printf '%s' "$1" >&2
  read -r value || value=
  printf '%s' "$value"
}

step "Checking prerequisites"
command -v python3 >/dev/null 2>&1 || die "python3 3.9+ is required"
python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))' || die "python3 3.9+ is required"
command -v git >/dev/null 2>&1 || die "git is required"
echo "python3 and git found."

step "Bootstrap packages"
case $(uname -s) in
  Darwin)
    command -v brew >/dev/null 2>&1 || die "Homebrew is required on macOS; install it from https://brew.sh, then re-run"
    if brew bundle check --no-upgrade --file "$REPO/manifests/Brewfile.core" >/dev/null 2>&1; then
      echo "All Brewfile.core packages are installed."
    elif confirm "Install missing packages from manifests/Brewfile.core with Homebrew?"; then
      brew bundle install --no-upgrade --file "$REPO/manifests/Brewfile.core"
    else
      die "the bootstrap packages are required"
    fi
    ;;
  *)
    if ! command -v mise >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/mise" ]; then
      if confirm "mise is not installed. Run the official installer (curl https://mise.run | sh)?"; then
        curl -fsSL https://mise.run | sh
      else
        die "mise is required"
      fi
    fi
    for tool in zsh tmux; do
      command -v "$tool" >/dev/null 2>&1 || echo "Install $tool with your package manager (also zsh-autosuggestions, zsh-syntax-highlighting)."
    done
    ;;
esac
PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
export PATH
command -v mise >/dev/null 2>&1 || die "mise is still not on PATH"

step "chezmoi for Workbench"
CHEZMOI=$(sed -n 's/^chezmoi = "\(.*\)"$/\1/p' "$MISE_CONFIG")
[ -n "$CHEZMOI" ] || die "no chezmoi pin in $MISE_CONFIG"
mise install "chezmoi@$CHEZMOI"
workbench() {
  (cd "$REPO" && mise exec "chezmoi@$CHEZMOI" -- python3 "$REPO/bin/workbench" "$@")
}

step "Git identity"
if [ -f "$LOCAL_GITCONFIG" ]; then
  echo "Keeping existing $LOCAL_GITCONFIG."
else
  # Carry over an identity from an older ~/.gitconfig before Workbench replaces it.
  [ -n "$NAME" ] || NAME=$(git config --global user.name 2>/dev/null || true)
  [ -n "$EMAIL" ] || EMAIL=$(git config --global user.email 2>/dev/null || true)
  if [ "$YES" = 0 ]; then
    entered=$(ask "Git name [${NAME}]: "); [ -n "$entered" ] && NAME=$entered
    entered=$(ask "Git email [${EMAIL}]: "); [ -n "$entered" ] && EMAIL=$entered
  fi
  [ -n "$NAME" ] && [ -n "$EMAIL" ] || die "a Git name and email are required (--name/--email)"
  mkdir -p "$(dirname "$LOCAL_GITCONFIG")"
  (umask 077 && cat > "$LOCAL_GITCONFIG" <<EOF
# Machine-local Git identity. Not managed by Workbench; never commit this file.
# Per-directory identities: see docs/examples/local.gitconfig in the dotfiles repo.
[user]
    name = "$NAME"
    email = "$EMAIL"
EOF
  )
  echo "Wrote $LOCAL_GITCONFIG."
fi

step "Configuration"
if [ -z "$EXISTING" ]; then
  EXISTING=skip
  if [ "$YES" = 1 ] || confirm "Replace config files that already exist? Originals are checkpointed and restorable."; then
    EXISTING=replace
  fi
fi
PLAN=$(workbench --color never plan --existing "$EXISTING")
printf '%s\n' "$PLAN"
HASH=$(printf '%s\n' "$PLAN" | sed -n 's/^Plan: //p')
if printf '%s\n' "$PLAN" | grep -qE '^(CREATE|REPLACE|REMOVE) '; then
  confirm "Apply this plan?" || die "stopped before applying; nothing changed"
  workbench --color never apply --existing "$EXISTING" --plan "$HASH"
else
  echo "Configuration already matches."
fi

step "mise tools"
(cd "$HOME" && mise install)

step "Doctor"
if workbench doctor; then
  status=0
else
  status=1
  echo "Doctor found the issues listed above."
fi
cat <<EOF

Next:
  - Open a new terminal so the shell configuration loads.
  - Choose optional tools: workbench apply --interactive
  - Per-directory Git identities: edit $LOCAL_GITCONFIG
EOF
exit "$status"
