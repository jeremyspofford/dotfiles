# Release policy

`VERSION` is the project version source. The release-please manifest is a derived
cache checked against it; it is never edited independently. The package.json
describes build tooling and intentionally has no project version.

Use Conventional Commits and squash PRs with the same title. Fixes, chores and
other maintenance changes increment patch; features and breaking changes
increment minor while the major remains zero. Commit subjects become changelog
bullets, so write plain-language descriptions.

The workflow uses upstream release-please with a small registered versioning
strategy and changelog formatter. `bumpMinorPreMajor` handles breaking changes;
the additional gate rejects nonzero majors and all Release-As overrides before
any proposal. Candidate release tags are also checked. There is no automatic
production-ready switch. Owner-declared 1.0.0 requires a deliberate manual
release and an explicit review of the automation policy.

## Activation after owner review

1. Resolve the WSL inventory and create `legacy/stow-2026` at the preserved main.
2. Review and approve the scaffold PR. Do not auto-merge this migration.
3. Establish the reviewed `v0.0.1` baseline tag/release and set the config's
   `bootstrap-sha` to that baseline commit before the first automated proposal.
   This prevents legacy history and the scaffold feature commit being released twice.
4. Enable Actions PR creation and repository auto-merge. Set required checks
   for CI / linux, release-policy and diagram. Supply `RELEASE_PLEASE_TOKEN`
   from a dedicated bot with contents/PR write permissions; the default
   GITHUB_TOKEN does not trigger new Actions runs for PRs it creates.
5. Merge a small `fix:` test PR. Confirm release-please opens a release PR changing
   VERSION and its derived manifest to 0.0.2, with a Keep a Changelog entry.
6. Merge that release PR after CI. The next main push publishes the tag/release.

Release-please normally batches changes until its release PR is merged. To release
each merged change independently, serialize change PRs and enable auto-merge on
each generated release PR after required CI; do not merge additional change PRs
until that release completes. The current connector cannot enable repository
settings. Automatic per-merge publication is not claimed until this setup and a
live test have succeeded. See BLOCKERS.md.

Policy tests verify fixes, chores, features, breaking changes at large 0.x minors,
Release-As overrides, and already-production versions. A unit-test result is not
a substitute for the requested live 0.0.2 release PR.

References: [release-please](https://github.com/googleapis/release-please),
[custom strategies](https://github.com/googleapis/release-please/blob/main/docs/customizing.md),
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
