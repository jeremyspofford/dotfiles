# dotfiles

Jeremy's personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Start

```bash
# Clone the repo
git clone git@github.com:jeremyspofford/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install stow if needed
sudo apt install stow  # Debian/Ubuntu
brew install stow      # macOS

# Symlink everything
./install.sh

# Or symlink specific packages
stow git
stow shell
stow nvim
```

## Structure

Each directory is a "package" that maps to `$HOME`:

```
dotfiles/
├── git/           # Git configuration
│   └── .gitconfig
├── shell/         # Shell configuration
│   ├── .bashrc
│   ├── .zshrc
│   └── .aliases
├── nvim/          # Neovim configuration
│   └── .config/
│       └── nvim/
└── ssh/           # SSH config (templates only)
    └── .ssh/
        └── config.template
```

## Usage

### Install all packages
```bash
./install.sh
```

### Install specific package
```bash
stow git      # Symlinks git/.gitconfig → ~/.gitconfig
stow shell    # Symlinks shell files to ~
```

### Uninstall a package
```bash
stow -D git   # Removes symlinks for git package
```

### Preview changes (dry run)
```bash
stow -n -v git
```

## Adding New Dotfiles

1. Create a package directory: `mkdir -p package-name/.config/app`
2. Move your dotfile: `mv ~/.config/app/config.toml package-name/.config/app/`
3. Stow it: `stow package-name`

## Notes

- **Secrets**: Never commit secrets. Use `.gitignore` and templates (e.g., `.env.template`)
- **Machine-specific**: Use `.local` suffix for machine-specific overrides (e.g., `.bashrc.local`)
- **Backup**: Existing files are NOT overwritten. Stow will warn about conflicts.

## License

MIT
