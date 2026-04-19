#!/usr/bin/env bash
# auto-ingest.sh — triggered by hooks to process pending raw/ files
#
# Called by: SessionStart, PostCompact, SubagentStop (scout)
# Safe to call concurrently — lock file prevents double-processing
# Exits quickly — ingest runs in background so hooks return fast

WIKI_VAULT="${WIKI_VAULT:-$HOME/Obsidian_Vault}"
LOCK_FILE="$WIKI_VAULT/.ingest.lock"
LOG_FILE="/tmp/auto-ingest.log"

# No vault — no-op
[ -d "$WIKI_VAULT" ] || exit 0

# Already locked — another ingest is running
[ -f "$LOCK_FILE" ] && exit 0

# Check for pending files
PENDING=$(grep -rl "^ingested: false" "$WIKI_VAULT/raw/" --include="*.md" 2>/dev/null | wc -l | tr -d ' ')
[ "$PENDING" -eq 0 ] && exit 0

# Find claude binary — works in cron (no PATH inheritance)
CLAUDE_BIN=$(command -v claude 2>/dev/null || echo "$HOME/.local/bin/claude")
[ -x "$CLAUDE_BIN" ] || exit 0

# Acquire lock — background subshell releases on exit
touch "$LOCK_FILE"

(
  trap "rm -f '$LOCK_FILE'" EXIT

  "$CLAUDE_BIN" \
    --print "Read $WIKI_VAULT/CLAUDE.md then run auto-ingest: process all markdown files with 'ingested: false' frontmatter in $WIKI_VAULT/raw/ per the Auto-ingest rules. No user interaction needed — use judgment throughout. Update wiki pages, move raw files to archive/, flip ingested flags when done." \
    --dangerously-skip-permissions \
    --model sonnet \
    --add-dir "$WIKI_VAULT" \
    >> "$LOG_FILE" 2>&1
) &

# Disown so the background process survives hook exit
disown $!

exit 0
