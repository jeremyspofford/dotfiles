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
- Move `tmux` once mise's prebuilt build (`aqua:tmux/tmux-builds`) reaches the
  Homebrew version (3.8 vs 3.7c).
- Bootstrap on a fresh machine: install mise, apply the mise config, then
  `mise install` so chezmoi exists before Workbench runs.

## 4. Update the local CLAUDE.md files on each machine

`~/CLAUDE.md` and `~/.claude/CLAUDE.md` still describe the retired Stow setup
(Stow packages, `.commonrc`, `.aliases`, `.secrets`). They are personal and stay
local and unmanaged; do not add them to this repository. Rewrite the dotfiles and
shell sections to describe Workbench: plan/apply/rollback, `workbench doctor`,
component list from `COMPONENTS` in `bin/workbench`, and the shell chain
`.zshrc` → `~/.config/workbench/shell/common.sh` → `env.sh`.

## 5. Optional cleanup

- Homebrew `curl`, `unzip`, and `zsh` are installed as leaves outside
  `manifests/Brewfile.core` and duplicate system tools.
- `~/.commonrc` and `~/.aliases` are leftovers from Stow; nothing sources them.

## Bringing up another machine

Multi-machine bootstrap is not built yet. Install Homebrew packages from
`manifests/Brewfile.core`, copy `docs/examples/local.gitconfig` to
`~/.config/git/local.gitconfig` (mode 600) and fill in the identity, then run `./bin/workbench doctor` and
`./bin/workbench plan --existing replace` from this checkout and review before
applying. Existing Stow symlinks are left untouched unless `--existing replace`
is used. Smoke tests currently assume Apple Silicon macOS paths.
