# Generated files

chezmoi renders source files into home files. A generated output is a file or link created from an authored source.
Paths beginning with `~/` refer to your home. Repository paths refer to `~/dotfiles`. Run `chezmoi managed` for the complete live list.

Bash and zsh are shells. A domain selects core-only, personal, work, or client settings; core settings always apply.
A manifest is a settings list. An agent is an installed coding assistant; a skill is a folder of instructions.
A symbolic link points to another path. Mode `0600` permits only the owner to read or write the file.
D2 creates diagrams; SVG is the generated image format. `--layout=dagre` selects CI's diagram layout engine.
CI means automated change checks. Release-please creates release proposals. Conventional Commits use type-prefixed subjects such as `fix: repair setup`.

| Source | Output | Regenerate |
| --- | --- | --- |
| `.chezmoi.toml.tmpl` | `~/.config/chezmoi/chezmoi.toml`: local data and source path | `chezmoi init` |
| `dot_zshenv`, `dot_zprofile`, `dot_zshrc` | `~/.zshenv`, `~/.zprofile`, `~/.zshrc` | `chezmoi apply` |
| `dot_bash_profile`, `dot_bashrc` | `~/.bash_profile`, `~/.bashrc` | `chezmoi apply` |
| `dot_commonrc` | `~/.commonrc`: shared Bash/zsh startup | `chezmoi apply` |
| `dot_aliases.tmpl`, `core/`, selected domain | `~/.aliases`: command shortcuts | `chezmoi apply` |
| `dot_gitconfig.tmpl` | `~/.gitconfig` | `chezmoi apply` |
| `.chezmoitemplates/dot_secrets.tmpl`, `private_dot_secrets.tmpl` | `~/.secrets`: mode `0600`, Git-ignored | `chezmoi apply` |
| `dot_config/dotfiles/*` | `~/.config/dotfiles/domain.zsh`, `~/.config/dotfiles/platform.zsh`, `~/.config/dotfiles/interactive.zsh` | `chezmoi apply` |
| `dot_config/git/ignore` | `~/.config/git/ignore` | `chezmoi apply` |
| `dot_config/mise/config.toml` | `~/.config/mise/config.toml` | `chezmoi apply` |
| `dot_config/starship.toml` | `~/.config/starship.toml` | `chezmoi apply` |
| `agents/manifest.toml` | Agent paths in the manifest and [AGENTS.md](AGENTS.md) | `bash scripts/generate-agent-configs.sh` |
| `agents/skills/*` | One symbolic link per skill per agent | Same generator |
| Generator's output record | `~/.local/state/dotfiles/agents.json` | Same generator; retains unused outputs for review |
| `docs/diagrams/layers.d2` | Repository: `docs/diagrams/layers.svg` | D2 0.7.1: `d2 --layout=dagre docs/diagrams/layers.d2 docs/diagrams/layers.svg` |
| `VERSION` | Repository: `.release-please-manifest.json` | Release-please updates both together; the driver checks equality |
| Conventional Commit subjects | Repository: `CHANGELOG.md`, release tags | Guarded release workflow |


Mise manages tools. Its binaries and caches belong to the tool, as do chezmoi's; they are not another configuration source.
A cache stores reusable results or downloads. This repository supplies neither machine-specific Git identity nor 1Password login credentials.
Keep local identity in machine configuration; the Git template can render it into `~/.gitconfig`.

The user owns optional `~/.commonrc.local`, `~/.aliases.local`, `~/.bashrc.local`, and `~/.zshrc.local` inputs. The generator does not create them.
The `*.local` Git rule excludes these overrides. Both shells load shared editor and fzf settings through `~/.commonrc`.
fzf finds choices by partial text. Their single source is `dot_config/dotfiles/interactive.zsh`, whose content also works in Bash.
