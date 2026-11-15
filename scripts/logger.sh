#!/usr/bin/env bash
# =============================================================================
# logger.sh — common logger for shell scripts
#
# Purpose:
#   Source this file in your scripts to get consistent, colored log output
#   plus small shared helpers (command checks, strict mode, repo root).
#
# Usage:
#   source "$(dirname "$0")/logger.sh"        # or an absolute path
#   log_info "Starting deploy"
#   log_success "Deploy finished"
#   log_warning "Config not found, using defaults"
#   log_error "Deploy failed"
#   log_debug "Cache dir: ${cache_dir}"       # only prints when debugging
#   log_section "Phase 2"
#   log_kv "Environment" "production"
#   require_commands git curl jq
#   error_exit "Something broke" 3
#
# Functions:
#   log_info msg...        Blue.   General progress (stdout).
#   log_success msg...     Green.  Completed steps (stdout).
#   log_warning msg...     Yellow. Warnings (stderr). Alias: log_warn.
#   log_error msg...       Red.    Errors (stderr).
#   log_debug msg...       Magenta. Only when DEBUG=1 or DOTFILES_DEBUG=1 (stderr).
#   log_section msg...     Cyan bold banner (stdout).
#   log_kv key value       Aligned "Key:  Value" line (stdout).
#   log_heredoc COLOR      Reads stdin, prints each line in COLOR.
#   error_exit msg [code]  log_error + exit (default code 1).
#   command_exists cmd     Returns 0 if cmd is on PATH.
#   require_commands ...   error_exit listing any missing commands.
#   get_repo_dir           Prints the git repo root; returns 1 outside a repo.
#   set_strict             set -euo pipefail in the calling script.
#   set_verbose            set -x (shell trace) — debugging only.
#   set_quiet              set +x.
#
# Environment:
#   NO_COLOR        If set (any value), colors are disabled. Colors are
#                   also disabled automatically when output is not a TTY,
#                   so CI logs stay clean.
#   LOG_TIMESTAMP   If 1, prefix each log line with [HH:MM:SS].
#   DEBUG / DOTFILES_DEBUG
#                   If 1, log_debug lines print.
#
# Notes:
#   - This file only DEFINES functions and color variables. It does not
#     change the calling script's shell options; call set_strict yourself.
#   - Improvements over the original (Jeremy's deployment logger, kept in
#     logger.orig.sh): printf instead of echo -e (portable, and message
#     text can never be read as format flags); colors auto-disable for
#     non-TTY output and NO_COLOR; log_warning/log_error/log_debug go to
#     stderr so stdout stays usable for real script output; added log_warn
#     and log_debug so the Dotfleet interface (log_info / log_warn /
#     log_error / log_debug) is fully covered; get_repo_dir fails cleanly
#     outside a git repo; optional timestamps.
#
# Author: Jeremy Spofford / Aria Labs (original), Muse (improvements)
# =============================================================================

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
