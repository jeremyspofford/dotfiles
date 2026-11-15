# Draft add-on contract

Status: proposal only. No executable interface is implemented in v0.0.1.

An add-on must declare an identifier, version, supported OS/architecture,
dependencies, compatibility range, installation roots and every managed output.
Installation may add tools, configuration or agent resources only within those
declared roots and only after the selected profile opts in.

The host may provide profile ID, domain, OS, architecture, capabilities, explicit
paths and opaque secret references. It must not expose secret values, unrelated
profiles, Git credentials or arbitrary home-directory contents by default.
Additional access requires an explicit documented capability.

Install and update must be idempotent. Plan must report writes and conflicts
without applying. Validate must report actionable failures. Ownership must be
recorded per output; two add-ons cannot silently own the same path. Partial
failure must leave enough inventory to resume or roll back safely.

Teardown removes only owned resources whose current state still matches the
recorded output. Preserve user edits, credentials, shared dependencies and
unrelated files. Explain anything retained and how to resolve it. No unbounded
recursive deletion of home/profile directories is permitted.

Add-ons may request Layer 0 configuration through a documented future host API;
they may not patch dotfiles' canonical sources or install a competing sync daemon.
Git transports source; chezmoi applies files; Mise manages tools.
