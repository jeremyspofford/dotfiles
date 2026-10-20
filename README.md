# Workbench dotfiles

A small, chezmoi-based setup for daily work on this Mac: zsh/Bash, Git identities,
mise tools, Neovim, tmux, and Herdr. `chezmoi/` is the configuration source.

## Daily use

```sh
workbench doctor
workbench plan --existing replace
workbench apply --existing replace --plan <reviewed-hash>
workbench checkpoints
```

`workbench doctor` checks core tool availability, confirms every
`manifests/Brewfile.core` entry is installed, and compares every managed file
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

## What's here

| Path | Purpose |
| --- | --- |
| `chezmoi/` | The active configuration, including explicit Git identities |
| `bin/workbench` | File preview, checkpoint, apply, rollback, and doctor |
| `manifests/Brewfile.core` | Core Homebrew package list |
| `tests/` | Transaction, shell/editor, and isolated Herdr checks |
| `docs/` | Shortcuts, Herdr usage, and recovery |

Homebrew owns OS-level tools; `chezmoi/dot_config/mise/config.toml` pins development
tools. Package installation is separate from configuration changes.

Personal Git identity is the default, including Alert Venture. Client overrides
are explicit in `chezmoi/.chezmoidata.toml`. SSH configuration and credentials stay
local and are not managed by this repository.

The legacy Stow packages, AI workflows, old installers, and machine migration
records have been archived outside this checkout. The active shell does not source
legacy aliases, secrets, or local override files. Multi-machine bootstrap and
optional tool profiles are deferred until this Mac's daily workflow is settled.

## Guides and checks

- [Shell, tmux, and Neovim shortcuts](docs/workbench-shortcuts.md)
- [Using Herdr](docs/herdr.md)
- [Checkpoints and legacy recovery](docs/recovery.md)

```sh
python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 tests/baseline_smoke.py
python3 tests/baseline_smoke.py --live
python3 tests/herdr_smoke.py ~/workspace/alertventure/ft-quoting
chezmoi verify
```

Smoke scripts currently target this Apple Silicon Mac and its installed tools.
Herdr's smoke check uses a separate server and read-only repository commands.
