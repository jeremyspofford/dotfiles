# Workbench dotfiles

A small, chezmoi-based setup for daily work on this Mac: zsh/Bash, Git,
mise tools, Neovim, and tmux, plus optional tools you choose. `chezmoi/` is the
configuration source.

## New machine

```sh
git clone <this repository> ~/workspace/dotfiles
~/workspace/dotfiles/bootstrap.sh
```

The script checks for Python 3.9+ and Git and installs the Homebrew bootstrap
packages (macOS) or mise (Linux), each only after asking. It installs the pinned
chezmoi, writes `~/.config/git/local.gitconfig` (carrying over the name and email
from an existing `~/.gitconfig`), shows the Workbench plan and applies it with a
checkpoint once you confirm, runs `mise install`, and finishes with
`workbench doctor`. Existing config files are replaced only if you agree, and
their originals stay in the checkpoint. It is safe to re-run. `--yes` accepts
every prompt; `--name`, `--email`, and `--existing skip|replace` answer
individual ones. Optional tools come afterwards with
`workbench apply --interactive`.

## Daily use

```sh
workbench doctor
workbench plan --existing replace
workbench apply --existing replace --plan <reviewed-hash>
workbench checkpoints
```

`workbench doctor` checks core tool availability, confirms every
`manifests/Brewfile.core` entry and every pinned mise tool is installed, checks
the local Git identity, and compares every managed file
with the rendered source, including permissions and symlinks. It lists `MISSING`
packages and `MISSING` or `DRIFT` paths without printing file contents or
changing installed files. Newer upstream package versions are not reported.
It exits 0 when tools and packages are present and configuration matches, or 1
when a tool or package is missing, configuration differs, or the check cannot
complete. Review drift
with `workbench plan --existing replace` before deciding what to preserve or apply.

Open a new terminal after shell changes. Use `./bin/workbench` from this checkout
before installation or during recovery. It requires Python 3.9+ and chezmoi.

Every replacement gets a checkpoint. Apply requires the exact reviewed plan hash
and refuses stale plans. Existing files are skipped unless `--existing replace`
is specified. The wrapper changes only its explicitly listed configuration files;
it never moves, cleans, or resets client repositories.

```sh
workbench --color always plan --existing replace | less -R
workbench plan --existing replace --format html > /tmp/workbench-review.html
workbench rollback <checkpoint-id>
workbench rollback <checkpoint-id> --plan <reviewed-rollback-hash>
```

`chezmoi diff`, `chezmoi status`, and `chezmoi verify` inspect the installed state.
Use Workbench for apply/rollback so changes retain checkpoints.

## Optional tools

Core components always apply. Optional components add one tool each, pinned in
its own `~/.config/mise/conf.d/<component>.toml`:

| Component | Adds |
| --- | --- |
| `herdr` | Herdr terminal workspace and its config |
| `zoetrope` | `zoe`, a live flow graph of a Claude Code session |

The quickest way to add, remove, or update tools is the checklist:

```sh
workbench apply --interactive
```

It lists core tools (always installed) and optional components, with each pinned
version and any newer release from `mise outdated`. Space chooses a component or
marks a tool for update; Enter shows the exact diff; `y` applies it with a
checkpoint and then runs `mise install` (or `mise uninstall` for removed tools).
Updates change the pin in this repository so every machine converges; commit them
afterwards. Homebrew status is shown read-only. Cancelling at any point leaves the
repository and home directory unchanged.

The same choices work without the checklist:

```sh
workbench plan --components herdr
workbench apply --components herdr --plan <reviewed-hash>
mise install
```

A component counts as chosen once any of its files exists. After that, a plain
`workbench plan` and `workbench doctor` include it; unchosen ones are ignored.
To drop one, uncheck it in `workbench apply --interactive` (rollback restores its
files), or delete its files and run `mise prune`. Editor and shell plugins are
not managed; add them per machine as needed.

## What's here

| Path | Purpose |
| --- | --- |
| `chezmoi/` | The active configuration (no personal data) |
| `bin/workbench` | File preview, checkpoint, apply, rollback, and doctor |
| `manifests/Brewfile.core` | Bootstrap Homebrew packages |
| `tests/` | Transaction, shell/editor, and isolated Herdr checks |
| `docs/` | Shortcuts, Herdr usage, and recovery |

`chezmoi/dot_config/mise/config.toml` pins CLI and development tools, including
Neovim, Herdr, chezmoi, and delta. Homebrew holds only the bootstrap layer (mise,
Git, tmux, zsh plugins). Package installation is separate from configuration changes.

Git identity is machine-local. The shared `.gitconfig` ends by including
`~/.config/git/local.gitconfig`, which holds your name, email, and any
per-directory `includeIf` identities. Start from
[`docs/examples/local.gitconfig`](docs/examples/local.gitconfig); `workbench doctor`
fails until it exists and sets `user.email`. That file, SSH configuration, and
credentials stay local and are never committed.

The legacy Stow packages, AI workflows, old installers, and machine migration
records have been archived outside this checkout. The active shell does not source
legacy aliases, secrets, or local override files. Multi-machine bootstrap and
optional tool profiles are deferred until this Mac's daily workflow is settled.

## Guides and checks

- [Shell, tmux, and Neovim shortcuts](docs/workbench-shortcuts.md)
- [Using Herdr](docs/herdr.md)
- [Checkpoints and legacy recovery](docs/recovery.md)
- [Next steps and open work](docs/next-steps.md)

```sh
python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 tests/baseline_smoke.py
python3 tests/baseline_smoke.py --live
python3 tests/herdr_smoke.py ~/workspace/<project>
chezmoi verify
```

Smoke scripts currently target this Apple Silicon Mac and its installed tools.
Herdr's smoke check uses a separate server and read-only repository commands.
