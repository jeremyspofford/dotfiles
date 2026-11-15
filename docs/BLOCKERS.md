# Blockers

This file records observed limits, not successful acceptance claims.

## Execution sandbox

On 2026-11-15 every local process launch failed before executing:
`cannot enforce sandbox read-only path /home/jeremy/.agents because it crosses writable symlink /home/jeremy/.agents`.
The patch tool also failed to write files. Local instructions could not be read,
and local git, shellcheck, shfmt, D2, container tests, and GitHub CLI could not run.
Implementation is being prepared through the authorized GitHub connector.

## Existing dotfiles repository

The requested private repository already contains an active Workbench setup.
The new scaffold is isolated on `feat/chezmoi-v0.0.1`; main is unchanged.
Merging requires the owner's explicit review and approval, even after checks pass. The old history
remains available in the parent commit. This branch intentionally replaces the
Workbench tree; it does not introduce a second active configuration source.

## WSL inventory and legacy tag

The WSL clone and uncommitted changes remain uninspected because no local process
can start. The requested `legacy/stow-2026` tag cannot be created with the available
connector; local git is blocked. Both must be resolved before merge. See
[LEGACY-INVENTORY.md](LEGACY-INVENTORY.md).

## Dotfleet creation

`jeremyspofford/dotfleet` returned 404. The connector has no repository-creation
endpoint, and local GitHub CLI execution is blocked. The two requested stub
documents are staged under `dotfleet-stub/` for transfer to a private repository.
No Dotfleet code is included.

## Acceptance evidence

Fresh-container execution, clean shellcheck/shfmt, D2 rendering, and the live
release-please 0.0.2 proposal must be confirmed by CI before completion is claimed.
The release workflow needs a bot token with contents and pull-request write
permissions to trigger subsequent CI on its release PRs. Repository Actions must
allow PR creation, and automatic merging must be enabled. These settings cannot
be changed using the current connector.

## Ollama boundary

Ollama is a model runtime, not a skills-aware agent. It has environment-variable
configuration rather than a portable native config file and SKILL.md discovery.
The manifest records this explicitly; the generator reports it without inventing
an unsupported `~/.ollama/config.json`. See docs/AGENTS.md.
