#!/usr/bin/env bash
# post-bash.sh — PostToolUse hook for Bash
#
# Detects `git commit` / `git push` commands and appends a capture entry
# to the per-slug raw file at $WIKI_VAULT/raw/<slug>/YYYY-MM-DD-session.md.
#
# Uses modern stdin-JSON hook protocol:
#   { "tool_name": "Bash", "tool_input": {"command": "..."}, "cwd": "..." }

set -uo pipefail

# Source helpers
# shellcheck disable=SC1090
source "$HOME/.claude/hooks/ignore-patterns.sh"
# shellcheck disable=SC1090
source "$HOME/.claude/hooks/resolve-project-path.sh"

# Ensure WIKI_VAULT is set — non-interactive shells won't have it
if [[ -z "${WIKI_VAULT:-}" ]] && [[ -f "$HOME/.commonrc" ]]; then
    # shellcheck disable=SC1090
    source "$HOME/.commonrc" 2>/dev/null
fi

# Read hook JSON from stdin
HOOK_INPUT=""
if [ ! -t 0 ]; then
    HOOK_INPUT=$(cat)
fi

# Parse command + cwd via python3 (robust against quoting)
parse_field() {
    local path="$1"
    local json="$2"
    [ -z "$json" ] && { echo ""; return; }
    command -v python3 >/dev/null 2>&1 || { echo ""; return; }
    echo "$json" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    # Support dotted path like 'tool_input.command'
    for key in '$path'.split('.'):
        d = d.get(key, '') if isinstance(d, dict) else ''
    print(d if isinstance(d, str) else '')
except Exception:
    print('')
" 2>/dev/null
}

CMD=$(parse_field tool_input.command "$HOOK_INPUT")
CWD=$(parse_field cwd "$HOOK_INPUT")

# Fallbacks if JSON didn't provide cwd
: "${CWD:=${CLAUDE_PROJECT_DIR:-$PWD}}"

# Only fire for git commit / git push
if ! echo "$CMD" | grep -qE "^git (commit|push)"; then
    exit 0
fi

# No vault → nothing to write
if [[ -z "${WIKI_VAULT:-}" ]]; then
    exit 0
fi

# Resolve wiki slug (returns empty if opted-out or ignored)
SLUG=$(get_wiki_slug "$CWD")
if [[ -z "$SLUG" ]]; then
    exit 0
fi

# Grab commit message for context (first 5 lines of the HEAD commit)
COMMIT_MSG=$(git -C "$CWD" log -1 --pretty=%B 2>/dev/null | head -5)
TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)
DATE=$(date +%Y-%m-%d)
RAW_DIR="$WIKI_VAULT/raw/$SLUG"
RAW_FILE="$RAW_DIR/${DATE}-session.md"

mkdir -p "$RAW_DIR"

# Create frontmatter on first write of the day
if [[ ! -f "$RAW_FILE" ]]; then
    cat > "$RAW_FILE" << EOF
---
source_project: $SLUG
captured_date: $DATE
session_context: "auto-captured from git activity"
ingested: false
---

EOF
fi

# Append the capture entry
cat >> "$RAW_FILE" << EOF

## [$TIMESTAMP] git commit captured

**Commit message:** $COMMIT_MSG

**Trigger:** post-bash hook on git commit/push
**Repo path:** $CWD

<!-- Claude: on next /wiki ingest, summarize what this commit accomplished,
     what problem it solved, any patterns or decisions worth preserving -->

EOF

exit 0
