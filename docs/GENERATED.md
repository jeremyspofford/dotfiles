# Generated output inventory

Paths below are relative to the destination home unless otherwise stated.
`chezmoi managed` gives the live machine's complete managed list.

| Source | Output | Regenerate |
| --- | --- | --- |
| `.chezmoi.toml.tmpl` | `.config/chezmoi/chezmoi.toml` (local data) | `chezmoi init` |
| `dot_zshenv` | `.zshenv` | `chezmoi apply` |
| `dot_zprofile` | `.zprofile` | `chezmoi apply` |
| `dot_zshrc` | `.zshrc` | `chezmoi apply` |
| `dot_bash_profile` | `.bash_profile` | `chezmoi apply` |
| `dot_bashrc` | `.bashrc` | `chezmoi apply` |
| `dot_commonrc` | `.commonrc` (shared Bash/zsh startup) | `chezmoi apply` |
| `dot_aliases.tmpl` + `core/` + selected domain | `.aliases` | `chezmoi apply` |
| `dot_gitconfig.tmpl` | `.gitconfig` | `chezmoi apply` |
| `.chezmoitemplates/dot_secrets.tmpl` via private wrapper | `.secrets` (0600, ignored) | `chezmoi apply` |
| `dot_config/dotfiles/*` | `.config/dotfiles/{domain,platform,interactive}.zsh` | `chezmoi apply` |
| `dot_config/git/ignore` | `.config/git/ignore` | `chezmoi apply` |
| `dot_config/mise/config.toml` | `.config/mise/config.toml` | `chezmoi apply` |
| `dot_config/starship.toml` | `.config/starship.toml` | `chezmoi apply` |
| `agents/manifest.toml` | Native paths listed in manifest and AGENTS.md | `bash scripts/generate-agent-configs.sh` |
| `agents/skills/*` | Per-agent per-skill symlinks | Same generator |
| Generator inventory | `.local/state/dotfiles/agents.json` | Same generator; retains orphan candidates for review |
| `docs/diagrams/layers.d2` | Repo: `docs/diagrams/layers.svg` | `d2 --layout=dagre docs/diagrams/layers.d2 docs/diagrams/layers.svg` (0.7.1) |
| `VERSION` | Repo: `.release-please-manifest.json` | Release-please updates both atomically; driver verifies equality |
| Conventional Commits | Repo: `CHANGELOG.md`, release tags | Guarded release workflow |

Mise and chezmoi install their own caches/binaries; these are tool-owned, not a
second configuration source. Machine-local Git identity and 1Password
authentication are deliberately not generated from this repository.

Optional `.commonrc.local`, `.aliases.local`, `.bashrc.local` and
`.zshrc.local` are user-owned inputs, not generated outputs. The `*.local`
Git ignore rule protects these overrides. Shared editor/fzf settings remain
canonical in `dot_config/dotfiles/interactive.zsh`; its content is Bash-compatible
and both shells source it through `.commonrc`.
