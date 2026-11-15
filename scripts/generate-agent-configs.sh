#!/usr/bin/env bash
# Purpose: Generate native configs and skill links for installed manifest agents.
# Usage: bash scripts/generate-agent-configs.sh [OPTIONS]
# Parameters: --dry-run, --home PATH, --os linux|darwin|windows|wsl, -h, --help.
# Examples: bash scripts/generate-agent-configs.sh --dry-run
# Exit codes: 0 success/help; 1 runtime/conflict; 2 invalid arguments.
# Author: Jeremy Spofford / Aria Labs; Version: read from ../VERSION at runtime.
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/logger.sh
source "$SCRIPT_DIR/logger.sh"
usage() {
	cat <<EOF
generate-agent-configs.sh — configure installed agents ($DOTFILES_VERSION)
Usage: bash scripts/generate-agent-configs.sh [OPTIONS]
Reads agents/manifest.toml; detects commands on PATH; creates native configs and
per-skill links to agents/skills. Refuses unmanaged conflicts. Python 3.11+ required.
Keep this checkout at a stable path.
Options:
  --dry-run     Validate/report proposed paths without writing.
  --home PATH   Absolute target home (default: current user's home).
  --os OS       linux, darwin, windows, wsl (default: detected platform).
  -h, --help    Print full help and exit 0.
Examples:
  bash scripts/generate-agent-configs.sh --dry-run
  bash scripts/generate-agent-configs.sh --home /tmp/demo --os linux
Outputs are listed in ~/.local/state/dotfiles/agents.json.
Ollama has no native skills/config-file contract and is reported without writing.
Exit codes: 0 success/help; 1 runtime/conflict; 2 invalid arguments.
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
	--home | --os)
		if [[ $# -lt 2 || -z $2 || $2 == --* ]]; then
			log_error "Missing value for $1"
			usage >&2
			exit 2
		fi
		args+=("$1" "$2")
		shift 2
		;;
	*)
		log_error "Unknown argument: $1"
		usage >&2
		exit 2
		;;
	esac
done
if ! command -v python3 >/dev/null; then
	log_error "Python 3.11+ required."
	exit 1
fi
python3 "$SCRIPT_DIR/agent_configs.py" "${args[@]}" 2>&1 | while IFS= read -r line; do
	log_info "$line"
done
