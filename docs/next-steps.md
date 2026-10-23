# Next steps

Open work, in priority order. Remove items as they land.

## 1. Decide on Git history before sharing

Tracked files no longer contain personal or client data: Git identity moved to
the machine-local `~/.config/git/local.gitconfig` (see
`docs/examples/local.gitconfig`). Earlier commits still contain names, emails,
and client directory names. Before making the repository public, publish a fresh
repository with a single initial commit and keep this one private as the archive.
Sharing privately needs no history change. Git history was scanned with gitleaks
(230 commits, no credentials).

## 2. Replace 1Password SSH with per-device keys and simplify Git identity

Goal: one SSH key per device, no 1Password agent dependency, and no Host-alias
`insteadOf` rewrites.

- Generate an ed25519 key per device and per account that needs its own key
  (a forge rejects the same public key on two accounts). Protect it with a
  passphrase stored in the OS keychain (`AddKeysToAgent yes`, `UseKeychain yes`
  on macOS), so the key on disk is never usable alone. Revoke per device if lost.
- In each identity file, replace the `[url "git@host-alias:"] insteadOf` rule
  with `core.sshCommand = ssh -i ~/.ssh/<key> -o IdentitiesOnly=yes`. Remotes
  stay plain `git@github.com:` URLs and `~/.ssh/config` loses its alias hosts.
- Remove the 1Password `Include` and `IdentityAgent` blocks from `~/.ssh/config`
  once every account has a device key.

## 3. Finish moving CLI tools to mise

Neovim, Herdr, chezmoi, delta, and shellcheck now come from mise. Remaining:

- `brew uninstall herdr` after the next Herdr server restart; the running server
  was started from the Homebrew binary.
- Optional components and `workbench apply --interactive` exist; see README
  "Optional tools".
- Move `tmux` once mise's prebuilt build (`aqua:tmux/tmux-builds`) reaches the
  Homebrew version (3.8 vs 3.7c).

## 4. Update the local CLAUDE.md files on other machines

Done on the primary Mac. On each other machine, `~/CLAUDE.md` and
`~/.claude/CLAUDE.md` still describe the retired Stow setup. They are personal and
stay local and unmanaged; do not add them to this repository. Describe Workbench
(plan/apply/rollback, `apply --interactive`, `doctor`), the components in
`bin/workbench`, mise as the tool manager, and the machine-local
`~/.config/git/local.gitconfig`.

## Bringing up another machine

Run `./bootstrap.sh` from the checkout (see README "New machine"). Linux and WSL
have not been run yet; expect to fix things on the first run.

### First run on WSL (Ubuntu)

1. Inside WSL, keep the checkout on the Linux filesystem
   (`~/workspace/dotfiles`), not under `/mnt/c`; file modes and performance
   depend on it.
2. Install the bootstrap layer with apt first:
   `sudo apt install git zsh tmux zsh-autosuggestions zsh-syntax-highlighting python3 curl`.
   `bootstrap.sh` offers the official mise installer (`curl https://mise.run | sh`)
   and installs mise into `~/.local/bin`.
3. Run `./bootstrap.sh`, review the plan, then open a new shell and run
   `workbench doctor`. Make zsh the login shell with `chsh -s "$(command -v zsh)"`.

Likely problem spots, all macOS-shaped today:

- `chezmoi/dot_config/private_workbench/private_shell/env.sh` lists Homebrew
  paths and the macOS ChatGPT app's Codex path. They are skipped when missing,
  but nothing Linux-specific is added.
- `chezmoi/dot_zshrc` looks for zsh plugins under `/opt/homebrew/share`,
  `/usr/local/share`, and `/usr/share`. Ubuntu installs them under
  `/usr/share/zsh-autosuggestions/` and `/usr/share/zsh-syntax-highlighting/`,
  which should match; verify.
- `tests/baseline_smoke.py` expects macOS paths (the Codex app path, `/bin/zsh`,
  pinned Node/Python output). Make it platform-aware before trusting `--live`.
- `bin/workbench` doctor runs `brew bundle check` only when Homebrew exists; on
  Linux it reports "unable to check" and does not fail. Decide whether Linux
  needs an apt package check.
- SSH on WSL: the old setup routed Git through Windows `ssh.exe` for the
  1Password agent. With per-device keys (item 2), generate a key inside WSL
  instead and skip that bridge.
- Herdr and zoetrope publish Linux builds; choose them with
  `workbench apply --interactive` after the core works.

A Docker Ubuntu container (`docker run -it ubuntu:24.04`) reproduces most of this
without touching a real machine.
