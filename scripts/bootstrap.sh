#!/usr/bin/env bash
# Purpose: Install chezmoi/Mise; validate then apply bundled or own dotfiles.
# Usage: bash scripts/bootstrap.sh [OPTIONS]; see usage() below.
# Parameters: --repo URL, --domain DOMAIN, --source PATH, --branch NAME,
# --dry-run, -h, --help.
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
bootstrap.sh — standalone dotfiles setup ($DOTFILES_VERSION)
Usage: bash scripts/bootstrap.sh [OPTIONS]
Install missing chezmoi/Mise in ~/.local/bin. Clone/init a trusted source checkout,
validate with chezmoi diff, then run chezmoi init --apply on that same checkout.
Diff contents are suppressed because they may contain secrets.
Requires Bash, curl, git, tar. Install zsh separately for the managed shell.
Supported hosts: Linux, macOS, WSL. Native Windows: use WSL.
Options:
  --repo URL       Own repo (default: https://github.com/jeremyspofford/dotfiles.git).
                  Accepts HTTPS, SSH or an absolute local repository path.
  --domain VALUE   Bundled overlay: core (default), personal, work, client.
  --source PATH    Absolute source path (default: ~/.local/share/chezmoi).
  --branch NAME    Branch to initialize (default: remote default).
  --dry-run        Install tools, clone/init and validate; do not apply dotfiles.
  -h, --help       Print full help and exit 0.
Examples:
  bash scripts/bootstrap.sh --domain personal
  bash scripts/bootstrap.sh --repo https://github.com/you/dotfiles.git --dry-run
  bash scripts/bootstrap.sh --repo git@github.com:you/dotfiles.git
Only use trusted repositories: templates and hooks can execute commands.
Private repositories require existing Git authentication.
Does not change your login shell, install agents, or configure 1Password.
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
source_path="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"
branch=
own_repo=0
dry_run=0
while (($#)); do
	case $1 in
	-h | --help)
		usage
		exit 0
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
	origin=$(git -C "$source_path" remote get-url origin) || {
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
[[ -z $branch ]] || init_args+=(--branch "$branch")
if [[ $own_repo == 0 ]]; then
	init_args+=(--promptString "domain=$domain")
fi
log_info "Initializing source checkout"
chezmoi "${args[@]}" init "${init_args[@]}" "$repo"
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
