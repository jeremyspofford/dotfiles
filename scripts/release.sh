#!/usr/bin/env bash
# Purpose: Run release-please with a fail-closed owner-only 1.0.0 gate.
# Usage: bash scripts/release.sh [--dry-run] [-h|--help]
# Parameters: --dry-run; GITHUB_TOKEN and GITHUB_REPOSITORY environment variables.
# Examples: bash scripts/release.sh --dry-run
# Exit codes: 0 success/help; 1 policy/API failure; 2 invalid arguments.
# Author: Jeremy Spofford / Aria Labs; Version: read from ../VERSION at runtime.
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/logger.sh
source "$SCRIPT_DIR/logger.sh"
usage() {
	cat <<EOF
release.sh — guarded release-please ($DOTFILES_VERSION)
Usage: bash scripts/release.sh [--dry-run] [-h|--help]
Parameters:
  --dry-run    Build release proposals without writing to GitHub.
  -h, --help   Print this help and exit 0.
Environment: GITHUB_TOKEN (contents/PR write); GITHUB_REPOSITORY (owner/repo).
Requires Node.js and npm dependencies installed from package.json.
Rejects all automatic 1.x proposals and all Release-As overrides.
Example: bash scripts/release.sh --dry-run
Exit codes: 0 success/help; 1 policy/API failure; 2 invalid arguments.
Author: Jeremy Spofford / Aria Labs; Version: $DOTFILES_VERSION (VERSION).
EOF
}
args=()
while (($#)); do
	case $1 in
	-h | --help)
		usage
		exit 0
		;;
	--dry-run)
		args+=("$1")
		shift
		;;
	*)
		log_error "Unknown argument: $1"
		usage >&2
		exit 2
		;;
	esac
done
cd "$SCRIPT_DIR/.."
node scripts/release.cjs "${args[@]}" 2>&1 | while IFS= read -r line; do
	log_info "$line"
done
