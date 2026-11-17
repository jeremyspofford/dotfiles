# Files and ownership

This repository contains plain files. It generates nothing by itself.
A manual link maps each content path to the same path under your home directory.

| Content | Home paths |
| --- | --- |
| Shell files | `~/.zshrc`, `~/.zprofile`, `~/.zshenv`, `~/.bashrc`, `~/.bash_profile`, `~/.commonrc` |
| Alias loader and blocks | `~/.aliases`, `~/.config/dotfiles/aliases/*.zsh` |
| Runtime shell settings | `~/.config/dotfiles/platform.zsh`, `domain.zsh`, `interactive.zsh` |
| Shared Git settings | `~/.gitconfig`, `~/.config/git/ignore` |
| Tool and prompt examples | `~/.config/mise/config.toml`, `~/.config/starship.toml` |
| Plain agent skills | `~/agents/skills/` when managed; otherwise use the checkout directly |

Fleet generates the domain file, local Git identity, merged Mise settings, and private secrets.
It stores converted content at `~/.local/share/fleet/chezmoi-source` and machine data at `~/.config/fleet/profile.toml`.
See the [content contract](https://github.com/jeremyspofford/fleet/blob/main/docs/CONTENT-CONTRACT.md) for regeneration and ownership rules.
The optional Fleet agent generator records every output and preserves edited files during removal.
