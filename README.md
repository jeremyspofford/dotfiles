# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Works on macOS, Linux, and WSL2.

## Quick install

On a fresh machine (Ubuntu/Debian/WSL2):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jeremyspofford/dotfiles/main/bootstrap.sh)
```

This installs prerequisites (git, stow, zsh, curl, unzip), clones the repo to `~/workspace/dotfiles`, runs `install.sh`, and sets zsh as the default shell. Restart your shell afterward.

> **WSL2 note:** Before dotfiles are installed, git can't reach 1Password. If you need to clone a repo first, prefix the command:
> ```bash
> GIT_SSH_COMMAND=ssh.exe git clone git@gitlab.com:org/repo.git
> ```

### Manual install

```bash
git clone https://github.com/jeremyspofford/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
./install.sh
```

The install script handles stow installation if missing, backs up conflicting files on first run, stows all packages, bootstraps SSH known_hosts, and installs JetBrains Mono Nerd Font.

### Install specific packages

```bash
stow git          # just git config
stow shell        # just shell config
stow -D shell     # unlink shell config
stow -n -v shell  # dry run (preview only)
```

## What's inside

| Package | Contents |
|---------|----------|
| `git/` | `.gitconfig` with aliases, delta pager, Aria Labs conditional identity |
| `shell/` | `.bashrc`, `.zshrc`, `.commonrc` (shared config), `.aliases` |
| `ssh/` | Multi-account SSH config (GitHub personal, GitHub Aria Labs, GitLab) |
| `nvim/` | Minimal `init.lua` — line numbers, space leader, sane defaults |

Shell config is split into three layers:
- `.commonrc` — platform detection, PATH, 1Password SSH integration, tool loaders (nvm, mise, bun, gcloud). Sourced by both `.bashrc` and `.zshrc`.
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

- `~/.commonrc.local` — extra PATH entries, env vars
- `~/.bashrc.local` / `~/.zshrc.local` — shell-specific overrides
- `~/.aliases.local` — extra aliases
- `~/.secrets` — API keys, tokens (git-ignored)

## Adding new dotfiles

1. Create a package directory mirroring the home directory structure:
   ```bash
   mkdir -p tmux
   mv ~/.tmux.conf tmux/.tmux.conf
   ```
2. Stow it: `stow tmux`
3. Commit.
