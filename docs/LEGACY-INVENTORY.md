# Legacy inventory

Inspected through GitHub on 2026-11-15, before scaffold changes.
Repository: private `jeremyspofford/dotfiles`.
Main snapshot: [`3421071b3ddcbd0dd5ddc728df009af1ba8ca902`](https://github.com/jeremyspofford/dotfiles/tree/3421071b3ddcbd0dd5ddc728df009af1ba8ca902).
All 35 tracked files in this snapshot were read. The tree has no
AGENTS.md and no active Stow package directories.

## Current main

| Area | Observed state | v0.0.1 disposition |
| --- | --- | --- |
| Shell | zsh and Bash entrypoints; shared env/common fragments; native completion, fzf, optional zsh plugins | Salvage neutral zsh history/completion, guarded aliases, PATH handling and fzf settings |
| Git | Fast-forward pulls, pruning, zdiff3, delta, optional gh credentials, local identity include | Salvage baseline and local include; make installed-tool settings conditional |
| Mise | Pinned general CLI tools and runtimes; separate optional component files | Salvage pins in an explicitly optional example profile; minimal core needs only chezmoi/Mise |
| Workbench | Python plan/apply/rollback/doctor plus checkpoints and interactive components | Preserve in history; exclude custom orchestration from Layer 0 |
| Editor/terminal | Neovim and tmux | Preserve in history; outside requested minimal shell/Git scaffold |
| Optional apps | Herdr and zoetrope configuration and docs | Preserve in history; exclude from this version |
| Tests | Python unit and smoke tests for Workbench, bootstrap, shell completion and optional apps | Preserve history; replace active checks with portable scaffold acceptance tests |
| Identity | Machine-local Git include, documented placeholder example | Keep machine-local; no personal values adopted |
| Secrets | Main shell intentionally does not load legacy secrets | Add requested opt-in 1Password template; never copy old credential material |

## Stow evidence and limits

The current tracked main is already a Workbench/chezmoi layout. Its README says
the legacy Stow packages, AI workflows, old installers, and migration records
were archived outside the checkout. `docs/next-steps.md` says older commits contain
names, emails and client directory names, and other machines may still have local
CLAUDE.md instructions describing Stow. These are statements in existing docs;
this run has not independently inspected the external archives or local machines.
Keep the repository private. No history rewrite is proposed.

## WSL working tree — blocked, not clean

No local command can start: the execution sandbox rejects its own read-only
`/home/jeremy/.agents` symlink mapping. File writes also fail. Therefore the WSL
clone location, current branch, index, untracked files, ignored files and local
diffs remain **uninspected**. This inventory must not be interpreted as evidence
of a clean clone. No local checkout, reset, clean, stash or apply has occurred.

Before merge, in the actual WSL clone, capture `git status --short --branch`,
`git diff --stat`, `git diff --cached --stat`, `git ls-files --others --exclude-standard`,
and inspect the corresponding diffs locally for salvage. Do not paste secrets
into this inventory. Record sanitized paths, purposes and dispositions here.
Preserve local changes in a separate branch/patch with private storage.

## Preservation and merge gate

Owner requires `legacy/stow-2026` to tag the existing main before any merge.
The connector supports branches but not creating tags, and local Git execution
is blocked; the tag has **not** been created. Once execution is restored, verify
main has not moved, then create an annotated tag at the reviewed snapshot:

```sh
git fetch origin main
git tag -a legacy/stow-2026 3421071b3ddcbd0dd5ddc728df009af1ba8ca902 -m "Archive pre-v0.0.1 Workbench and Stow history"
git push origin refs/tags/legacy/stow-2026
```

Do not move an existing tag. A restoration is a checkout of this tag in a separate
clone/worktree, followed by the legacy README's instructions; it is not a forced
reset of a working machine. Owner review and explicit merge approval are required,
even after CI passes. The implementation branch is `feat/chezmoi-v0.0.1`.
The earlier empty `feat/dotfiles-v0.0.1` branch still points to main's original
snapshot and contains no implementation.

## Complete tracked-file list

- `.gitignore`
- `README.md`
- `bin/workbench`
- `bootstrap.sh`
- `chezmoi/dot_bash_profile`
- `chezmoi/dot_bashrc`
- `chezmoi/dot_config/git/ignore`
- `chezmoi/dot_config/mise/conf.d/herdr.toml`
- `chezmoi/dot_config/mise/conf.d/zoetrope.toml`
- `chezmoi/dot_config/mise/config.toml`
- `chezmoi/dot_config/nvim/init.lua`
- `chezmoi/dot_config/private_chezmoi/chezmoi.toml.tmpl`
- `chezmoi/dot_config/private_herdr/config.toml`
- `chezmoi/dot_config/private_workbench/private_shell/common.sh`
- `chezmoi/dot_config/private_workbench/private_shell/completion.zsh`
- `chezmoi/dot_config/private_workbench/private_shell/env.sh`
- `chezmoi/dot_gitconfig`
- `chezmoi/dot_profile`
- `chezmoi/dot_tmux.conf`
- `chezmoi/dot_zprofile`
- `chezmoi/dot_zshenv`
- `chezmoi/dot_zshrc`
- `chezmoi/private_dot_local/bin/executable_workbench.tmpl`
- `docs/examples/local.gitconfig`
- `docs/herdr.md`
- `docs/next-steps.md`
- `docs/recovery.md`
- `docs/workbench-shortcuts.md`
- `manifests/Brewfile.core`
- `tests/baseline_smoke.py`
- `tests/herdr_smoke.py`
- `tests/test_bootstrap.py`
- `tests/test_workbench.py`
- `tests/test_workbench_completion.py`
- `tests/test_workbench_interactive.py`
