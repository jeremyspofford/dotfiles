# dotfiles

Dotfiles are home configuration files. These come from Workbench, an older setup, with private details removed.
Git records file versions. chezmoi copies or renders configuration files into your home. Mise installs and selects developer tool versions.
Layer 0, this repository, works alone. Planned [Dotfleet](https://github.com/jeremyspofford/dotfleet) forms Layer 1 and manages multiple machines.
Add-ons will extend Dotfleet. This repository has no custom sync engine, graphical interface, background service, or agent pack.

## Install

A checkout is a local Git copy of this repository.
The installer puts a checkout of this repository at ~/dotfiles; that folder is what chezmoi reads, and it's where you edit your dotfiles.
A **profile** is the saved domain and Git commit identity for this machine. A domain selects one group of settings.
Bash runs terminal commands. curl downloads files. tar unpacks archives.

```sh
curl -fsSL https://raw.githubusercontent.com/jeremyspofford/dotfiles/main/install.sh | bash
```

- Setup backs up files, installs missing tools, asks for your profile, and applies settings.
- Re-run this command to update the checkout and your home files.
- Backups live in `~/dotfleet-backups/<YYYYMMDD-HHMMSS>/`. They include links and their external file targets.

Roll back by restoring saved files from a backup's `MANIFEST`; follow the [rollback steps](docs/DESIGN.md#enrollment-and-rollback).

Choose a domain and identity at the prompts:

| Prompt choice | Meaning |
| --- | --- |
| `core` | Shared settings only; the default |
| `personal` | Shared settings plus your personal settings |
| `work` | Shared settings plus your employer's settings |
| `client` | Shared settings plus settings for a client |
| Git name / email | Optional author name and email for commits; blank means no identity here |

First-run prompts read `/dev/tty`, the terminal device, never piped input. Updates reuse the profile.
For disposable test homes, `bash install.sh --defaults` selects `core` and a blank identity without a terminal.
Core supplies shell startup, aliases, Git defaults, and tool setup to every machine. It does not depend on the machine or role.
An overlay adds one role's aliases, settings, and configuration fragments. Personal, work, and client each select exactly one overlay above core.
Choose the machine's role at the prompt. Domains keep personal and employer settings separate.
Domain folders start empty. Aliases are command shortcuts; this setup invents no personal aliases.

Use Linux, macOS, or WSL (Windows Subsystem for Linux). Install Bash, git, curl, and tar first. Native Windows users must use WSL.
Missing chezmoi and Mise binaries go in `~/.local/bin`. The installer needs no sudo or GitHub login.
Install zsh, another command shell, separately if wanted. Changing your login shell is a separate step.

An existing `~/dotfiles` must be this repository's clean `main` checkout.
Updates must fast-forward: advance without merging separate histories.
Setup refuses local edits, unrelated repositories, and separate histories. It never overwrites unrelated `~/dotfiles` contents.
First runs from another clone copy its committed files without changing it.
Updates move the active checkout from the previous hidden location when `~/dotfiles` is absent. Preserved archives stay untouched.
Saved configuration points chezmoi at `~/dotfiles`. Bare `chezmoi status` and `chezmoi apply` work from any directory.
The end summary prints the checkout location and commit. Edit checkout files, then run `chezmoi apply`.
Direct edits to generated home files can be overwritten by the next apply.

## Files in your home

With default directory settings, chezmoi creates or updates these managed files:

- `~/.zshrc`, `~/.zprofile`, `~/.zshenv`: zsh startup.
- `~/.bashrc`, `~/.bash_profile`: Bash startup.
- `~/.commonrc`, `~/.aliases`: shared shell setup and shortcuts.
- `~/.gitconfig`, `~/.config/git/ignore`: Git settings and ignored paths.
- `~/.secrets`: private secrets file; comments only by default.
- `~/.config/chezmoi/chezmoi.toml`: saved source path, domain, and identity.
- `~/.config/dotfiles/domain.zsh`, `~/.config/dotfiles/platform.zsh`, `~/.config/dotfiles/interactive.zsh`: domain, operating-system, and interactive settings.
- `~/.config/mise/config.toml`, `~/.config/starship.toml`: tool manager and prompt settings.

See [GENERATED.md](docs/GENERATED.md) for every source, output, and regeneration command.
Bash interactive/login sessions and zsh load aliases, secrets, tool paths, and Mise through `~/.commonrc`.
Optional tools activate only when installed: Starship formats prompts, eza lists files, and fzf finds choices by partial text.
The [Workbench tool example](docs/examples/workbench-tools.toml) retains existing versions and commented WSL additions. Setup does not install that example.

## Use and update

Run `diff`, which shows proposed changes, only in a private terminal: it can expose secrets.
`update` pulls Git changes and applies them. Re-running the installer also makes a backup.

```sh
chezmoi status
chezmoi diff
chezmoi apply
chezmoi update
cd ~/dotfiles && git pull && chezmoi apply
bash ~/dotfiles/scripts/bootstrap.sh --help
```

Change `[data].domain` in `~/.config/chezmoi/chezmoi.toml` to a domain listed above, then run `chezmoi apply`.
The new overlay replaces the old overlay in the same generated files; obsolete settings disappear.
The `.chezmoi.toml.tmpl` template creates local configuration. Templates contain placeholders for machine settings.
Git identity can instead live in `~/.config/git/local.gitconfig`; see the [example](docs/examples/local.gitconfig).
Keep machine-only shell edits in `~/.commonrc.local`, `~/.aliases.local`, `~/.zshrc.local`, or `~/.bashrc.local`.
These optional files are user-owned; setup neither generates nor commits them.

With the AWS command-line tool installed, `sso PROFILE` signs in and exports credentials into the current shell.
`PROFILE` is an AWS profile name. Without that argument, set `AWS_PROFILE` to the desired name first.
Shell startup never signs in to AWS.

## Optional agent setup

An agent is an installed coding assistant. The generator writes detected agents' settings, skill links, and an output record.
Skills are folders of agent instructions. Use the generator to share them across installed agents.
Skip it without agents or to keep your setup. It neither installs agents nor handles logins.
Requires Python 3.11+. From `~/dotfiles`, preview first: `--dry-run` lists paths without writing.

```sh
bash scripts/generate-agent-configs.sh --dry-run
bash scripts/generate-agent-configs.sh
```

Unknown or edited outputs stop generation. See [agent instructions](docs/AGENTS.md) for paths, conflicts, and removal.
Ollama uses process/service settings; this generator writes no Ollama configuration.

## Secrets

Secrets are off by default. The generated `~/.secrets` contains comments and uses mode `0600`: only its owner can read or write it.
To enable secrets:

1. Install the 1Password command-line tool and sign in.
2. Set `secretsEnabled = true` under `[data]` in `~/.config/chezmoi/chezmoi.toml`.
3. Set `secretReference = "op://YourVault/YourItem/field"` to your vault, item, and field.
4. Run `chezmoi apply`.

Keep references in Git, never secret values. Shell quoting prevents values from becoming commands.
Repository and global Git ignore rules exclude `.secrets`. Never run `chezmoi add ~/.secrets`.
The `private_` source prefix protects file permissions. One named template holds the secret-file content.

## Advanced bootstrap

Bootstrap is the lower-level setup script, without installer backups or updates.
For direct interactive setup, run:

```sh
git clone https://github.com/jeremyspofford/dotfiles.git
cd dotfiles
bash scripts/bootstrap.sh --interactive
```

`--interactive` prompts for domain and identity. `--domain personal` selects initial personal settings and default identity without prompts. Existing profiles keep their saved domain.
For your own trusted repository, preview before applying:

```sh
bash scripts/bootstrap.sh --repo https://github.com/you/dotfiles.git --dry-run
bash scripts/bootstrap.sh --repo https://github.com/you/dotfiles.git
```

`--repo` selects a repository. `--dry-run` installs tools and initializes source/configuration state without applying home files.
Both modes validate templates with `chezmoi diff` before applying. A failed diff stops apply. Bootstrap hides diff content to protect secrets.
Templates and hooks can execute commands. Hooks are chezmoi-triggered commands. Dry-run provides no security isolation.
Own-repository mode adds none of this project's aliases, domains, secret templates, or agents.

## Uninstall

Keep a terminal open until you restore usable shell files. Do not delete unrelated files, credentials, shared tools, or preserved archives.

1. Run `chezmoi status`. Back up checkout edits and changed home files privately before removal.
2. Run `chezmoi managed --include files,symlinks` and save the list outside `~/dotfiles`. `files,symlinks` selects files and symbolic links, which point to other paths.
3. If you used the agent generator, follow its [removal steps](docs/AGENTS.md#remove-generated-agent-files) before deleting the checkout.
4. Remove only the listed managed files. Restore original files from an installer backup using the [rollback steps](docs/DESIGN.md#enrollment-and-rollback).
   Keep any user edits you saved. Remove empty generated directories with `rmdir`; leave directories containing unrelated files.
5. Run `chezmoi purge`. It removes the checkout, configuration, and state, but keeps home outputs.
   Step 4 is therefore required. Review the confirmation. See [purge documentation](https://www.chezmoi.io/reference/commands/purge/).
6. Remove `~/.local/bin/chezmoi` and `~/.local/bin/mise` only if this installer added them and no other project uses them.
   If Mise is no longer needed, remove its installed runtimes at `~/.local/share/mise` and cache at `~/.cache/mise`.
   A cache stores reusable downloads or results. Keep shared tools and user-owned settings.
7. Keep `~/dotfleet-backups` until you verify recovery. Open a fresh shell. Restore your previous login shell separately if you changed it.

## How it works

![dotfiles, Dotfleet and add-on layers](docs/diagrams/layers.svg)

Source files are the files you edit; generated outputs are their rendered copies or links.
Shell sources create startup files. Core aliases and one domain create `~/.aliases`. Git settings combine a template with local data.
The `dot_config/` sources create operating-system, domain, prompt, Git ignore, and Mise settings.
`agents/manifest.toml` is the agent configuration list; `agents/skills/` holds skill content. The generator records its outputs.
D2, a diagram tool, produces the committed SVG, a vector image. `.chezmoiignore` excludes source-only files from your home.
Read [DESIGN.md](docs/DESIGN.md) for boundaries and [RELEASES.md](docs/RELEASES.md) for release rules and recorded live tests.

## Development

CI means continuous integration: automated change checks. It checks shells, fresh Linux setup, isolated apply/preview, releases, and diagrams.
CI uses D2 0.7.1. Run:

```sh
shellcheck -x install.sh scripts/*.sh
shfmt -d install.sh scripts/*.sh
python3 -m unittest discover -s tests -p 'test_*.py' -v
npm install --ignore-scripts
npm run test:release
d2 --layout=dagre docs/diagrams/layers.d2 docs/diagrams/layers.svg
```

`--layout=dagre` selects the diagram layout engine used by CI. ShellCheck checks shell code; shfmt checks its formatting.
`VERSION` is the version source. Conventional Commits use type-prefixed subjects, such as `fix: repair setup`; subjects become release-note entries.
Only the owner can authorize a manual 1.0.0 release. Follow [WRITING.md](docs/WRITING.md) for documentation changes.
This repository is public. Its history was reset on 2026-11-15. The private archive preserves earlier history.
