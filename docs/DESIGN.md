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
