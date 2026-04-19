#!/usr/bin/env bash
# run-scout.sh — runs the Scout agent (invoked by cron)
#
# Sources shell profile to pick up WIKI_VAULT and PATH since
# cron runs with a stripped environment.
# After Scout finishes, triggers auto-ingest on any new files.

LOG_FILE="/tmp/scout.log"

# Source environment — try commonrc first (Jeremy's standard), fall back to shell profiles
for profile in "$HOME/.commonrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc"; do
  if [ -f "$profile" ]; then
    # shellcheck disable=SC1090
    source "$profile" 2>/dev/null
    break
  fi
done

WIKI_VAULT="${WIKI_VAULT:-$HOME/Obsidian_Vault}"
CLAUDE_BIN=$(command -v claude 2>/dev/null || echo "$HOME/.local/bin/claude")

# Validate environment
if [ ! -x "$CLAUDE_BIN" ]; then
  echo "[$(date)] Error: claude not found at $CLAUDE_BIN" >> "$LOG_FILE"
  exit 1
fi

if [ ! -d "$WIKI_VAULT" ]; then
  echo "[$(date)] Error: WIKI_VAULT not found: $WIKI_VAULT" >> "$LOG_FILE"
  exit 1
fi

if [ ! -f "$WIKI_VAULT/Assistant/watchlist.md" ]; then
  echo "[$(date)] Error: Assistant/watchlist.md not found in $WIKI_VAULT" >> "$LOG_FILE"
  exit 1
fi

echo "[$(date)] Scout starting" >> "$LOG_FILE"

# Run Scout — not exec, so we can run auto-ingest after
"$CLAUDE_BIN" \
  --print "Read $HOME/.claude/agents/scout.md for your instructions. Then read $WIKI_VAULT/Assistant/watchlist.md to find all sources to fetch. Fetch content from each source and write new files to $WIKI_VAULT/raw/scout/. Skip any source that fails — log the error and continue to the next. When done, report how many files were written per source." \
  --dangerously-skip-permissions \
  --model sonnet \
  --add-dir "$WIKI_VAULT" \
  >> "$LOG_FILE" 2>&1

SCOUT_EXIT=$?
echo "[$(date)] Scout finished (exit: $SCOUT_EXIT)" >> "$LOG_FILE"

# Trigger ingest on any new files Scout wrote
"$HOME/.claude/hooks/auto-ingest.sh"
