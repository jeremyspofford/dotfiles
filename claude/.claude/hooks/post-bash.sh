#!/bin/bash
# post-bash.sh
# PostToolUse hook — fires after every Bash tool execution by Claude Code.
# Detects git commit/push and appends to the capture queue for the vault.

source ~/.claude/hooks/ignore-patterns.sh
source ~/.claude/hooks/resolve-project-path.sh

# If WIKI_VAULT isn't set (non-interactive shell), try sourcing commonrc
if [[ -z "$WIKI_VAULT" ]] && [[ -f "$HOME/.commonrc" ]]; then
    source "$HOME/.commonrc"
fi

# Only act on git commit or git push commands
if ! echo "$CLAUDE_TOOL_INPUT" | grep -qE "^git (commit|push)"; then
    exit 0
fi

# WIKI_VAULT must be set
if [[ -z "$WIKI_VAULT" ]]; then
    exit 0
fi

CWD="${CLAUDE_TOOL_CWD:-$PWD}"

# Resolve to wiki slug (returns empty if ignored or opted out)
SLUG=$(get_wiki_slug "$CWD")
if [[ -z "$SLUG" ]]; then
    exit 0
fi

# Get the git commit message for context
COMMIT_MSG=$(git -C "$CWD" log -1 --pretty=%B 2>/dev/null | head -5)
TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)
DATE=$(date +%Y-%m-%d)
RAW_DIR="$WIKI_VAULT/raw/$SLUG"
RAW_FILE="$RAW_DIR/${DATE}-session.md"

mkdir -p "$RAW_DIR"

# If file doesn't exist yet, write frontmatter header
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

# Append the git event as a capture entry
cat >> "$RAW_FILE" << EOF

## [$TIMESTAMP] git commit captured

**Commit message:** $COMMIT_MSG

**Trigger:** post-bash hook on git commit/push
**Repo path:** $CWD

<!-- Claude: on next /wiki ingest, summarize what this commit accomplished,
     what problem it solved, any patterns or decisions worth preserving -->

EOF
