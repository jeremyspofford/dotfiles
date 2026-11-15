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
| `chezmoi/dot_config/private_chezmoi/chezmoi.toml.tmpl` | Legacy Workbench chezmoi configuration | Superseded by the root `.chezmoi.toml.tmpl` and local domain data |
| `chezmoi/dot_config/private_herdr/config.toml` | Herdr terminal/session behavior, update settings, theme and toasts | Preserved in tagged history; not installed by this shell/Git scaffold because Herdr configuration is outside v0.0.1 |

## Stow evidence and limits

The current tracked main is already a Workbench/chezmoi layout. Its README says
the legacy Stow packages, AI workflows, old installers, and migration records
were archived outside the checkout. `docs/next-steps.md` says older commits contain
names, emails and client directory names, and other machines may still have local
CLAUDE.md instructions describing Stow. The preserved WSL Stow tree has now also been reviewed, as recorded below.
Keep the repository private. No history rewrite is proposed.

## WSL inventory — complete; preservation verified

The owner completed the WSL inventory and pushed
[`legacy/stow-local-2026`](https://github.com/jeremyspofford/dotfiles/tree/legacy/stow-local-2026).
Its preservation commit is `16477c53fa6bc200b329430f2bac732cdaecee15`, based on
`7f42fc1`. The parent was **32 commits behind** the inventoried main; this count
was verified against `3421071b3ddcbd0dd5ddc728df009af1ba8ca902`.

The preservation commit contains **eight tracked modifications**:

- `packages/git/.gitconfig`
- `packages/mise/.config/mise/config.toml`
- `packages/nvim/.config/nvim/lazy-lock.json`
- `packages/shell/.aliases`
- `packages/shell/.bashrc`
- `packages/shell/.commonrc`
- `packages/shell/.zshrc`
- `packages/ssh/.ssh/config`

It also preserves five previously untracked files:

- `packages/nvim/.config/nvim/lua/plugins/telescope.lua`
- `packages/opencode/.config/opencode/herdr-opencode/tui.js`
- `packages/opencode/.config/opencode/herdr-tui-session.js`
- `packages/opencode/.config/opencode/plugins/herdr-agent-state.js`
- `packages/opencode/.config/opencode/tui.jsonc`

`packages/agents/.agents/.skill-lock.json` and
`packages/agents/.agents/claude-audit.txt` were deliberately left untracked, per the
owner; neither is in the preservation commit. The WSL inventory merge blocker is
closed. The earlier sandbox failure is historical; local execution now works.
This pass used an isolated worktree and did not apply dotfiles to the WSL home.

## WSL salvage decisions

Compared the seven requested source files at the preservation commit against the
candidate's canonical sources. The decisions below distinguish additions from
behavior already covered and incompatible machine preferences.

| Source / item | Disposition | Reason |
| --- | --- | --- |
| `.zshrc`: history, comments, bun completion and autosuggestions | Already covered; retain current behavior | The newer Workbench scaffold already supplies these features and guarded plugin discovery. |
| `.zshrc`: AWS completion and dircolors-aware completion | Taken into `dot_zshrc` | Registers the installed AWS completer without repeating `compinit`; uses available color definitions. |
| `.zshrc`: `.zshrc.local` | Taken as a final optional source | Preserves per-machine overrides without committing their contents. |
| `.zshrc`: vi bindings, adam1 prompt and older completion styles | Not taken as defaults | Keep the newer scaffold's emacs bindings, Starship/fallback prompt and cached completion; a local override can select personal preferences. |
| `.zshrc`: NVM loader and `OLLAMA_HOST` | Not taken | Mise owns Node; the Windows Ollama endpoint is a machine topology choice, not a cross-platform default. |
| `.aliases`: navigation, Git, listing fallbacks, process/network, tool and utility shortcuts | Taken into `core/aliases.zsh` | Restores real conveniences with platform branches and installed-tool guards while retaining Workbench's eza tree exclusions. |
| `.aliases`: `sso()` | Taken with sanitized profile selection | Explicit argument or `AWS_PROFILE` replaces the personal `dev` default; login/export failures stop before changing profile, native exports are retained and credential values are never printed. |
| `.aliases`: `.aliases.local` | Taken after the selected overlay | A machine-local extension overrides generated aliases without becoming another committed source. |
| `.aliases`: replacements for standard commands and forced cleanup/history shortcuts | Not taken | Keep standard commands predictable; omit `dprune`, `tfd`, Git amend/undo/WIP shortcuts from general defaults, including the non-Conventional-Commit WIP message. |
| `.aliases`: `sync-cursor` | Not taken | It depends on an unmanaged personal script and client rules outside this scaffold. |
| `.commonrc`: standalone bin paths, bun/Go/pnpm paths, WSL browser and local override | Taken into `dot_commonrc` | Adds only existing directories without duplication, preserves explicit environment overrides and selects `wslview` only when installed. |
| `.commonrc`: editor, aliases, secrets, platform and Mise setup | Already covered; shared through `dot_commonrc` | Bash and zsh now source the same canonical fragments; Mise activation follows the actual shell instead of the login-shell variable. |
| `.commonrc`: `SSH_AUTH_SOCK`, Windows SSH bridge and wiki path | Not taken | Agent selection, transport and the wiki location remain machine-local; the preserved WSL change had already disabled the Windows Git SSH override. |
| `.bashrc`: history, resize handling, dircolors, completion, prompt and local override | Taken into `dot_bashrc`, with a login entrypoint | Restores Bash behavior and AWS completion while reusing the shared startup and optional Starship integration. |
| `.gitconfig`: aliases, automatic upstream setup and moved-line coloring | Taken into `dot_gitconfig.tmpl` | Retains portable convenience without embedding an identity, client directory or executable version path. |
| `.gitconfig`: main branch, pruning, colors, delta and gh credentials | Already covered | The current template resolves installed tools through PATH and retains the machine-local identity include. |
| `.gitconfig`: identities/client clone aliases, absolute gh path, pull/rebase/autostash, push-current, autocrlf and diff3 defaults | Not taken | Keep identities/routing local and retain the newer fast-forward/simple/zdiff3 baseline; line-ending and history policies remain explicit local choices. |
| Mise config: additional active tools, including Go 1.27 and pnpm | Taken as commented selections in `docs/examples/workbench-tools.toml` | Preserve the real WSL choices without imposing rolling versions or installing agents on every machine; overlapping tools retain Workbench pins. |
| Mise config: Herdr and experimental settings | Not taken into active configuration | Herdr remains outside scope and a blanket experimental-mode setting is unnecessary for the minimal scaffold. |
| SSH config: the one added line | No scaffold change or example | The added line is blank, so there is no missing behavior; the surrounding personal host aliases, agent sockets and agent forwarding remain machine-local. |
| nvim lockfile/telescope and OpenCode/Herdr files | Preserved only on the legacy branch | These editor/app integrations are outside the requested shell/Git/tool salvage scope. |

AWS behavior follows its documented [environment export format](https://docs.aws.amazon.com/cli/latest/reference/configure/export-credentials.html)
and [Bash/zsh completion setup](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-completion.html).
No real credentials were fetched or committed during this pass.

## Preservation and merge gate

Owner requires `legacy/stow-2026` before any merge. This annotated tag now exists
and points to `3421071b3ddcbd0dd5ddc728df009af1ba8ca902`, verified through the GitHub API.
The preservation [workflow run](https://github.com/jeremyspofford/dotfiles/actions/runs/43736087968)
created it without moving main. Its tag-object SHA is
`f32ac6ce6d2315d44f67af393bc4b053e6cc46bf`.

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
