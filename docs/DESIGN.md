# Design

## Layer boundaries

Layer 0 is standalone dotfiles: git history, chezmoi source, Mise tools, shell,
Git and optional agent configuration. Layer 1, Dotfleet, will orchestrate existing
git/chezmoi operations and select profiles. Add-ons will attach to Layer 1.
Dotfiles never imports, invokes, or requires Dotfleet.

No sync service or custom merge engine is introduced. The legacy Workbench
orchestrator remains in history rather than becoming a second apply mechanism.
The [inventory](LEGACY-INVENTORY.md) records salvage and the owner's merge gate.

## One source per output

Authored templates and manifest entries are sources. Rendered home files, agent
configurations and skills links are outputs. Edit sources and regenerate; do not
edit generated files. The [output inventory](GENERATED.md) includes every output.
The agent generator refuses to overwrite unmanaged files and records output
hashes/links. Existing agent edits must be reconciled explicitly.

## Domain overlays

`[data].domain` in the local chezmoi config is the only selector. Valid values are
core, personal, work and client. Core always applies. A non-core domain adds
exactly one overlay through a template conditional. Switching domains regenerates
the same output paths, so obsolete aliases disappear without orphan files.

The existing Workbench core supplies reusable defaults. Domain directories start
empty because no separate domain aliases were found in main. Jeremy's optional
tool profile is an example, never a required project specification. Identities,
client names and paths remain machine-local.

## Platforms

Template branches distinguish macOS, Linux, Windows and WSL (Linux plus WSL
environment detection). The macOS branch discovers either Homebrew prefix.
Linux assumes no particular package manager. WSL uses Linux paths and tools.
Native Windows paths are documented in the agent manifest, but Bash bootstrap
requires WSL. No macOS app-bundle executable path survives into portable core.

## Secrets

The template stores a 1Password reference, never a credential. With secrets
disabled it generates a private comment-only file; with secrets enabled it invokes
`onepasswordRead`. Shell single-quote encoding prevents substitutions in credential
values becoming shell commands. chezmoi's private attribute sets mode 0600.

Rendered `.secrets` is ignored in the repo and in managed global Git excludes.
CI checks ignore matching and absence from tracked paths. Git ignore does not
protect forced additions or already-tracked files; review changes before commit.
No diff containing secret values is logged by bootstrap. A 1Password failure
stops rendering instead of substituting a fake credential.

## Enrollment and rollback

`install.sh` is the enrollment and update entry point. It chooses the canonical
source at `~/.local/share/chezmoi`, fast-forwards an existing clean main checkout,
or seeds it from a local clone or public HTTPS. It never resets local changes or
merges divergent history. The original local clone is not modified.

Before applying, the installer asks `chezmoi managed` for the current file and
symlink inventory. If chezmoi is missing, its official installer first downloads
a temporary binary solely for inventory; the permanent binary is installed into
`~/.local/bin` afterward. Mise uses its official installer with the same user-local
destination. No package manager or sudo is invoked.

Each run makes a private `~/dotfleet-backups/<timestamp>/` directory (a suffix
prevents same-second collisions). `home/` mirrors saved paths; `MANIFEST` records
saved/absent paths and symlink targets using Bash-escaped filenames. Symlinks are
copied as links, including broken links. File targets physically outside HOME are
also copied to `external/`, mirroring their absolute paths. The local chezmoi
configuration is backed up before bootstrap regenerates it. Backups may contain
secrets; retain their private directory permissions.

Bootstrap's `--interactive` mode reads initialization prompts from `/dev/tty`.
First enrollment without a terminal fails unless `install.sh --defaults` explicitly
accepts the core profile and blank identity. The installer uses bootstrap's
existing diff validation and apply path; it does not maintain a separate renderer.
The end summary reports backup/source/commit/status even when installation fails
after the logger has loaded. Help and invalid arguments do not start enrollment;
a missing curl or failed logger download on a standalone run produces the shell
or curl diagnostic before logging is available.

To roll back:

1. Stop applying changes and review the chosen backup's `MANIFEST` in a private
   terminal. Restore any `external/` files to the absolute paths recorded there.
2. Restore saved home files with `cp -a /path/to/backup/home/. "$HOME/"`. This
   restores preserved symlinks as links. Review any pre-existing symlinked parent
   directories before copying; do not replace unrelated directory contents.
3. Remove only files created by enrollment whose paths were recorded as `absent`.
   If the chezmoi config was absent, remove the newly generated config too. Keep
   unrelated files and the backups. Installed tools/source may remain in place.
4. Run `chezmoi status` to inspect the restored differences. Do not run apply
   until you intend to replace those restored files again.

Idempotence means identical managed file contents and modes on repeated runs.
New backup directories and updates to chezmoi's own state database are expected.

## Agent scope

The manifest selects native paths/formats and is the only source of config content.
The generator finds installed commands without running them. Empty valid native
configs preserve vendor defaults; authentication is outside this scaffold.
Canonical skill directories are linked per skill. Ollama has no native portable
configuration-file/skills contract and is reported explicitly, not fabricated.

## Future add-on boundary

Dotfleet may pass a validated domain, explicit profile selection, a machine's OS/
architecture/capabilities and approved installation roots to an add-on. An add-on
must declare its managed outputs and dependencies and provide idempotent install,
validation and teardown. It cannot silently modify Layer 0 sources, read secret
values or remove unrelated user configuration. The draft contract is in
`dotfleet-stub/docs/ADDON-INTERFACE.md` pending creation of the separate stub repo.

## Version and release authority

VERSION is authoritative. Release-please's manifest is a derived cache. Automatic
versions stay in 0.x indefinitely: fixes/chores bump patch, features/breaking
changes bump minor. An additional strategy guard rejects nonzero-major proposals
and Release-As overrides. Only the owner may deliberately declare and manually
release 1.0.0. The migration itself always requires explicit owner approval.
