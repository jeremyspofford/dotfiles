#!/usr/bin/env bash
# Purpose: Run release-please while restricting automatic versions to 0.x.
# Release-please proposes and publishes releases. Only the owner can authorize 1.0.0.
# Usage: bash scripts/release.sh [--dry-run] [-h|--help]
# Parameters: --dry-run prevents GitHub writes; -h/--help prints full help.
# GITHUB_TOKEN grants content and pull-request write access.
# GITHUB_REPOSITORY selects owner/repo. A pull request proposes a repository change.
# Examples: bash scripts/release.sh --dry-run
# Exit codes: 0 success/help; 1 policy or GitHub API failure; 2 invalid arguments.
# The API is GitHub's programming interface.
# Author: Jeremy Spofford / Aria Labs; Version: read from ../VERSION at runtime.
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/logger.sh
source "$SCRIPT_DIR/logger.sh"
usage() {
	cat <<EOF
release.sh — propose and publish releases with release-please ($DOTFILES_VERSION)
Usage: bash scripts/release.sh [--dry-run] [-h|--help]

Parameters:
  --dry-run   Build release proposals without writing to GitHub.
  -h, --help  Print full help and exit 0.

Environment:
  GITHUB_TOKEN       Token with content and pull-request write access.
  GITHUB_REPOSITORY  Repository name in owner/repo form.
A pull request proposes a repository change.
Requires Node.js, the JavaScript runtime, and npm dependencies from package.json.
npm installs the build packages. Run npm install --ignore-scripts first.
--ignore-scripts prevents dependency install scripts from running.
Reject automatic nonzero major versions, including 1.x, and all Release-As overrides.
The major is the first version number. Release-As requests a forced version.
Example: bash scripts/release.sh --dry-run
Exit codes: 0 success/help; 1 policy or GitHub API failure; 2 invalid arguments.
The API is GitHub's programming interface.
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
