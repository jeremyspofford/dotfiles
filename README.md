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

## Daily use

After the first `./install.sh`, the repo is driven through `stow` and direct edits to package files. Three things to know:

1. **Edit the source, never the symlink.** `~/.zshrc`, `~/.gitconfig`, etc. are symlinks into `packages/`. Open `packages/shell/.zshrc` (or whichever package) and edit there — the symlink reflects the change immediately.
2. **`stow <pkg>` works from anywhere.** `stow.sh` writes `~/.stowrc` with `--dir=…/packages --target=$HOME`, so stow finds the right tree no matter your cwd.
3. **Restow (`-R`) after deleting a tracked file.** Plain `stow` only adds symlinks; `-R` cleans up dead ones too.

### Common operations

| Goal | Command |
|------|---------|
| Stow one package | `stow git` |
| Stow several | `stow shell nvim mise` |
| Stow / restow everything (after pulling, adding files, etc.) | `./stow.sh` |
| Preview a full restow without changing anything | `./stow.sh -n` |
| Restow specific packages with conflict-backup | `./stow.sh shell nvim` |
| Restow (re-link, prune dead symlinks) | `stow -R nvim` |
| Unstow (unlink without deleting source) | `stow -D ssh` |
| Dry run / preview a single package | `stow -nv shell` |
| List packages | `ls packages/` |
| Full bootstrap (fresh machine: installs tools + stows) | `./install.sh` |

### Typical workflow

```bash
# 1. Edit the source in the repo
$EDITOR packages/shell/.aliases

# 2. (No restow needed — the symlink already points at the file.)
#    But if you added or removed a file inside the package:
stow -R shell

# 3. Commit in the repo root
git add packages/shell/.aliases && git commit -m "shell: add foo alias"
```

Adding a new package is its own short section below — see [Adding new dotfiles](#adding-new-dotfiles).

## What gets installed

The install script handles everything:

| Tool | Method |
|------|--------|
| stow, zsh, curl, unzip, libnotify-bin | System package manager |
| [Neovim 0.11](https://neovim.io) | GitHub releases on apt/x86_64 (pinned to `NVIM_VERSION`), package manager elsewhere |
| [delta](https://github.com/dandavison/delta) | GitHub releases .deb on apt, package manager elsewhere |
| [shellcheck](https://www.shellcheck.net/) | System package manager (used by the pre-commit hook) |
| [mise](https://mise.jdx.dev) | `mise.run` installer on Linux, Homebrew on macOS |
| All tools in `packages/mise/.config/mise/config.toml` | `mise install` (runs after stowing) |
| JetBrains Mono Nerd Font | GitHub releases (auto-registered on WSL) |

Zsh is set as the default shell. Conflicting files are backed up to `~/.dotfiles_backup/` before stowing (safe on re-runs).

## What's inside

Every stow package lives under `packages/`. Non-package repo content (examples) sits at the repo root and is invisible to stow.

| Package | Contents |
|---------|----------|
| `packages/git/` | `.gitconfig`, `.gitconfig-arialabs`, `.gitignore_global` |
| `packages/shell/` | `.bashrc`, `.zshrc`, `.commonrc` (shared config), `.aliases` |
| `packages/ssh/` | Multi-account SSH config (GitHub personal, GitHub Aria Labs, GitLab) with 1Password agent |
| `packages/nvim/` | `init.lua` with lazy.nvim, catppuccin theme, treesitter, neo-tree |
| `packages/mise/` | Global tool versions (`config.toml`) — bun, node, python, gh, bat, eza, ripgrep, fzf, uv, and more |
| `.githooks/` | Tracked git hooks (pre-commit shellcheck) — repo-level, not stowed |
| `examples/` | Reference content — not stowed |

Shell config is split into three layers:

- `.commonrc` — platform detection, PATH, 1Password SSH integration, mise activation. Sourced by both `.bashrc` and `.zshrc`.
- `.bashrc` / `.zshrc` — shell-specific settings (prompt, completion, keybindings).
- `.aliases` — aliases for git, docker, k8s, terraform, etc.

## Pre-commit hook

The repo has a tracked `pre-commit` hook in `.githooks/` that runs [shellcheck](https://www.shellcheck.net/) on staged shell scripts. `install.sh` activates it for you on a fresh clone via `git config core.hooksPath .githooks`.

**What it lints:** files matching `*.sh`, `*.bash`, `install.sh`, `bootstrap.sh`, plus any other staged file with a `#!/usr/bin/env bash` (or `sh`) shebang.

**Severity:** `--severity=warning` — catches real bugs including `SC2168` (`local` outside function), `SC2086` (unquoted expansions), `SC2155` (declare-and-assign masking exit codes), and `SC2064` (trap quoting).

**To bypass:** `git commit --no-verify`

**To test:** introduce a deliberate bug and try to commit:

```bash
echo 'local foo=bar' >> install.sh
git add install.sh
git commit -m "test"
# → blocked by hook with shellcheck error
git checkout install.sh   # undo
```

If the hook ever isn't running, check:

```bash
git config --get core.hooksPath          # should print .githooks
ls -l .githooks/pre-commit               # should be executable
```

Re-run `./install.sh` to fix both.

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

1. Create a package directory under `packages/` mirroring the home directory structure:

   ```bash
   mkdir -p packages/tmux
   mv ~/.tmux.conf packages/tmux/.tmux.conf
   ```

2. Stow it: `stow tmux`
3. Commit.

The stow loop in `install.sh` iterates over every directory under `packages/`. Non-package repo content (`examples/`) lives at the repo root and is invisible to the loop by construction — no exclusion list needed.

Conflicting files are automatically backed up on the next `install.sh` run.
