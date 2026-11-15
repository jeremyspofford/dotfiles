#!/usr/bin/env bash
# Purpose: Provide shared shell logging and small command/path helpers.
# Usage: source "$(dirname "$0")/logger.sh"; an absolute path also works.
#        bash scripts/logger.sh --help
# Sourcing defines functions, colors, and DOTFILES_VERSION. It preserves shell options.
# Call set_strict yourself to enable strict error handling.
# Parameters: -h/--help prints help when executed; other arguments are invalid.
# Examples: log_info "Starting deploy"; log_success "Deploy finished"
#           log_warning "Config missing; using defaults"; log_error "Deploy failed"
#           log_debug "Cache dir: ${cache_dir}"; log_section "Phase 2"
#           log_kv "Environment" "production"; require_commands git curl jq
#           error_exit "Something broke" 3
#
# Functions and output:
# log_info msg...: blue progress; log_success msg...: green success. Both use stdout.
# log_warning msg...: yellow warnings on stderr. log_warn is the same interface.
# log_error msg...: red errors on stderr.
# log_debug msg...: magenta stderr output when DEBUG=1 or DOTFILES_DEBUG=1.
# stdout is normal output; stderr is diagnostic output.
# log_section msg...: cyan bold banner on stdout.
# log_kv key value: aligned "Key: Value" output on stdout.
# log_heredoc COLOR: read stdin and print each line in that color.
# stdin is input. Color variables are RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN,
# BOLD (bold text), and CLEAR (reset formatting).
# error_exit msg [code]: log an error and exit; default code is 1.
# command_exists cmd: return 0 when PATH, the command search path, contains cmd.
# require_commands ...: list missing commands and exit through error_exit.
# get_repo_dir: print the Git root; return 1 without output outside a repository.
# set_strict: enable set -euo pipefail in the caller.
# Strict mode stops on failed commands, unset variables, and failed pipeline commands.
# set_verbose: enable set -x command tracing for debugging. set_quiet: disable tracing.
#
# Environment:
# NO_COLOR: a nonempty value disables colors. Nonterminal output also disables colors.
# The original header promised any set value; this implementation treats empty as unset.
# LOG_TIMESTAMP=1: prefix log lines with [HH:MM:SS].
# DEBUG=1 or DOTFILES_DEBUG=1: enable debug lines.
#
# Compared with Jeremy's deployment logger, printf replaces echo -e.
# Messages cannot become printf format flags. Warnings, errors, and debug use stderr.
# log_warn/log_debug complete the Dotfleet logging interface; timestamps are optional.
# The original header references logger.orig.sh; this checkout does not contain it.
# Exit codes when executed: 0 help; 2 invalid or missing arguments.
# Author: Jeremy Spofford / Aria Labs (original), Muse (improvements).
# Version: read from ../VERSION at runtime; use "unknown" if unavailable.

# Guard against being sourced twice.
if [[ -n "${_LOGGER_SH_LOADED:-}" ]]; then
	# shellcheck disable=SC2317  # reachable when sourced, which is the point
	return 0 2>/dev/null || true
fi
_LOGGER_SH_LOADED=1
# --- Version --------------------------------------------------------------------
# Scripts print DOTFILES_VERSION in their --help output. Read it from the
# VERSION file next to this script's parent directory; fall back to
# "unknown" so sourcing this file never fails under `set -u`.
_LOGGER_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -r "${_LOGGER_DIR}/../VERSION" ]]; then
	DOTFILES_VERSION="$(cat "${_LOGGER_DIR}/../VERSION")"
else
	DOTFILES_VERSION="unknown"
fi
export DOTFILES_VERSION
unset _LOGGER_DIR

# --- Colors -------------------------------------------------------------------
# Enabled only on a real terminal and only when NO_COLOR is unset.
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
	RED=$'\033[31m'
	GREEN=$'\033[32m'
	YELLOW=$'\033[33m'
	BLUE=$'\033[34m'
	MAGENTA=$'\033[35m'
	CYAN=$'\033[36m'
	BOLD=$'\033[1m'
	CLEAR=$'\033[0m'
else
	RED=''
	GREEN=''
	YELLOW=''
	BLUE=''
	MAGENTA=''
	CYAN=''
	BOLD=''
	CLEAR=''
fi
export RED GREEN YELLOW BLUE MAGENTA CYAN BOLD CLEAR

# --- Internal -----------------------------------------------------------------
# _log_line COLOR MESSAGE...
#   Prints MESSAGE in COLOR on one line, with an optional timestamp.
#   Destination (stdout vs stderr) is chosen by the caller via redirection
#   on the log_* function call itself.
_log_line() {
	local color="$1"
	shift
	local prefix=''
	if [[ "${LOG_TIMESTAMP:-0}" == "1" ]]; then
		prefix="[$(date +%H:%M:%S)] "
	fi
	printf '%b%s%s%b\n' "${color}" "${prefix}" "$*" "${CLEAR}"
}

# --- Logging functions ----------------------------------------------------------
log_info() {
	_log_line "${BLUE}" "$*"
}

log_success() {
	_log_line "${GREEN}" "$*"
}

log_warning() {
	_log_line "${YELLOW}" "$*" >&2
}

# Dotfleet interface name; same function as log_warning.
log_warn() {
	log_warning "$@"
}

log_error() {
	_log_line "${RED}" "$*" >&2
}

log_debug() {
	if [[ "${DEBUG:-0}" == "1" || "${DOTFILES_DEBUG:-0}" == "1" ]]; then
		_log_line "${MAGENTA}" "$*" >&2
	fi
}

log_section() {
	local bar='━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
	printf '%b%s%b\n' "${CYAN}${BOLD}" "${bar}" "${CLEAR}"
	printf '%b  %s%b\n' "${CYAN}${BOLD}" "$*" "${CLEAR}"
	printf '%b%s%b\n' "${CYAN}${BOLD}" "${bar}" "${CLEAR}"
}

log_kv() {
	# Logs a key-value pair with color formatting.
	#
	# Arguments:
	#   $1  The key
	#   $2  The value
	#
	# Example:
	#   log_kv "Key" "Value"
	#
	# Output:
	#   (blue) Key:    (reset) Value
	local key="${1:-}"
	local value="${2:-}"
	printf '%b%-30s%b %s\n' "${BLUE}" "${key}:" "${CLEAR}" "${value}"
}

log_heredoc() {
	# Logs a heredoc string with color formatting.
	#
	# Arguments:
	#   $1  The color code to use (e.g. ${GREEN})
	#   stdin  The heredoc content to log
	#
	# Example:
	#   show_help() {
	#       log_heredoc "${GREEN}" <<EOF
	#       This is some
	#       multi-line text
	#       that will be green
	#       EOF
	#   }
	local level="${1:-}"
	local line
	while IFS= read -r line; do
		printf '%b%s%b\n' "${level}" "${line}" "${CLEAR}"
	done
}

# --- Error handling -------------------------------------------------------------
error_exit() {
	log_error "$1"
	exit "${2:-1}"
}

# --- Helpers ----------------------------------------------------------------------
# Check if command exists.
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Validate required commands; exits listing any that are missing.
require_commands() {
	local missing=''
	local cmd
	for cmd in "$@"; do
		if ! command_exists "${cmd}"; then
			missing="${missing}${missing:+ }${cmd}"
		fi
	done

	if [[ -n "${missing}" ]]; then
		error_exit "Missing required commands: ${missing}"
	fi
}

# Print the root of the current git repository.
# Returns 1 (and prints nothing) when not inside a repo.
get_repo_dir() {
	git rev-parse --show-toplevel 2>/dev/null || return 1
}

# Set strict error handling in the calling script:
# exit on error | undefined variable | pipe failure.
set_strict() {
	set -euo pipefail
}

# Show commands as they run (shell trace; debugging).
set_verbose() {
	set -x
}

# Hide commands (clean output).
set_quiet() {
	set +x
}

# CLI handling runs only when executed, never when sourced by another script.
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
	set_strict
	usage() {
		cat <<EOF
logger.sh — shared shell logging
Usage: source scripts/logger.sh
       bash scripts/logger.sh --help

Source this file to load functions and colors without changing your shell options.
It reads DOTFILES_VERSION from the repository VERSION file; the fallback is unknown.
stdout carries normal output; stderr carries diagnostics; stdin supplies input.

Parameters:
  -h, --help  Print full help and exit 0.
  No other command-line arguments are accepted.

Functions:
  log_info MESSAGE...       Blue progress on stdout.
  log_success MESSAGE...    Green success on stdout.
  log_warning MESSAGE...    Yellow warning on stderr; log_warn is an alias.
  log_error MESSAGE...      Red error on stderr.
  log_debug MESSAGE...      Magenta stderr output when debugging is enabled.
  log_section MESSAGE...    Cyan bold banner on stdout.
  log_kv KEY VALUE          Aligned key/value output on stdout.
  log_heredoc COLOR         Read stdin lines and print them in COLOR.
  error_exit MESSAGE [CODE] Log an error and exit; default code: 1.
  command_exists COMMAND   Return 0 if PATH, the command search path, contains COMMAND.
  require_commands CMD...  List missing commands and exit 1 if any are missing.
  get_repo_dir             Print the Git root; return 1 without output outside a repository.
  set_strict               Enable set -euo pipefail in the caller.
  set_verbose              Enable set -x command tracing for debugging.
  set_quiet                Disable command tracing.
Color variables: RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, BOLD, CLEAR.
BOLD enables bold text. CLEAR resets formatting.
Strict mode stops on failed commands, unset variables, and failed pipeline commands.

Environment:
  DEBUG=1 or DOTFILES_DEBUG=1  Enable debug messages.
  LOG_TIMESTAMP=1             Prefix log lines with [HH:MM:SS].
  NO_COLOR=1                  Disable colors; any nonempty value works.
Nonterminal output disables colors automatically.

Examples:
  source scripts/logger.sh
  log_info "Starting setup"
  log_warn "Optional configuration missing"
  require_commands git curl
  DOTFILES_DEBUG=1 log_debug "Checking configuration"

Exit codes: 0 help; 2 invalid or missing arguments.
Author: Jeremy Spofford / Aria Labs (original), Muse (improvements).
Version: $DOTFILES_VERSION (VERSION).
EOF
	}
	if [[ $# == 1 && ($1 == --help || $1 == -h) ]]; then
		usage
		exit 0
	fi
	log_error "Source logger.sh for its functions, or run it with --help."
	usage >&2
	exit 2
fi
