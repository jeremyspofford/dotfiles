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

## 2. Update the local CLAUDE.md files on each machine

`~/CLAUDE.md` and `~/.claude/CLAUDE.md` still describe the retired Stow setup
(Stow packages, `.commonrc`, `.aliases`, `.secrets`). They are personal and stay
local and unmanaged; do not add them to this repository. Rewrite the dotfiles and
shell sections to describe Workbench: plan/apply/rollback, `workbench doctor`,
component list from `COMPONENTS` in `bin/workbench`, and the shell chain
`.zshrc` → `~/.config/workbench/shell/common.sh` → `env.sh`.

## 3. Optional cleanup

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
