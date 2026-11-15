# Blockers and acceptance evidence

## WSL inventory and local execution — resolved

The owner completed the inventory and pushed `legacy/stow-local-2026` at
`16477c53fa6bc200b329430f2bac732cdaecee15`. Its parent was 32 commits behind main.
The branch preserves eight tracked modifications plus five formerly untracked
OpenCode/Herdr and nvim telescope files. `.skill-lock.json` and `claude-audit.txt`
were deliberately left untracked. The requested shell, Git, Mise and SSH sources
were compared with the scaffold; sanitized salvage and exclusions are recorded in
[LEGACY-INVENTORY.md](LEGACY-INVENTORY.md).

The earlier execution-sandbox failure no longer applies. This pass used an
isolated worktree; it did not alter the preserved branch or install configuration
into the WSL home. **WSL inventory is no longer a merge blocker.**

## Main migration — awaiting explicit owner review

The candidate is [PR #1](https://github.com/jeremyspofford/dotfiles/pull/1) on
`feat/chezmoi-v0.0.1`. Main is unchanged. The owner explicitly prohibited merging
on CI results alone. No merge has been performed.

Resolved: the requested annotated `legacy/stow-2026` tag now preserves main at
`3421071b3ddcbd0dd5ddc728df009af1ba8ca902`.
[Preservation run](https://github.com/jeremyspofford/dotfiles/actions/runs/43736087968).

## Live release-please acceptance — deferred

The unit tests prove `fix`/`chore` at 0.0.1 produce 0.0.2 and the 1.0.0 guard
rejects automatic production releases. A real merged test PR and a live
release-please 0.0.2 proposal have **not** been performed. Main has no baseline
VERSION/release configuration until the owner approves the migration.

The workflow proposes release PRs and publishes tags when release PRs are merged.
Strict automatic publication for every merged change remains an activation gap:
repository required checks/auto-merge and a bot token must be configured, and
release PR merging must be automated/serialized. Standard release-please can
batch several merged changes into one release. The current workflow does not
claim to solve that by itself. See [RELEASES.md](RELEASES.md).

## Dotfleet publication — deferred

The earlier run could not create the requested stub repository. Local GitHub CLI
access now works, but repository creation is outside this follow-up. The README
and add-on contract remain staged under `dotfleet-stub/`; no Dotfleet code was
added. This PR stays in the existing dotfiles repository.

## Ollama native config — explicit scope exception

Ollama configures its runtime through process/service environment variables and
has no portable native config-file or SKILL.md discovery contract. The manifest
records unsupported paths explicitly; the generator reports it and does not
invent a config file. See [AGENTS.md](AGENTS.md).

## Verified in GitHub Actions

[Successful CI run](https://github.com/jeremyspofford/dotfiles/actions/runs/43735983320)
at `ea0b8958a1cdb2c6fe78b807026f73f2bc017eee` verified:

- Shellcheck and shfmt pass for every Bash script.
- Fresh Ubuntu 24.04 container installs chezmoi/Mise, validates and applies.
- Managed zsh starts; local .secrets exists at mode 0600 and is Git-ignored/untracked.
- Five Python tests pass, including all four domains, regeneration idempotence,
  every Bash script's help/unknown flags, and agent conflict protection.
- Release-policy tests pass, including 0.0.1 → 0.0.2 and breaking changes staying 0.x.
- D2 0.7.1 renders headlessly; committed SVG exactly matches regenerated output.

No real 1Password credential was fetched. Native macOS/Windows behavior and
live agent application compatibility have not been executed. The Linux bootstrap
test uses the own-repo path against the checked-out candidate, avoiding private
GitHub authentication inside the container.
