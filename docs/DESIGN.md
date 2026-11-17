# Plain content design

Dotfiles is content. Fleet is the optional manager. Neither requires a custom sync engine.
Git stores source history. Plain files keep their real home names and work with manual links.
Fleet converts them into chezmoi source names, then chezmoi applies them.
The [content contract](https://github.com/jeremyspofford/fleet/blob/main/docs/CONTENT-CONTRACT.md) governs both repositories.

## One source per setting

Edit content here. Keep machine identity, domain, tools, and secret references in the manager profile or local files for manual use.
Tools use selected versions. A domain selects shared settings alone or one personal, work, or client overlay.
An overlay adds role-specific settings. `.config/dotfiles/domain.zsh` reads `~/.config/dotfiles/domain` when the shell starts.
`.aliases` loads shared shortcuts and the chosen overlay when present. Each non-core overlay contains two harmless worked examples to replace. The manifest describes each domain.

`.config/dotfiles/platform.zsh` detects the operating system at runtime with uname and Linux's /proc/version.
WSL means Windows Subsystem for Linux. It uses Linux tools and paths.
macOS checks both Apple Silicon and Intel Homebrew paths. Homebrew installs developer tools.
Shared shell configuration loads aliases, local overrides, optional tools, and private secrets.

## Git and tools

The shared Git file has no identity or tool-detection blocks. Machine identity belongs in `~/.config/git/local.gitconfig`.
Git pull uses fast-forward only: diverged histories require a deliberate decision.
Optional delta settings live in the local Git example. Run `gh auth setup-git` separately for GitHub CLI credentials.

The Mise file is an example DevOps workstation selection. DevOps combines software delivery and system operations.
Mise manages tool versions. Manual users review the example themselves.
Fleet merges content defaults under profile tool versions. It applies defaults only when their requested versions are already installed.
The manager lists other defaults as available; it does not install them.

## Secrets and ownership

`.secrets.example` has comments only. Fleet owns generated `~/.secrets`; manual users create their own file.
The manifest names EXAMPLE_API_TOKEN and a disabled 1Password reference. A reference names a stored secret without containing its value.
Keep values outside Git and use owner-only mode 0600. Git ignore rules cannot protect forced additions or already tracked files.

Agents are coding assistants. Their plain skill folders stay here; Fleet owns the agent manifest and generator.
The installer, converter, profile store, backups, and releases also belong to Fleet.
Historical inventory and changelog files describe the old setup. They do not define current behavior.
