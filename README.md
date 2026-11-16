# dotfiles

Dotfiles are home configuration files. This repository contains plain files with real names, such as `.zshrc` and `.gitconfig`.
It has no installer, templates, or release automation. [Dotfleet](https://github.com/jeremyspofford/dotfleet) is the optional manager.
The shared [content contract](https://github.com/jeremyspofford/dotfleet/blob/main/docs/CONTENT-CONTRACT.md) defines files, groups, and ownership.

![Content and manager layers](docs/diagrams/layers.svg)

## Use by hand

Git records file versions. A checkout is a local copy of this repository. A symbolic link points to another file or directory.
Back up existing target files before creating links. Do not force links over existing settings.

1. Clone the repository:

   ```sh
   git clone https://github.com/jeremyspofford/dotfiles.git ~/dotfiles
   ```

2. Link shell files and configuration directories:

   ```sh
   for file in .zshrc .zprofile .zshenv .bashrc .bash_profile .commonrc .aliases .gitconfig; do
     ln -s "$HOME/dotfiles/$file" "$HOME/$file"
   done
   mkdir -p ~/.config
   for directory in dotfiles git mise; do
     ln -s "$HOME/dotfiles/.config/$directory" "$HOME/.config/$directory"
   done
   ln -s "$HOME/dotfiles/.config/starship.toml" ~/.config/starship.toml
   ```

3. Write the machine's domain, a group of role-specific settings:

   ```sh
   printf 'personal\n' > ~/.config/dotfiles/domain
   ```

   Choose core for shared settings only, personal for personal settings, work for employer settings, or client for client settings.
   Shared settings always apply. Missing overlay files are allowed. An overlay adds one domain's settings.
   Each non-core overlay has two examples: DOMAIN_where runs pwd; DOMAIN_list runs ls. Replace these with your own aliases.

4. Copy and edit the local Git example:

   ```sh
   cp ~/dotfiles/docs/examples/local.gitconfig ~/.config/git/local.gitconfig
   chmod 600 ~/.config/git/local.gitconfig
   ```

   Set your author name and email there. The optional delta block formats Git diffs; enable it only after installing delta.

5. Create `~/.secrets` by hand if needed. Use `chmod 600 ~/.secrets` for owner-only access. Never commit secret values.
6. Open a fresh shell. Install optional tools separately.

Mise selects tool versions. Its plain config is a DevOps workstation example; DevOps combines software delivery and system operations.
Review its pins, which select versions, before using it by hand. Project Mise files can override global choices.
Run `gh auth setup-git` once if you use GitHub CLI credentials. That command configures Git's credential helper.
`pull.ff = only` is deliberate: Git pull advances matching history and stops when histories have diverged. It never creates a merge automatically.

## Use Dotfleet

Use [Dotfleet's one-line installer](https://github.com/jeremyspofford/dotfleet#install) for backups, profiles, group choices, and generated machine settings.
A profile saves a machine's domain, identity, pins, and content selections. Dotfleet converts this plain content for chezmoi, which applies home files.
The content checkout stays at `~/dotfiles`. Dotfleet owns its private converted source and never rewrites the content checkout.

## Content

- Shell startup: `.zshrc`, `.zprofile`, `.zshenv`, `.bashrc`, `.bash_profile`, and `.commonrc`.
- Shortcuts: `.aliases` loads `.config/dotfiles/aliases/core.zsh` and the selected domain overlay.
- Runtime settings: `.config/dotfiles/platform.zsh`, `domain.zsh`, and `interactive.zsh`.
- Git: `.gitconfig` and `.config/git/ignore`; identity belongs in local Git settings.
- Tools and prompt: `.config/mise/config.toml` and `.config/starship.toml`. Starship formats the shell prompt.
- Agent skills: `agents/skills/`. A skill is a folder of instructions for a coding assistant.
- Secret guidance: `.secrets.example`, which contains comments only.

`dotfleet.toml` declares optional Docker, Terraform, Kubernetes, Python, and npm shortcut groups.
The manager can omit their marked blocks. Manual users get all available shortcut blocks.
The `sso()` function keeps AWS sign-in credentials in the current shell. It requires a profile argument or `AWS_PROFILE`; startup never signs in.
Local overrides remain supported: `~/.commonrc.local`, `~/.aliases.local`, `~/.zshrc.local`, and `~/.bashrc.local`.

## Update and remove

1. Commit your edits, then run `git -C ~/dotfiles pull --ff-only`.
2. With manual links, open a fresh shell. With Dotfleet, rerun its installer.
3. To remove manual setup, unlink only links that point into this checkout. Restore your backups before deleting the checkout.
4. For managed setup, restore a Dotfleet backup using its recorded paths. Keep unrelated settings, credentials, tools, and archives.

Read [DESIGN.md](docs/DESIGN.md), [GENERATED.md](docs/GENERATED.md), and [WRITING.md](docs/WRITING.md).
Historical release notes and the legacy inventory remain records of the previous layout.

## Manager helpers

The optional helpers group defines shortcuts when `dotfleet` is installed. A group selects related commands or files.
Use `dtf` for `dotfleet`, `dtfu` for update, `dtfs` for status, and `dtfd` for a preview.
Run `dtf rollback` to restore a backup. Run `dtf domain personal` to switch to your personal settings.
The helpers never replace `df`, the disk-usage command. Without Dotfleet, these aliases stay undefined.
