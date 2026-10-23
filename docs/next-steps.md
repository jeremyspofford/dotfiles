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

Run `./bootstrap.sh` from the checkout (see README "New machine"). On Linux and
WSL it installs mise but leaves zsh, tmux, and the zsh plugins to the system
package manager, and the smoke tests still assume Apple Silicon macOS paths.
