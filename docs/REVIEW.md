# v0.0.1 owner review

Candidate: [PR #1](https://github.com/jeremyspofford/dotfiles/pull/1),
`feat/chezmoi-v0.0.1`. Main remains
`3421071b3ddcbd0dd5ddc728df009af1ba8ca902`.
The annotated `legacy/stow-2026` tag preserves that commit.

## Inventory

All 35 main files were read before implementation. Current main is Workbench/
chezmoi, not an active Stow tree; its own docs say Stow files were archived
outside the checkout. WSL changes and that archive could not be inspected due
to the local sandbox error. The detailed [inventory](LEGACY-INVENTORY.md) identifies
this explicitly rather than inventing a clean working tree.

## Salvaged

- zsh history behavior, emacs key bindings, native completion and optional plugins.
- Guarded eza aliases and fzf options from the real shared shell fragment.
- Git fast-forward pulls, pruning, zdiff3, conditional delta/gh integration and
  machine-local identity include.
- Existing Mise tool pins as an optional example, not a universal requirement.
- Workbench prompt intent: identity, directory, branch and exit status. Starship
  replaces the custom prompt function and avoids scanning client working trees.

## Branch versus main

The candidate replaces the Workbench apply/checkpoint/doctor orchestration and
Mac-shaped layout with a root chezmoi source tree. It removes active Neovim/tmux,
Herdr/zoetrope, Workbench code and their tests from the candidate, preserving all
of them in tagged history. This is a source-tree migration, not an automated
teardown of existing home-directory files. Legacy installed files will remain
until reviewed; do not blindly delete them.

Added: domain overlays, private optional 1Password secrets, canonical agent skills
and manifest, bootstrap, logger interface stub, release policy, CI and D2 source/
rendered SVG. No separate personal aliases were invented; domain overlays are
documented empty customization points. Dotfleet is documentation only.

## Checks and remaining work

CI has passed the fresh Linux container, shell standards, five integration tests,
release-policy tests and byte-for-byte D2 rendering check. Exact run links and
limitations are in [BLOCKERS.md](BLOCKERS.md).

Before any merge: complete WSL inventory, reconcile useful local changes, review
this diff, and obtain explicit owner approval. The preservation tag is complete.
The live release-please test and strict automatic per-merge publication remain
pending; main must not be merged just to demonstrate them.
