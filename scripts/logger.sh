#!/usr/bin/env bash
# Purpose: INTERFACE STUB ONLY. The owner's real logger.sh will replace this
# file without changing call sites: log_info, log_warn, log_error, log_debug.
# Usage: source scripts/logger.sh; log_info MESSAGE
# Parameters: MESSAGE... for functions; -h/--help when executed.
# Examples: source scripts/logger.sh; log_warn "Optional tool missing"
# Exit codes: 0 success/help; 2 invalid arguments.
# Author: Jeremy Spofford / Aria Labs; Version: read from ../VERSION at runtime.
set -euo pipefail
DOTFILES_VERSION=$(cat "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/VERSION")
export DOTFILES_VERSION
log_info() { printf '[INFO] %s\n' "$*" >&2; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }
log_debug() {
	if [[ ${DOTFILES_DEBUG:-0} == 1 ]]; then
		printf '[DEBUG] %s\n' "$*" >&2
	fi
}
usage() {
	cat <<EOF
logger.sh — replaceable logging interface ($DOTFILES_VERSION)
Usage: source scripts/logger.sh
       bash scripts/logger.sh --help
Functions: log_info MESSAGE..., log_warn MESSAGE..., log_error MESSAGE...,
           log_debug MESSAGE...
All messages go to stderr. DOTFILES_DEBUG=1 enables debug output.
Parameters: -h, --help  Print this help and exit 0.
Examples: source scripts/logger.sh; log_info "Ready"
Exit codes: 0 success/help; 2 invalid arguments.
Author: Jeremy Spofford / Aria Labs; Version: $DOTFILES_VERSION (VERSION).
EOF
}
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
	case ${1:-} in
	-h | --help) usage ;;
	*)
		log_error "Source this file, or use --help."
		usage >&2
		exit 2
		;;
	esac
fi
