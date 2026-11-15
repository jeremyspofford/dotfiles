# Design

## Layers and ownership

Layer 0 is standalone dotfiles: shell, Git, tools, and optional agent settings.
Git records source history. chezmoi renders source files into home files. Mise manages developer tools.
Layer 1 is Dotfleet, a planned manager for machines and profiles. A profile saves a machine's domain and identity.
Add-ons are optional Dotfleet extensions. Dotfiles never imports, calls, or requires Dotfleet.
There is no sync service or custom merge engine. Workbench, the older setup, stays archived rather than providing another apply mechanism.
The [inventory](LEGACY-INVENTORY.md) records reused settings and the owner's approval rule.

Templates contain placeholders; manifest entries declare settings and paths. These authored files are the sources.
Rendered home files, agent settings, and skill links are outputs. A skill is a folder of agent instructions.
Edit sources and regenerate outputs. Do not edit generated files. [GENERATED.md](GENERATED.md) lists every output.
The agent generator rejects unowned files. Resolve agent edits before generating replacements.
It records link targets and hashes, identifiers used to compare file contents.

## Domains and systems

`[data].domain` in local chezmoi configuration is the only domain selector:

| Value | Settings |
| --- | --- |
| `core` | Shared settings only; always included |
| `personal` | Core plus personal settings |
| `work` | Core plus employer settings |
| `client` | Core plus client settings |

An overlay is one domain's added settings. A non-core domain adds exactly one overlay through a template condition.
Changing domains regenerates the same paths, so obsolete aliases disappear. Aliases are command shortcuts.
Workbench supplies shared defaults. Domain folders start empty because the old main branch had no separate domain aliases.
Jeremy's tool profile is optional, not a project requirement. Identities, client names, and paths stay machine-local.

Templates distinguish macOS, Linux, Windows, and WSL (Windows Subsystem for Linux).
macOS finds either Homebrew package-manager prefix, the installation directory. Linux assumes no specific package manager.
WSL uses Linux paths and tools. The agent manifest describes native Windows paths; Bash setup there requires WSL. Bash is a command shell.
Portable core has no fixed macOS application-bundle executable path.

## Global tool pins

A pin selects a tool version. Local `[data.miseTools]` owns global pins; the Mise template renders them into `~/.config/mise/config.toml`.
Before the first apply, initialization copies existing `[tools]` entries into that data. Lists and option tables retain their values.
Without existing pins, it records the newest installed Node and Python versions, when present. It installs neither runtime.
Saved data wins on later runs, including an explicit empty table. Project files override global choices within their projects.
Change the data, then apply. `mise use -g` edits only the generated file; copy its selections into machine data before applying.
Malformed existing TOML, the configuration format, stops enrollment before apply. The installer backs up the original file before initialization.
The end summary lists pins and their initial source. The repository contains no machine's version choices.

## Secrets

The secret template stores a 1Password reference, never a credential value. A reference names a stored secret without containing its value.
Secrets off generates private comments only. Secrets on retrieves the value through `onepasswordRead`.
Shell single quotes prevent credential contents from becoming commands. chezmoi's `private_` prefix sets mode `0600`: owner-only read/write access.
Repository and global Git ignore rules exclude generated `.secrets`. CI, the automated checks, verifies ignore matching and no tracked secrets.
Ignore rules cannot protect forced additions or files Git already tracks. Review changes before committing.
A diff shows proposed file changes. Bootstrap, the setup script, never logs secret-bearing diffs.
A 1Password failure stops rendering; it never substitutes a fake credential.

## Enrollment and rollback

Enrollment means installing this setup on a machine. `install.sh` handles enrollment and updates.
A checkout is a local Git copy. The editable checkout lives at `~/dotfiles`.
The installer fast-forwards clean `main` checkouts: Git advances without merging separate histories.
Fresh installs copy a local clone's committed tree or clone public HTTPS. The original local clone stays unchanged.
Run `chezmoi apply` to render edits into your home.
Local configuration saves `sourceDir`, the checkout path. Bare `chezmoi status` and `chezmoi apply` work anywhere in a fresh shell.
The installer never resets local changes or merges separate histories.

If `~/dotfiles` is absent, updates migrate this repository's active clone from the previous hidden location.
The installer validates and fast-forwards that clone before moving it. It then backs up files and configures the new source path.
It checks bare `chezmoi status`. Only the exact previous active path qualifies; preserved pre-reset archives stay untouched.
If an unrelated item occupies `~/dotfiles`, setup stops before moving, pulling, backing up, or applying anything.
Re-run the one-liner to update, or run `cd ~/dotfiles && git pull && chezmoi apply`.

Before apply, `chezmoi managed` lists managed files and symbolic links, which point to other paths.
If chezmoi is missing, its official installer downloads a temporary listing binary. It installs permanently in `~/.local/bin` afterward.
The official Mise installer uses the same directory. Setup never calls sudo or a package manager.

Each run creates private `~/dotfleet-backups/<timestamp>/`. A suffix prevents collisions within one second.
`home/` mirrors saved paths. `MANIFEST` records saved and absent paths, plus link targets, with Bash-escaped filenames.
Copies preserve links, including broken links. External file targets also go into `external/`, mirroring their full paths.
Setup backs up local chezmoi configuration before bootstrap regenerates it. Backups can contain secrets; keep their directory permissions private.

`--interactive` reads setup prompts from `/dev/tty`, the terminal device.
First enrollment without a terminal fails unless `--defaults` explicitly accepts core settings and blank identity.
The installer uses bootstrap's existing diff validation and apply path. It adds no separate renderer.
After loading the logger, which formats messages, every run prints backup, checkout, commit, and status, even on failure.
Help and invalid arguments never start enrollment. Before logging is available, missing curl or a failed logger download produces shell or curl errors.

To restore an earlier setup:

1. Stop applying files. Review the backup's `MANIFEST` privately. Restore `external/` files to their recorded full paths.
2. Run `cp -a /path/to/backup/home/. "$HOME/"` to restore saved files and links.
   Inspect existing linked parent directories first. Do not replace unrelated contents.
3. Remove only newly created files marked `absent`. If chezmoi configuration was absent, remove the new configuration too.
   Keep unrelated files and backups. Tools and the checkout may remain.
   After migration, keep restored `sourceDir` set to the full path of `~/dotfiles`; the checkout now lives there.
4. Run `chezmoi status` to inspect restored differences. Do not apply until you intend to replace the restored files.

Idempotence means repeated runs preserve managed contents and permissions. New backups and changes to chezmoi's state database are expected.

## Agents and future add-ons

The agent manifest alone defines configuration content, formats, and operating-system paths.
The generator finds commands without running them. Minimal valid settings preserve agent defaults; login remains outside this setup.
Each skill links to its source. Ollama has no portable configuration-file or skill format; the generator reports this limit.

A capability grants specific access. An installation root is an allowed destination directory.
Dotfleet may provide a validated domain, selected profile, operating system, processor architecture (type), capabilities, and approved installation roots.
Each add-on must declare outputs and dependencies, and support repeatable install, validation, and removal.
An add-on cannot silently change Layer 0 sources, read secret values, or remove unrelated user settings.
Originally, `dotfleet-stub/docs/ADDON-INTERFACE.md` held the draft pending a separate repository.
The current [draft contract](https://github.com/jeremyspofford/dotfleet/blob/main/docs/ADDON-INTERFACE.md) lives in Dotfleet.

## Releases and approval

`VERSION` is authoritative. Release-please, the release automation tool, keeps a matching derived manifest, or version record.
Automatic releases remain in `0.x`. Fixes and chores increase the patch number; features and breaking changes increase the minor number.
In `0.minor.patch`, minor and patch are the second and third numbers.
A strategy guard rejects nonzero major versions and `Release-As` overrides, which request a forced version.
Only the owner can declare production readiness and manually release 1.0.0. The migration itself requires explicit owner approval.
