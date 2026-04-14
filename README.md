# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Works on macOS, Linux, and WSL2.

## Quick install

On a fresh machine (macOS, Ubuntu/Debian, Fedora, Arch, or WSL2):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jeremyspofford/dotfiles/main/bootstrap.sh)
```

This installs prerequisites, clones the repo to `~/workspace/dotfiles`, runs `install.sh`, and installs all global tools via mise. Restart your shell afterward.

> **macOS:** Homebrew must be installed first ([brew.sh](https://brew.sh)).

> **WSL2:** Before dotfiles are installed, git can't reach 1Password. If you need to clone a repo first, prefix the command:
>
> ```bash
> GIT_SSH_COMMAND=ssh.exe git clone git@gitlab.com:org/repo.git
> ```

### Manual install

```bash
git clone https://github.com/jeremyspofford/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
./install.sh
```

### Install specific packages

```bash
stow git          # just git config
stow shell        # just shell config
stow -D shell     # unlink shell config
stow -n -v shell  # dry run (preview only)
```

## What gets installed

The install script handles everything:

| Tool | Method |
|------|--------|
| stow, zsh, curl, unzip, libnotify-bin | System package manager |
| [Neovim 0.11](https://neovim.io) | GitHub releases on apt/x86_64 (pinned to `NVIM_VERSION`), package manager elsewhere |
| [delta](https://github.com/dandavison/delta) | GitHub releases .deb on apt, package manager elsewhere |
| [mise](https://mise.jdx.dev) | `mise.run` installer on Linux, Homebrew on macOS |
| All tools in `mise/.config/mise/config.toml` | `mise install` (runs after stowing) |
| JetBrains Mono Nerd Font | GitHub releases (auto-registered on WSL) |

Zsh is set as the default shell. Conflicting files are backed up to `~/.dotfiles_backup/` before stowing (safe on re-runs).

## What's inside

| Package | Contents |
|---------|----------|
| `git/` | `.gitconfig`, `.gitconfig-arialabs`, `.gitignore_global` |
| `shell/` | `.bashrc`, `.zshrc`, `.commonrc` (shared config), `.aliases` |
| `ssh/` | Multi-account SSH config (GitHub personal, GitHub Aria Labs, GitLab) with 1Password agent |
| `nvim/` | `init.lua` with lazy.nvim, catppuccin theme, treesitter, neo-tree |
| `1password/` | SSH agent config (`agent.toml`) — Personal vault keys, confirmation on use |
| `mise/` | Global tool versions (`config.toml`) — bun, node, python, claude, gh, bat, eza, ripgrep, fzf, uv, and more |
| `claude/` | Global Claude Code config — `CLAUDE.md`, `settings.json`, custom commands |

Shell config is split into three layers:

- `.commonrc` — platform detection, PATH, 1Password SSH integration, mise activation. Sourced by both `.bashrc` and `.zshrc`.
- `.bashrc` / `.zshrc` — shell-specific settings (prompt, completion, keybindings).
- `.aliases` — aliases for git, docker, k8s, terraform, etc.

## Claude Code config

The `claude/` package sets up a global Claude Code environment:

- **`CLAUDE.md`** — global context: who I am, work contexts (personal vs Aria Labs), preferences, working style
- **`settings.json`** — permissions (`dontAsk` mode), global tool allows, hooks
- **`commands/init-project.md`** — `/init-project` command: scaffolds a project-specific `CLAUDE.md` + `.claude/settings.json` with hooks tuned to the project's actual toolchain

### Global hooks

| Event | Hook |
|-------|------|
| `PreToolUse/Bash` | Logs all bash commands with timestamps to `~/.claude/bash-log.txt` (async) |
| `Notification` | Desktop notification via `notify-send` (Linux) or `osascript` (macOS) |

## 1Password SSH

SSH keys live in 1Password — no private keys on disk. The `.commonrc` configures the agent per platform:

| Platform | How it works |
|----------|-------------|
| **macOS** | `SSH_AUTH_SOCK` points to `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock` |
| **Linux** | `SSH_AUTH_SOCK` points to `~/.1password/agent.sock` |
| **WSL2** | `GIT_SSH_COMMAND="ssh.exe"` — git calls the Windows SSH binary, which talks to 1Password natively. |

### Setup

1. In 1Password > **Settings > Developer**, enable **"Use the SSH agent"**
2. On WSL2, also enable **"WSL integration"**
3. Create SSH keys in 1Password (or import existing ones)
4. Add the public keys to your GitHub/GitLab accounts
5. Test: `ssh.exe -T git@github.com` (WSL2) or `ssh -T git@github.com` (macOS/Linux)

## Multi-account Git/SSH

The SSH config uses host aliases for multi-account GitHub access. Clone Aria Labs repos with:

```bash
git clone-aria <repo-name>
```

This clones `git@github.com-arialabs:arialabs/<repo>.git` into `~/workspace/arialabs/`. The `.gitconfig` conditionally loads `.gitconfig-arialabs` (different name/email) for anything in `~/workspace/arialabs/`.

## Machine-specific overrides

Drop a `.local` file next to any config to add machine-specific settings without touching the repo:

- `~/.commonrc.local` — extra PATH entries, env vars, optional tools (gcloud, etc.)
- `~/.bashrc.local` / `~/.zshrc.local` — shell-specific overrides and completions
- `~/.aliases.local` — extra aliases
- `~/.secrets` — API keys, tokens (git-ignored by `.gitignore_global`)

The `examples/` directory has commented starter files for common setups:

```bash
cp examples/commonrc.local.example ~/.commonrc.local
cp examples/zshrc.local.example ~/.zshrc.local
```

## Adding new dotfiles

1. Create a package directory mirroring the home directory structure:

   ```bash
   mkdir -p tmux
   mv ~/.tmux.conf tmux/.tmux.conf
   ```

2. Stow it: `stow tmux`
3. Commit.

Non-stow directories (like `examples/`) are excluded from the stow loop via the `NO_STOW` list in `install.sh`.

Conflicting files are automatically backed up on the next `install.sh` run.
