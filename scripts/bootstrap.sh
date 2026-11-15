#!/usr/bin/env bash
# Purpose: Install missing tools, validate files, and apply home configuration.
# Usage: bash scripts/bootstrap.sh [OPTIONS]; see --help for all choices.
# Parameters: --repo URL selects a trusted repository; --source PATH selects its checkout.
# --domain DOMAIN selects initial core (shared), personal, work (employer), or client settings.
# --branch NAME selects a Git branch; --dry-run validates without applying home files.
# --interactive asks for missing profile data; -h/--help prints full help.
# A profile saves the machine's domain and Git identity.
# Examples: bash scripts/bootstrap.sh --domain work
#           bash scripts/bootstrap.sh --repo https://github.com/you/dotfiles.git
# Exit codes: 0 success/help; 1 runtime failure; 2 invalid arguments.
# Author: Jeremy Spofford / Aria Labs; Version: read from ../VERSION at runtime.
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/logger.sh
source "$SCRIPT_DIR/logger.sh"
usage() {
	cat <<EOF
bootstrap.sh — set up home files ($DOTFILES_VERSION)
Usage: bash scripts/bootstrap.sh [OPTIONS]

chezmoi generates home files from source templates. Mise manages developer tools.
Install missing chezmoi/Mise into ~/.local/bin. Initialize a trusted Git checkout.
Validate with chezmoi diff, which compares generated and existing files.
Hide diff contents because they can contain secrets. Apply only after validation passes.
Apply uses chezmoi init --apply on that same checkout.
Requires Bash, curl, git, and tar. Install zsh separately if wanted.
Use Linux, macOS, or WSL (Windows Subsystem for Linux). Native Windows users must use WSL.

Options:
  --repo URL       Select a trusted repository; default: https://github.com/jeremyspofford/dotfiles.git.
                   Accept HTTPS (web), SSH (key-authenticated), or a full local path.
  --domain VALUE   Initial bundled settings: core (shared only, default), personal (personal plus shared),
                   work (employer plus shared), or client (client plus shared).
                   Existing profiles keep their saved domain.
  --source PATH    Full checkout path; default: ~/dotfiles.
  --branch NAME    Git branch to initialize; default: the remote's default branch.
  --dry-run        Install tools and initialize source/configuration state.
                   Validate files, but do not apply them to your home.
  --interactive    Ask for missing domain/name/email through /dev/tty, the terminal device.
                   Name/email identify the Git commit author; blank leaves identity unset.
  -h, --help       Print full help and exit 0.

Examples:
  bash scripts/bootstrap.sh --domain personal
  bash scripts/bootstrap.sh --repo https://github.com/you/dotfiles.git --dry-run
  bash scripts/bootstrap.sh --repo git@github.com:you/dotfiles.git

Templates and hooks can execute commands. Use only trusted repositories.
Private repositories require existing Git authentication.
Setup does not change your login shell, install agents, or configure 1Password.
Agents are coding assistants; 1Password supplies optional secrets.
Exit codes: 0 success/help; 1 runtime failure; 2 invalid arguments.
Author: Jeremy Spofford / Aria Labs; Version: $DOTFILES_VERSION (VERSION).
EOF
}
bad_argument() {
	log_error "$*"
	usage >&2
	exit 2
}
repo=https://github.com/jeremyspofford/dotfiles.git
domain=core
source_path="$HOME/dotfiles"
branch=
own_repo=0
dry_run=0
interactive=0
while (($#)); do
	case $1 in
	-h | --help)
		usage
		exit 0
		;;
	--interactive)
		interactive=1
		shift
		;;
	--dry-run)
		dry_run=1
		shift
		;;
	--repo | --domain | --source | --branch)
		[[ $# -ge 2 && -n $2 && $2 != --* ]] || bad_argument "Missing value for $1"
		case $1 in
		--repo)
			repo=$2
			own_repo=1
			;;
		--domain) domain=$2 ;;
		--source) source_path=$2 ;;
		--branch) branch=$2 ;;
		esac
		shift 2
		;;
	*) bad_argument "Unknown argument: $1" ;;
	esac
done
case $domain in
core | personal | work | client) ;;
*) bad_argument "Invalid domain: $domain" ;;
esac
[[ $source_path == /* ]] || bad_argument "--source must be absolute"
case $repo in
https://* | ssh://* | git@*:* | /*) ;;
*) bad_argument "Unsupported repository URL" ;;
esac
case $(uname -s) in
Linux | Darwin) ;;
*)
	log_error "Use Linux, macOS, or WSL."
	exit 1
	;;
esac
for tool in curl git tar; do
	if ! command -v "$tool" >/dev/null; then
		log_error "Missing prerequisite: $tool"
		exit 1
	fi
done
export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin"
work_dir=$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT
umask 077
if ! command -v chezmoi >/dev/null; then
	log_info "Installing chezmoi"
	curl --fail --silent --show-error --location https://get.chezmoi.io -o "$work_dir/chezmoi-install"
	sh "$work_dir/chezmoi-install" -b "$HOME/.local/bin"
fi
if ! command -v mise >/dev/null; then
	log_info "Installing Mise"
	curl --fail --silent --show-error --location https://mise.run -o "$work_dir/mise-install"
	MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh "$work_dir/mise-install"
fi
if [[ -e $source_path ]]; then
	origin=$(git -C "$source_path" config --get remote.origin.url) || {
		log_error "Source exists but is not a Git checkout: $source_path"
		exit 1
	}
	if [[ $origin != "$repo" ]]; then
		log_error "Source origin differs; choose a new --source."
		exit 1
	fi
fi
args=(--source "$source_path")
init_args=(--promptDefaults)
prompt_required=0
if [[ $interactive == 1 && ! -f ${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.toml ]]; then
	init_args=(--prompt)
	prompt_required=1
fi
[[ -z $branch ]] || init_args+=(--branch "$branch")
if [[ $own_repo == 0 && $interactive == 0 ]]; then
	# chezmoi keys prompt overrides by the displayed question, not the data key.
	init_args+=(--promptString "Domain (core: shared; personal: shared+personal; work: shared+employer; client: shared+client)=$domain")
fi
log_info "Initializing source checkout"
if [[ $prompt_required == 1 ]]; then
	# Never consume the installer script from a curl | bash pipeline.
	if { exec 3<>/dev/tty; } 2>/dev/null; then
		chezmoi "${args[@]}" init "${init_args[@]}" "$repo" <&3
		exec 3>&-
	else
		error_exit 'First enrollment needs a terminal (/dev/tty); use install.sh --defaults only to explicitly accept core/blank identity.'
	fi
else
	# --prompt would ask again even when promptStringOnce has saved values.
	# Updates reuse that data whether or not a terminal is attached.
	chezmoi "${args[@]}" init "${init_args[@]}" "$repo" </dev/null
fi
log_info "Validating templates with chezmoi diff (private output)"
chezmoi "${args[@]}" diff >"$work_dir/diff"
if [[ $dry_run == 1 ]]; then
	log_info "Validation passed; dry run complete."
	exit 0
fi
log_info "Applying the validated checkout"
chezmoi "${args[@]}" init --apply --promptDefaults
log_info "Complete: chezmoi and Mise available; source=$source_path"
log_info "Open zsh; inspect changes with chezmoi status."
if [[ $own_repo == 0 ]]; then
	log_info "Secrets are disabled by default; ~/.secrets contains comments only."
	log_info "Optional: bash $source_path/scripts/generate-agent-configs.sh"
fi
