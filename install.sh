#!/usr/bin/env bash
# Purpose: Install or update the bundled home configuration.
# Usage: bash install.sh [--defaults]; see --help for the one-line command.
# Parameters: --defaults selects shared settings and blank Git identity without prompts.
# -h and --help print full help.
# Save existing global tool pins before apply; otherwise select installed Node/Python defaults.
# Examples: bash install.sh; bash install.sh --defaults
# Exit codes: 0 success/help; 1 missing tool, install failure, or drift; 2 invalid arguments.
# Drift means home files differ from the generated result.
# Author: Jeremy Spofford / Aria Labs; Version: read from VERSION at runtime.
set -euo pipefail

repo=https://github.com/jeremyspofford/dotfiles.git
raw=https://raw.githubusercontent.com/jeremyspofford/dotfiles/main
source_path="$HOME/dotfiles"
legacy_source_path="$HOME/.local/share/chezmoi"
script_path=${BASH_SOURCE[0]:-}
script_dir=
if [[ -n $script_path && -f $script_path ]]; then
	script_dir=$(cd -- "$(dirname -- "$script_path")" && pwd)
fi
DOTFILES_VERSION=unknown
if [[ -n $script_dir && -r $script_dir/VERSION ]]; then
	read -r DOTFILES_VERSION <"$script_dir/VERSION"
fi
usage() {
	cat <<HELP
install.sh — install or update dotfiles ($DOTFILES_VERSION)
Usage: bash install.sh [OPTIONS]
       curl -fsSL $raw/install.sh | bash

Dotfiles are home configuration files. chezmoi generates them; Mise manages tools.
Setup backs up existing managed files, then applies the bundled files.
It installs missing chezmoi and Mise into ~/.local/bin without sudo.
Requires Bash, git, curl, and tar on Linux, macOS, or WSL.
WSL means Windows Subsystem for Linux. Native Windows users must use WSL.

A profile saves this machine's domain and Git commit identity.
Domain choices: core = shared only; personal = shared plus personal settings;
work = shared plus employer settings; client = shared plus client settings.
Git name/email identify the commit author; blank leaves identity unset here.
First-run prompts read /dev/tty, the terminal device, never piped input.
Updates reuse the profile. The ~/dotfiles Git checkout must be clean and on main.
Pins select global tool versions. Setup saves existing pins before the first apply.
Without pins, it selects the newest installed Node and Python, when present.
Change pins in [data.miseTools] in ~/.config/chezmoi/chezmoi.toml, then run chezmoi apply.
Do not edit the generated Mise file or use mise use -g as permanent storage.
Updates must fast-forward: advance without merging separate histories.
A first run inside another clone copies its committed files without changing it.

Options:
  --defaults  Select core and blank identity without prompts; for test homes.
  -h, --help  Print full help and exit 0.

Examples:
  bash install.sh
  bash install.sh --defaults
  curl -fsSL $raw/install.sh | bash

Edit your checkout at ~/dotfiles, then run chezmoi apply.
Backups: ~/dotfleet-backups/<YYYYMMDD-HHMMSS>/; collisions get a unique suffix.
MANIFEST records saved/absent paths and link targets. home/ holds file copies.
external/ holds file targets outside your home. Review MANIFEST before restoring.
See docs/DESIGN.md for recovery steps.
Exit codes: 0 success/help; 1 missing tool, install failure, or drift; 2 invalid arguments.
Drift means home files differ from the generated result.
Author: Jeremy Spofford / Aria Labs; Version: $DOTFILES_VERSION (VERSION).
HELP
}
defaults=0
for argument in "$@"; do
	case $argument in
	--defaults) defaults=1 ;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		usage >&2
		exit 2
		;;
	esac
done

work_dir=
backup_path='not created'
source_commit='not resolved'
status_result='not run (installation incomplete)'
mise_pins_result='not recorded (installation incomplete)'

finish() {
	local result=$?
	trap - EXIT
	set +e
	log_info 'END SUMMARY'
	log_info "Result: $([[ $result == 0 ]] && echo SUCCESS || echo FAILED) (exit $result)"
	log_info "Backup: $backup_path"
	log_info 'Your dotfiles live in: ~/dotfiles — a git checkout. Edit files there, then run: chezmoi apply'
	log_info "Commit: $source_commit"
	log_info "chezmoi status: $status_result"
	log_info "Mise global pins: $mise_pins_result"
	log_info 'Additional information'
	log_info "Update: curl -fsSL $raw/install.sh | bash"
	log_info 'Or: cd ~/dotfiles && git pull && chezmoi apply'
	log_info 'Check drift: chezmoi status (or ~/.local/bin/chezmoi status before opening a new shell).'
	log_info 'Backups: ~/dotfleet-backups/<timestamp>/; MANIFEST records saved and absent paths and symlink targets.'
	# shellcheck disable=SC2016 # Print a command for the user to run later.
	log_info 'Roll back: review MANIFEST. Restore external/ targets to their recorded paths.'
	# shellcheck disable=SC2016 # Print a command for the user to run later.
	log_info 'Then run: cp -a BACKUP/home/. "$HOME/". Remove only newly created files marked absent.'
	log_info 'Do not apply again until ready.'
	log_info "Docs: $source_path/README.md and $source_path/docs/DESIGN.md"
	[[ -z $work_dir ]] || rm -rf -- "$work_dir"
	exit "$result"
}

is_this_repo() {
	local origin
	# Do not mistake an ordinary directory inside another checkout for a clone.
	[[ -e $1/.git ]] || return 1
	origin=$(git -C "$1" config --get remote.origin.url 2>/dev/null) || return 1
	case $origin in
	https://github.com/jeremyspofford/dotfiles | https://github.com/jeremyspofford/dotfiles.git | git@github.com:jeremyspofford/dotfiles.git | ssh://git@github.com/jeremyspofford/dotfiles.git) return 0 ;;
	*) return 1 ;;
	esac
}

require_clean_clone() {
	[[ -z $(git -C "$1" status --porcelain) ]] || error_exit "Checkout has local changes; preserve them before updating: $1"
}

# Resolve a file's symlink chain and physical parent without GNU-only readlink -f.
resolved_path() {
	local path=$1 target hops=0
	while [[ -L $path ]]; do
		((hops += 1))
		[[ $hops -le 40 ]] || return 1
		target=$(readlink "$path")
		case $target in
		/*) path=$target ;;
		*) path="$(dirname -- "$path")/$target" ;;
		esac
	done
	(cd -P -- "$(dirname -- "$path")" && printf '%s/%s\n' "$PWD" "$(basename -- "$path")")
}

backup_entry() {
	local relative=$1 path="$HOME/$1" resolved target
	if [[ ! -e $path && ! -L $path ]]; then
		printf 'absent\t%q\n' "$relative" >>"$backup_path/MANIFEST"
		return
	fi
	mkdir -p -- "$backup_path/home/$(dirname -- "$relative")"
	cp -pPR -- "$path" "$backup_path/home/$relative"
	printf 'saved\t%q\n' "$relative" >>"$backup_path/MANIFEST"
	if [[ -L $path ]]; then
		target=$(readlink "$path")
		printf 'symlink\t%q\t-> %q\n' "$relative" "$target" >>"$backup_path/MANIFEST"
	fi
	# Physical resolution also catches a symlink in a parent directory.
	if [[ -f $path ]]; then
		resolved=$(resolved_path "$path") || error_exit "Cannot resolve backup target: $path"
		case $resolved in
		"$physical_home"/*) ;;
		*)
			mkdir -p -- "$backup_path/external/$(dirname -- "${resolved#/}")"
			cp -pL -- "$path" "$backup_path/external/${resolved#/}"
			printf 'external\t%q\t-> %q\n' "$relative" "$resolved" >>"$backup_path/MANIFEST"
			;;
		esac
	fi
}

main() {
	# A piped standalone script has no adjacent logger yet. Load the canonical
	# logger before emitting messages; curl's own diagnostics cover download
	# failure. The shell itself reports a missing curl before a logger exists.
	local logger_path='' os local_clone='' config_path inventory_tool relative stamp suffix origin migrated=0
	if [[ -n $script_dir && -r $script_dir/scripts/logger.sh ]]; then
		logger_path="$script_dir/scripts/logger.sh"
	elif command -v git >/dev/null && is_this_repo "$source_path" && [[ -r $source_path/scripts/logger.sh ]]; then
		logger_path="$source_path/scripts/logger.sh"
	fi
	if [[ -z $logger_path ]]; then
		if ! command -v curl >/dev/null; then
			unset missing_curl
			: "${missing_curl:?Missing prerequisite: curl. Install curl and re-run install.sh.}"
		fi
		work_dir=$(mktemp -d)
		trap 'rm -rf -- "$work_dir"' EXIT
		mkdir -p "$work_dir/scripts"
		curl -fsSL "$raw/scripts/logger.sh" -o "$work_dir/scripts/logger.sh"
		curl -fsSL "$raw/VERSION" -o "$work_dir/VERSION"
		logger_path="$work_dir/scripts/logger.sh"
	fi
	# shellcheck source=scripts/logger.sh
	source "$logger_path"
	trap finish EXIT
	require_commands git curl tar
	case $(uname -s) in
	Linux)
		os=Linux
		if [[ -n ${WSL_DISTRO_NAME:-} ]] || [[ $(uname -r) == *[Mm]icrosoft* ]]; then os=WSL; fi
		;;
	Darwin) os=macOS ;;
	*) error_exit 'Supported hosts: Linux, macOS or WSL.' ;;
	esac
	log_info "Host: $os / $(uname -m)"
	export PATH="$HOME/.local/bin:$PATH"
	umask 077
	[[ -n $work_dir ]] || work_dir=$(mktemp -d)
	physical_home=$(cd -P -- "$HOME" && pwd)

	# Check the visible destination before touching the old checkout or home.
	if [[ -e $source_path || -L $source_path ]]; then
		[[ ! -L $source_path ]] || error_exit "Source must not be a symlink: $source_path"
		is_this_repo "$source_path" || error_exit "Cannot install: $source_path already exists and is not this repository's clone. Nothing was changed; move it aside yourself before retrying."
	elif [[ -e $legacy_source_path || -L $legacy_source_path ]] && is_this_repo "$legacy_source_path"; then
		[[ ! -L $legacy_source_path && -d $legacy_source_path/.git ]] || error_exit 'The previous checkout must be a directory clone, not a symlink or linked worktree.'
		require_clean_clone "$legacy_source_path"
		[[ $(git -C "$legacy_source_path" branch --show-current) == main ]] || error_exit 'The previous checkout must be on main before migration.'
		# Finish network/fast-forward checks before moving the active checkout.
		log_info 'Updating your existing checkout before moving it to ~/dotfiles'
		git -C "$legacy_source_path" pull --ff-only origin main </dev/null
		log_info 'Moving your existing dotfiles checkout to ~/dotfiles'
		mv -- "$legacy_source_path" "$source_path"
		migrated=1
	fi

	if [[ -e $source_path ]]; then
		require_clean_clone "$source_path"
		[[ $(git -C "$source_path" branch --show-current) == main ]] || error_exit 'The ~/dotfiles checkout must be on main before updating.'
		if [[ $migrated == 0 ]]; then
			log_info 'Updating ~/dotfiles from GitHub'
			git -C "$source_path" pull --ff-only origin main </dev/null
		fi
	else
		if [[ -n $script_dir ]] && is_this_repo "$script_dir"; then
			local_clone=$(git -C "$script_dir" rev-parse --show-toplevel)
		else
			local_clone=$(git rev-parse --show-toplevel 2>/dev/null) || local_clone=''
			if [[ -n $local_clone ]] && ! is_this_repo "$local_clone"; then local_clone=''; fi
		fi
		mkdir -p -- "$(dirname -- "$source_path")"
		if [[ -n $local_clone ]]; then
			require_clean_clone "$local_clone"
			log_info "Creating ~/dotfiles from $local_clone"
			git clone --no-hardlinks -- "$local_clone" "$source_path" </dev/null
			git -C "$source_path" remote set-url origin "$repo"
			# Keep the supplied committed tree; subsequent runs update from main.
			git -C "$source_path" checkout -B main
			git -C "$source_path" config branch.main.remote origin
			git -C "$source_path" config branch.main.merge refs/heads/main
		else
			log_info 'Cloning your dotfiles into ~/dotfiles'
			git clone --branch main -- "$repo" "$source_path" </dev/null
		fi
	fi
	source_commit=$(git -C "$source_path" rev-parse HEAD)

	# Inventory needs chezmoi, but no home files or tools are installed yet.
	# Use the official OS/architecture-selecting binary installer in a temp dir.
	if command -v chezmoi >/dev/null; then
		inventory_tool=$(command -v chezmoi)
	else
		log_info 'Downloading temporary chezmoi for backup inventory'
		curl -fsSL https://get.chezmoi.io -o "$work_dir/chezmoi-install"
		sh "$work_dir/chezmoi-install" -b "$work_dir/bin" </dev/null
		inventory_tool="$work_dir/bin/chezmoi"
	fi
	"$inventory_tool" --source "$source_path" --destination "$HOME" managed --include files,symlinks --path-style relative -0 >"$work_dir/managed"
	mkdir -p "$HOME/dotfleet-backups"
	stamp=$(date +%Y%m%d-%H%M%S)
	backup_path="$HOME/dotfleet-backups/$stamp"
	suffix=0
	while ! mkdir -- "$backup_path"; do
		[[ -d $backup_path ]] || error_exit "Cannot create backup: $backup_path"
		((suffix += 1))
		backup_path="$HOME/dotfleet-backups/$stamp-$suffix"
	done
	mkdir "$backup_path/home"
	log_info "Backup: $backup_path"
	while IFS= read -r -d '' relative; do
		case $relative in
		/* | .. | ../* | */../*) error_exit "Unsafe managed path: $relative" ;;
		esac
		backup_entry "$relative"
	done <"$work_dir/managed"
	config_path="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi"
	# Bootstrap also regenerates its local config; preserve it before init.
	case $config_path in
	"$HOME"/*) backup_entry "${config_path#"$HOME"/}" ;;
	*) error_exit 'XDG_CONFIG_HOME must be inside HOME for enrollment backups.' ;;
	esac

	mkdir -p "$HOME/.local/bin"
	if ! command -v chezmoi >/dev/null; then
		cp "$inventory_tool" "$HOME/.local/bin/chezmoi"
		chmod 755 "$HOME/.local/bin/chezmoi"
	fi
	if ! command -v mise >/dev/null; then
		log_info 'Installing Mise into ~/.local/bin'
		curl -fsSL https://mise.run -o "$work_dir/mise-install"
		MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh "$work_dir/mise-install" </dev/null
	fi
	origin=$(git -C "$source_path" config --get remote.origin.url)
	local bootstrap=(bash "$source_path/scripts/bootstrap.sh" --source "$source_path" --repo "$origin")
	if [[ $defaults == 0 ]]; then bootstrap+=(--interactive); fi
	# Bootstrap owns domain/identity initialization and validated apply.
	"${bootstrap[@]}" </dev/null
	mise_pins_result=$(chezmoi execute-template '{{ if .miseTools }}{{ .miseTools | toJson }}{{ else }}none{{ end }} (initial source: {{ .misePinsSource }})')
	if ! chezmoi status >"$work_dir/status"; then
		status_result='FAILED (status command failed)'
		error_exit 'Cannot check chezmoi status.'
	elif [[ -s $work_dir/status ]]; then
		status_result='DRIFT (managed paths differ)'
		log_heredoc '' <"$work_dir/status"
		error_exit 'Installation completed with drift; inspect chezmoi status.'
	fi
	status_result='CLEAN (no differences)'
}
# All definitions are parsed before execution, including when stdin is the script.
main
