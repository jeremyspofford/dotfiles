#!/usr/bin/env bash
# init-daily-log.sh — create today's daily memory log skeleton if it doesn't exist
#
# Called by: SessionStart
# Guarantees Assistant/memory/YYYY-MM-DD.md exists before Claude starts,
# so the session has somewhere to write even if Claude forgets to create it.

WIKI_VAULT="${WIKI_VAULT:-$HOME/Obsidian_Vault}"
DATE=$(date +%Y-%m-%d)
LOG_FILE="$WIKI_VAULT/Assistant/memory/$DATE.md"

[ -d "$WIKI_VAULT/Assistant/memory" ] || exit 0
[ -f "$LOG_FILE" ] && exit 0

cat > "$LOG_FILE" <<EOF
---
date: $DATE
ingested: false
---

# $DATE
EOF

exit 0
