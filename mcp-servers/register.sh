#!/usr/bin/env bash
#
# register.sh — sync manifest.json into Claude Code's user-scope MCP config.
#
# The manifest is the declarative source of truth. On each run, this script
# makes ~/.claude.json's user-scope mcpServers converge exactly on the
# manifest:
#
#   - Servers in the manifest are (re-)registered.
#   - User-scope servers that are NOT in the manifest are unregistered.
#
# Corollary: any quick experiments via `claude mcp add --scope user ...`
# will be wiped on the next run. Use project scope (.mcp.json at a project
# root) for transient servers; promote to the manifest when they're keepers.
#
# Env placeholders in the manifest (e.g. $HOME) are expanded via envsubst
# at registration time.
#
# Usage:
#   ./register.sh [manifest.json]
#
# Dependencies: bash 4+, jq, envsubst (gettext), claude CLI.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${1:-$SCRIPT_DIR/manifest.json}"
CLAUDE_JSON="$HOME/.claude.json"

for dep in jq envsubst claude; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "register.sh: missing dependency: $dep" >&2
    exit 1
  fi
done

if [[ ! -f "$MANIFEST" ]]; then
  echo "register.sh: manifest not found: $MANIFEST" >&2
  exit 1
fi

expand() { printf '%s' "$1" | envsubst; }

# Manifest names (desired state)
mapfile -t manifest_names < <(jq -r '.mcpServers // {} | keys[]' "$MANIFEST")

# Current user-scope names (actual state). Missing file → empty list.
current_names=()
if [[ -f "$CLAUDE_JSON" ]]; then
  mapfile -t current_names < <(jq -r '.mcpServers // {} | keys[]' "$CLAUDE_JSON")
fi

# Set of manifest names for O(1) membership checks
declare -A manifest_set=()
if ((${#manifest_names[@]} > 0)); then
  for name in "${manifest_names[@]}"; do
    [[ -n "$name" ]] && manifest_set["$name"]=1
  done
fi

# 1. Unregister: user-scope servers not in the manifest
if ((${#current_names[@]} > 0)); then
  for name in "${current_names[@]}"; do
    [[ -z "$name" ]] && continue
    if [[ -z "${manifest_set[$name]:-}" ]]; then
      if claude mcp remove "$name" --scope user >/dev/null 2>&1; then
        echo "x  unregistered (not in manifest): $name"
      fi
    fi
  done
fi

# 2. Register: add-or-replace each server in the manifest
if ((${#manifest_names[@]} > 0)); then
  for name in "${manifest_names[@]}"; do
    [[ -z "$name" ]] && continue

    cmd_raw="$(jq -r --arg n "$name" '.mcpServers[$n].command' "$MANIFEST")"
    cmd="$(expand "$cmd_raw")"

    env_flags=()
    while IFS= read -r pair; do
      [[ -n "$pair" ]] && env_flags+=("-e" "$(expand "$pair")")
    done < <(jq -r --arg n "$name" '.mcpServers[$n].env // {} | to_entries[] | "\(.key)=\(.value)"' "$MANIFEST")

    args=()
    while IFS= read -r a; do
      args+=("$(expand "$a")")
    done < <(jq -r --arg n "$name" '.mcpServers[$n].args[]? // empty' "$MANIFEST")

    claude mcp remove "$name" --scope user >/dev/null 2>&1 || true

    echo "-> registered: $name"
    claude mcp add "$name" --scope user "${env_flags[@]}" -- "$cmd" "${args[@]}"
  done
fi

echo
echo "Done. Restart any running Claude Code sessions to pick up changes."
