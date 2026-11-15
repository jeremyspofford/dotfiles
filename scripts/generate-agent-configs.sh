#!/usr/bin/env bash
# Purpose: Write settings and skill links for installed coding agents.
# A skill is a folder of agent instructions. The manifest lists settings and paths.
# Usage: bash scripts/generate-agent-configs.sh [OPTIONS]
# Parameters: --dry-run lists changes without writing; --home PATH selects a full home path.
# --os selects linux (Linux), darwin (macOS), windows (Windows), or wsl (Windows Subsystem for Linux).
# -h and --help print full help.
# Examples: bash scripts/generate-agent-configs.sh --dry-run
# Exit codes: 0 success/help; 1 runtime failure or conflict; 2 invalid arguments.
# Author: Jeremy Spofford / Aria Labs; Version: read from ../VERSION at runtime.
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/logger.sh
source "$SCRIPT_DIR/logger.sh"
usage() {
	cat <<EOF
generate-agent-configs.sh — configure installed coding agents ($DOTFILES_VERSION)
Usage: bash scripts/generate-agent-configs.sh [OPTIONS]

An agent is a coding assistant. A skill is a folder of agent instructions.
The manifest, agents/manifest.toml, lists settings and paths.
Find agent commands on PATH, the command search path. Write their settings and links to agents/skills.
Refuse files the generator does not own. Keep this checkout at a stable path.
Requires Python 3.11+.

Options:
  --dry-run     Validate and report proposed paths without writing.
  --home PATH   Full target home path; default: the current user's home.
  --os OS       Select linux (Linux), darwin (macOS), windows (Windows),
                or wsl (Windows Subsystem for Linux); default: detected system.
  -h, --help    Print full help and exit 0.

Examples:
  bash scripts/generate-agent-configs.sh --dry-run
  bash scripts/generate-agent-configs.sh --home /tmp/demo --os linux

Outputs are recorded in ~/.local/state/dotfiles/agents.json.
Ollama has no portable settings-file or skill contract. Report it without writing files.
Exit codes: 0 success/help; 1 runtime failure or conflict; 2 invalid arguments.
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
