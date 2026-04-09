# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Works on macOS, Linux, and WSL2.

## Quick install

On a fresh machine (macOS, Ubuntu/Debian, Fedora, Arch, or WSL2):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jeremyspofford/dotfiles/main/bootstrap.sh)
```

This installs prerequisites, clones the repo to `~/workspace/dotfiles`, and runs `install.sh`. Restart your shell afterward.

> **macOS:** Homebrew must be installed first ([brew.sh](https://brew.sh)).

> **WSL2:** Before dotfiles are installed, git can't reach 1Password. If you need to clone a repo first, prefix the command:
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
| stow, zsh, curl, unzip | System package manager |
| [Neovim 0.11](https://neovim.io) | GitHub releases on apt/x86_64 (pinned), package manager elsewhere |
| [delta](https://github.com/dandavison/delta) | GitHub releases .deb on apt, package manager elsewhere |
| [mise](https://mise.jdx.dev) | `mise.run` installer on Linux, Homebrew on macOS |
| [bun](https://bun.sh) | `mise use --global bun@latest` |
| JetBrains Mono Nerd Font | GitHub releases (auto-registered on WSL) |

Zsh is set as the default shell. Conflicting files are backed up to `~/.dotfiles_backup/` before stowing (safe on re-runs).

## What's inside

| Package | Contents |
|---------|----------|
| `git/` | `.gitconfig` with aliases, delta pager, Aria Labs conditional identity |
| `shell/` | `.bashrc`, `.zshrc`, `.commonrc` (shared config), `.aliases` |
| `ssh/` | Multi-account SSH config (GitHub personal, GitHub Aria Labs, GitLab) |
| `nvim/` | `init.lua` with lazy.nvim, catppuccin theme, treesitter |

Shell config is split into three layers:
- `.commonrc` — platform detection, PATH, 1Password SSH integration, mise activation. Sourced by both `.bashrc` and `.zshrc`.
- `.bashrc` / `.zshrc` — shell-specific settings (prompt, completion, keybindings).
- `.aliases` — aliases for git, docker, k8s, terraform, etc.

## 1Password SSH

SSH keys live in 1Password — no private keys on disk. The `.commonrc` configures the agent per platform:

| Platform | How it works |
|----------|-------------|
| **macOS** | `SSH_AUTH_SOCK` points to `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock` |
| **Linux** | `SSH_AUTH_SOCK` points to `~/.1password/agent.sock` |
| **WSL2** | `GIT_SSH_COMMAND="ssh.exe"` — git calls the Windows SSH binary, which talks to 1Password natively. No relay or socket bridging needed. |

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
- `~/.secrets` — API keys, tokens (git-ignored)

The `examples/` directory has commented starter files for common setups:

```bash
cp examples/commonrc.local.example ~/.commonrc.local
cp examples/zshrc.local.example ~/.zshrc.local
```

Edit the copies to uncomment what you need (gcloud, client-specific env vars, proxy settings, etc.).

## Adding new dotfiles

1. Create a package directory mirroring the home directory structure:
   ```bash
   mkdir -p tmux
   mv ~/.tmux.conf tmux/.tmux.conf
   ```
2. Stow it: `stow tmux`
3. Commit.

Conflicting files are automatically backed up on the next `install.sh` run.
