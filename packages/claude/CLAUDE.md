# Home Directory — Claude Context

## This Context

Working in `~/` is the **Life/Vault context** — personal system management, dotfiles, shell config, and Obsidian vault work. Not software development. No PRs, no deployments.

---

## Directory Map

| Path | Purpose |
|------|---------|
| `~/workspace/` | All code projects (personal, arialabs, alertventure) |
| `~/Obsidian_Vault/` | Wiki vault (`$WIKI_VAULT`) — personal knowledge base |
| `~/workspace/dotfiles/` | Dotfiles source — managed with GNU Stow |
| `~/Downloads/` | Browser downloads |
| `~/go/` | Go toolchain installation |
| `~/google-cloud-sdk/` | GCP SDK installation |

---

## Dotfiles

All shell and tool config is stow-managed from `~/workspace/dotfiles/`. **Never edit config files in `~/` directly** — edit the source in the dotfiles repo, then re-stow.

Stow packages and what they manage:

| Package | Manages |
|---------|---------|
| `shell` | `.zshrc`, `.bashrc`, `.commonrc`, `.aliases` |
| `claude` | `.claude/` and `CLAUDE.md` |
| `git` | `.gitconfig`, `.gitignore_global` |
| `nvim` | `.config/nvim/` |
| `mise` | `.config/mise/` |
| `ssh` | `.ssh/config` |
| `cursor` | Cursor IDE config |
| `scripts` | `~/bin/` scripts |

To re-stow after editing: `stow -d ~/workspace/dotfiles/packages -t ~ <package>`
To preview without applying: `stow -nv -d ~/workspace/dotfiles/packages -t ~ <package>`

### Local-only files (not in dotfiles repo)

These live in `~/` but are intentionally not committed:
- `~/.secrets` — sourced by `.commonrc`, contains API keys and tokens
- `~/.commonrc.local` — machine-specific overrides, sourced last by `.commonrc`

Do not commit either of these. Do not recreate them without asking.

---

## Shell Config

Config chain: `.zshrc` → `.commonrc` → `.aliases` → `.secrets` (optional) → `.commonrc.local` (optional)

`.commonrc` is the primary config — PATH, env vars, tool activation (mise, bun, pnpm), platform detection (`macos`/`wsl`/`linux`), and 1Password SSH agent setup all live there.

---

## Rules for This Directory

- Don't create new files in `~/` — use `~/workspace/` for code, `~/Obsidian_Vault/` for notes
- Don't edit dotfile symlinks in `~/` directly — trace to the source in `~/workspace/dotfiles/` and edit there
- `~/.secrets` and `~/.commonrc.local` are absent from version control on purpose — don't flag them as missing
