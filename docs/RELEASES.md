# Release rules

`VERSION` is the project version source. Release-please is the tool that proposes and publishes releases.
Its manifest, `.release-please-manifest.json`, is a derived version record. The driver checks equality; never edit the record independently.
`package.json` describes build tools and intentionally has no project version.

Use Conventional Commits: type-prefixed subjects such as `fix: repair setup`. A pull request (PR) proposes a repository change.
Squash change PRs with the same title: combine their commits into one commit. Subjects become plain-language changelog entries, which record release changes.
In `major.minor.patch`, the three numbers describe the release level:

| Change | Automatic result |
| --- | --- |
| `fix`, `chore`, other maintenance | Increase patch, the third number |
| `feat`, breaking changes | Increase minor, the second number |
| Major, the first number | Stay at zero indefinitely |

The workflow registers a version rule and a changelog formatter with release-please.
`bumpMinorPreMajor` routes breaking changes to minor releases. The extra guard rejects nonzero majors and every `Release-As` forced-version request before proposing.
It also checks candidate tags. There is no automatic production-ready switch.
Only the owner can declare production readiness and manually release 1.0.0. That decision requires explicit review of the automation policy.

## Current baseline

A baseline is the release point from which automation counts new commits.
The owner reset history on 2026-11-15. The private `jeremyspofford/dotfiles-archive` repository preserves the earlier history and legacy references.
The new root is `d727c466882dba5ea3287f4ff6398152f74ab783`. Both `bootstrap-sha` and the replacement `v0.0.2` tag point there.
The [v0.0.2 GitHub Release](https://github.com/jeremyspofford/dotfiles/releases/tag/v0.0.2) supplies the release object as well as the tag.
The live 0.0.2 proposal and publication test is complete. Release proposals still need owner review; automation can group later changes.

## Original activation procedure

These steps describe the original migration, not a request to recreate old tags on current main.
The owner has since approved the migration and replaced the baseline as described above.

1. Review the WSL inventory and reused settings. Verify the recorded snapshots under `legacy/stow-2026` and `legacy/stow-local-2026` in the private archive.
   WSL means Windows Subsystem for Linux. Do not automatically merge the migration; obtain owner approval after reviewing the initial dotfiles PR.
2. For the original release, create the reviewed `v0.0.1` tag and GitHub Release. Set `bootstrap-sha` to that commit before automated proposals.
   This excludes legacy history and prevents releasing the initial feature commit twice.
3. Enable GitHub Actions PR creation and repository auto-merge. Auto-merge merges a PR after its required checks pass.
   Require CI / linux, release-policy, and diagram. CI means automated change checks.
4. Supply `RELEASE_PLEASE_TOKEN` from a dedicated automation account (bot) with repository-content and PR write access.
   The default `GITHUB_TOKEN` does not trigger new Actions runs for PRs it creates.
5. Merge a small `fix:` test PR. Confirm a release PR updates `VERSION` and its manifest to `0.0.2` with a Keep a Changelog entry.
   Keep a Changelog is the release-note format used here.
6. Merge that release PR only after CI passes. The next main push publishes its tag and GitHub Release.

Release-please normally groups changes until its release PR merges.
For one release per merged change, process change PRs one at a time. Enable auto-merge on each release PR after required checks.
Wait for publication before merging another change PR. Do not enable release-PR auto-merge without owner approval.
The original connector could not enable repository settings; those settings require a suitable GitHub tool or manual setup.
Automatic per-change publication needs that setup and a successful live test. Historical gaps remain recorded in [BLOCKERS.md](BLOCKERS.md).

Tests cover fixes, chores, features, breaking changes at large `0.x` minor values, forced versions, and already-production versions.
Passing unit tests does not replace the required live 0.0.2 release-PR test.
See [release-please](https://github.com/googleapis/release-please), [custom strategies](https://github.com/googleapis/release-please/blob/main/docs/customizing.md), and [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
