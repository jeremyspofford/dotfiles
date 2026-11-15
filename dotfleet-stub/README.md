# Dotfleet

A planned fleet layer above [dotfiles](https://github.com/jeremyspofford/dotfiles).
Dotfiles is independently usable; Dotfleet consumes it and will orchestrate git,
chezmoi and Mise across machines and domains. This is a documentation-only stub.

Roadmap:
- TUI onboarding for bundled or user-owned dotfiles repositories.
- Multi-machine personal, work and client profiles.
- Sync orchestration using existing tools.
- An explicit add-on interface with installation, validation and teardown.

No TUI, service, runtime or add-on code is included. See the draft
[add-on contract](docs/ADDON-INTERFACE.md). Version 1.0.0 requires an explicit
owner declaration of production readiness.

These two files are staged in dotfiles only because creating the requested private
`jeremyspofford/dotfleet` repository is blocked. They should become that repo's
entire initial tree once repository creation is available.
