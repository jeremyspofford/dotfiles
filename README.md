# dotfiles

A standalone, chezmoi-managed shell and Git scaffold, built from a sanitized
existing Workbench configuration. Git stores the source, chezmoi renders it for
one machine and domain, and Mise manages tools. You can use this layer on its own.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/jeremyspofford/dotfiles/main/install.sh | bash
```

- Backs up existing managed files, installs missing user-local tools, and prompts for your domain and Git identity before applying.
- Re-running the same command fast-forwards the source and updates your dotfiles.
- Backups live in `~/dotfleet-backups/<YYYYMMDD-HHMMSS>/`, including symlinks and external file targets.

Roll back by reviewing the backup's `MANIFEST` and restoring its saved files; see the [rollback procedure](docs/DESIGN.md#enrollment-and-rollback).

![dotfiles, Dotfleet and add-on layers](docs/diagrams/layers.svg)

Dotfleet will consume dotfiles to provide onboarding and fleet profiles.
Add-ons will extend Dotfleet. Neither is required here; there is no custom sync
engine, GUI, daemon, or agent pack.

## Advanced bootstrap

The installer supports Linux, macOS and WSL and requires Bash, git, curl and tar.
It downloads official chezmoi/Mise binaries into `~/.local/bin` only when missing;
no sudo or GitHub authentication is needed. Install zsh separately if desired.
Python 3.11+ is needed only for the optional agent generator. Native Windows users
should run the installer inside WSL.

The first run reads domain and identity prompts from `/dev/tty`, including when
piped from curl. Later runs reuse your machine-local profile. For disposable CI
homes, `bash install.sh --defaults` explicitly accepts core and a blank identity.
An existing canonical source must be a clean checkout of this repository on
`main`; the installer refuses unrelated repositories, local edits and divergent
history. When invoked from a local clone on first enrollment, it copies that
clone's committed tree into the canonical location without changing the original.

For direct bootstrap use (without the installer's backup/update wrapper):

```sh
git clone https://github.com/jeremyspofford/dotfiles.git
cd dotfiles
bash scripts/bootstrap.sh --interactive
```

Choose `core`, `personal`, `work` or `client` at the prompt. The selected overlay
adds to core; identity stays machine-local. The lower-level bootstrap also accepts
`--domain personal` for noninteractive setup with default identity values.

To use **your own trusted chezmoi repository**, use this bootstrap as tooling:

```sh
bash scripts/bootstrap.sh --repo https://github.com/you/dotfiles.git --dry-run
bash scripts/bootstrap.sh --repo https://github.com/you/dotfiles.git
```

Both modes initialize a checkout and validate templates with `chezmoi diff`
before applying. Dry-run installs tools and initializes source/config state but
does not apply dotfiles. Diff content is suppressed to keep secrets out of logs.
A failing diff prevents apply. A repo can run code through templates and hooks;
dry-run is validation, not a sandbox. The own-repo mode does not inject this
project's aliases, domain values, secrets template, or agents.

Open zsh after setup. Set it as your login shell separately if desired.
Interactive Bash and Bash login sessions are also managed; both shells share
`~/.commonrc` for aliases, secrets, tool paths and Mise activation.
Starship, eza, fzf and other integrations activate only when installed. The
[optional Workbench Mise profile](docs/examples/workbench-tools.toml) preserves
the existing tool choices and commented WSL additions; it is not automatically installed.

## Usage

```sh
chezmoi status
chezmoi diff                   # May display secrets; use only in a private terminal.
chezmoi apply
chezmoi update                 # Git pull plus apply; ordinary chezmoi behavior.
bash scripts/generate-agent-configs.sh --dry-run
bash scripts/generate-agent-configs.sh
bash scripts/bootstrap.sh --help
```

Change `[data].domain` in `~/.config/chezmoi/chezmoi.toml`, then apply again.
The repository's `.chezmoi.toml.tmpl` creates this machine-local configuration.
Names and email addresses are optional template data or can stay in
`~/.config/git/local.gitconfig`; see the [sanitized example](docs/examples/local.gitconfig).

Machine-only shell adjustments can stay in `~/.commonrc.local`,
`~/.aliases.local`, `~/.zshrc.local` or `~/.bashrc.local`. These optional
inputs are not generated or committed. When AWS CLI is installed, `sso PROFILE`
logs in and exports credentials in the current shell; omitting PROFILE requires
an existing `AWS_PROFILE`. Shell startup never performs an AWS login.

Secrets are disabled by default, so a fresh machine gets a private, comment-only
`~/.secrets`. To enable a value, install/sign in to 1Password CLI and set
`secretsEnabled = true` and `secretReference = "op://YourVault/YourItem/field"`
under local `[data]`, then apply. Only references belong in source control.
The rendered file is mode 0600, shell-escaped, and ignored by both repository and
managed global Git ignore rules. Never run `chezmoi add ~/.secrets`.

## How it works

| Source of truth | Generated result |
| --- | --- |
| `dot_zshenv`, `dot_zprofile`, `dot_zshrc` | Shell startup files |
| `dot_bash_profile`, `dot_bashrc`, `dot_commonrc` | Bash startup and shared interactive setup |
| `core/aliases.zsh` plus selected domain | `~/.aliases` |
| `dot_config/` templates and files | Platform/domain fragments, prompt, Git ignore, Mise settings |
| `dot_gitconfig.tmpl` plus local data | `~/.gitconfig` |
| `.chezmoitemplates/dot_secrets.tmpl` | `~/.secrets` via `private_dot_secrets.tmpl` |
| `agents/manifest.toml`, `agents/skills/` | Native configs, skill links and output inventory |
| `docs/diagrams/layers.d2` | Committed `layers.svg` |

The `private_` chezmoi attribute protects secrets permissions; the named secrets
template holds the content in one place. Source-only directories are excluded by
`.chezmoiignore`. Every output and regeneration command is listed in
[GENERATED.md](docs/GENERATED.md). Agent defaults and limitations, including
Ollama's environment-only model, are documented in [AGENTS.md](docs/AGENTS.md).

## Development and review

```sh
shellcheck -x install.sh scripts/*.sh
shfmt -d install.sh scripts/*.sh
python3 -m unittest discover -s tests -p 'test_*.py' -v
npm install --ignore-scripts
npm run test:release
d2 --layout=dagre docs/diagrams/layers.d2 docs/diagrams/layers.svg
```

CI runs shell checks, a fresh Linux-container bootstrap, isolated chezmoi
dry-run/apply tests, release-policy tests and D2 rendering. D2 is pinned to 0.7.1
in CI. Read [DESIGN.md](docs/DESIGN.md) for boundaries and [RELEASES.md](docs/RELEASES.md)
for the owner-only 1.0.0 gate and pending live release test. VERSION is the
version source; Conventional Commit subjects become plain-language changelog entries.

This repository is public. Its history was reset on 2026-11-15; the earlier history is preserved in a private archive.
