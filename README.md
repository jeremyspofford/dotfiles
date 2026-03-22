# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Works on macOS, Linux, and WSL2.

## What's inside

| Package | Contents |
|---------|----------|
| `git/` | `.gitconfig` with aliases, delta pager, Aria Labs conditional identity |
| `shell/` | `.bashrc`, `.zshrc`, `.commonrc` (shared config), `.aliases` |
| `ssh/` | Multi-account SSH config (GitHub personal, GitHub Aria Labs, GitLab) |
| `nvim/` | Minimal `init.lua` — line numbers, space leader, sane defaults |

Shell config is split into three layers:
- `.commonrc` — platform detection, PATH, 1Password SSH agent, tool loaders (nvm, mise, bun, gcloud). Sourced by both `.bashrc` and `.zshrc`.
- `.bashrc` / `.zshrc` — shell-specific settings (prompt, completion, keybindings).
- `.aliases` — platform-aware aliases for git, docker, k8s, terraform, etc.

## Quickstart

### Prerequisites

All platforms need [GNU Stow](https://www.gnu.org/software/stow/) and [delta](https://github.com/dandavella/delta) (git pager).

**macOS:**
```bash
brew install stow git-delta
```

**Ubuntu/Debian (including WSL2):**
```bash
sudo apt install stow
# delta: download .deb from https://github.com/dandavella/delta/releases
```

### Install

```bash
git clone git@github.com:jeremyspofford/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Stow symlinks each package into `$HOME`. Restart your shell afterward.

### Install specific packages

```bash
stow git          # just git config
stow shell        # just shell config
stow -D shell     # unlink shell config
stow -n -v shell  # dry run (preview only)
```

## 1Password SSH agent

SSH keys are stored in 1Password. The `.commonrc` auto-configures the SSH agent socket per platform:

| Platform | How it works |
|----------|-------------|
| **macOS** | Native socket at `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`. Just works after enabling SSH agent in 1Password settings. |
| **Linux** | 1Password Linux app creates `~/.1password/agent.sock` directly. Enable SSH agent in 1Password settings. |
| **WSL2** | Bridges the Windows named pipe into a Unix socket via `npiperelay` + `socat`. Requires extra setup (see below). |

### WSL2 setup

1Password runs on Windows but WSL2 is a separate Linux VM. You need to relay the agent:

1. **Enable SSH agent** in 1Password (Windows) > Settings > Developer > "Use the SSH agent"
2. **Install socat** in WSL2: `sudo apt install socat`
3. **Install npiperelay:**
   ```bash
   go install github.com/jstarks/npiperelay@latest
   # or download the binary from https://github.com/jstarks/npiperelay/releases
   # and put npiperelay.exe somewhere on your Windows PATH
   ```
4. Restart your shell. `.commonrc` starts the relay automatically.

### SSH key setup (all platforms)

1. Create your SSH keys in 1Password (or import existing ones)
2. Export the **public keys only** to `~/.ssh/keys/`:
   ```bash
   mkdir -p ~/.ssh/keys
   # Copy public keys from 1Password into:
   #   ~/.ssh/keys/github-personal.pub
   #   ~/.ssh/keys/github-arialabs.pub
   #   ~/.ssh/keys/gitlab-client.pub
   ```
3. Verify: `ssh-add -l` should list your 1Password keys
4. Test: `ssh -T git@github.com`

No private keys on disk. 1Password handles signing.

## Multi-account Git/SSH

The Aria Labs GitHub org uses a separate SSH key and git identity:

- **SSH:** Repos under `~/workspace/arialabs/` use `github.com-arialabs` host alias. Clone with `git clone-aria <repo>` or set the remote to `git@github.com-arialabs:arialabs/<repo>.git`.
- **Git identity:** `.gitconfig` conditionally loads `.gitconfig-arialabs` (different name/email) for anything in `~/workspace/arialabs/`.

## Machine-specific overrides

Drop a `.local` file next to any config to add machine-specific settings without modifying the shared files:

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
