# Next steps

Open work, in priority order. Remove items as they land.

## 1. Generalize the repository for sharing

The repository should hold only reusable configuration. Personal and client
values currently appear in tracked files:

- `chezmoi/.chezmoidata.toml`: name, default email, per-client identities.
- `chezmoi/dot_gitconfig.tmpl` and `chezmoi/dot_config/git/private_identities/`:
  client directory `includeIf` rules and identity files.
- `docs/herdr.md`, `README.md`: client project names and paths in examples.
- `tests/baseline_smoke.py`: asserts specific identities.
- `bin/workbench`, `chezmoi/dot_config/private_workbench/private_shell/env.sh`:
  smaller references.

Planned approach: move personal values into the machine-local chezmoi config
(`~/.config/chezmoi/chezmoi.toml`, `[data]` section, never committed) and have
templates read them, with a list of identities driving the `includeIf` rules.
`render()` in `bin/workbench` passes its own temporary `--config`, so it must
learn to merge local data before templates can use it. Tests should use
placeholder identities. Git history was scanned with gitleaks (230 commits, no
leaks), so this is about content, not credentials.

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
`manifests/Brewfile.core`, then run `./bin/workbench doctor` and
`./bin/workbench plan --existing replace` from this checkout and review before
applying. Existing Stow symlinks are left untouched unless `--existing replace`
is used. Smoke tests currently assume Apple Silicon macOS paths.
