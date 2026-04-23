#!/usr/bin/env bash
# daily-log-sweep.sh — cron-triggered end-of-day backfill
#
# If yesterday's daily log has no `## Session:` entries but transcripts from
# that day exist, spawn a headless claude to read the transcripts and call
# append_to_daily_log. Runs non-interactively so capture doesn't depend on a
# live Claude Code session being open when the day ends.
#
# Scheduled via cron; safe to re-run (no-op when log is already populated).

set -uo pipefail

# Source env — same pattern as run-scout.sh
for profile in "$HOME/.commonrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc"; do
  if [ -f "$profile" ]; then
    # shellcheck disable=SC1090
    source "$profile" 2>/dev/null
    break
  fi
done

WIKI_VAULT="${WIKI_VAULT:-$HOME/Obsidian_Vault}"
CLAUDE_BIN=$(command -v claude 2>/dev/null || echo "$HOME/.local/bin/claude")
LOG_DIR="$HOME/.claude/logs"
LOG_FILE="$LOG_DIR/daily-log-sweep.log"

mkdir -p "$LOG_DIR"

# Portable "yesterday" — BSD date has -v, GNU date has -d
if date -v-1d +%Y-%m-%d >/dev/null 2>&1; then
  yesterday=$(date -v-1d +%Y-%m-%d)
else
  yesterday=$(date -d yesterday +%Y-%m-%d)
fi

log="$WIKI_VAULT/Assistant/memory/$yesterday.md"

# Nothing to do if the log doesn't exist (user wasn't active yesterday)
if [ ! -f "$log" ]; then
  echo "[$(date)] No log file for $yesterday — skipping" >> "$LOG_FILE"
  exit 0
fi

# Already populated — skip
if grep -q '^## Session:' "$log" 2>/dev/null; then
  echo "[$(date)] $yesterday already populated — skipping" >> "$LOG_FILE"
  exit 0
fi

# Find transcripts from yesterday (touch-sentinel pattern matches catchup-daily-log.sh)
yesterday_touch="${yesterday//-/}"
start_ref=$(mktemp)
end_ref=$(mktemp)
trap 'rm -f "$start_ref" "$end_ref"' EXIT
touch -t "${yesterday_touch}0000" "$start_ref"
touch -t "${yesterday_touch}2359" "$end_ref"

transcripts=$(find "$HOME/.claude/projects" -name "*.jsonl" \
  -not -path "*/subagents/*" \
  -newer "$start_ref" ! -newer "$end_ref" 2>/dev/null | head -20)

if [ -z "$transcripts" ]; then
  echo "[$(date)] No transcripts from $yesterday — skipping" >> "$LOG_FILE"
  exit 0
fi

if [ ! -x "$CLAUDE_BIN" ]; then
  echo "[$(date)] claude binary not found at $CLAUDE_BIN — aborting" >> "$LOG_FILE"
  exit 1
fi

echo "[$(date)] Filling $yesterday log via headless claude" >> "$LOG_FILE"

transcripts_list=$(printf '%s' "$transcripts" | sed 's/^/- /')

# Prompt headless claude to summarize + call the MCP tool.
# Instructions mirror the manual catchup prompt in catchup-daily-log.sh so
# output quality is comparable.
"$CLAUDE_BIN" \
  --print "Read these Claude Code transcripts from $yesterday (.jsonl, one JSON object per line — focus on user and assistant text, skip tool_use/tool_result entries). Extract 3-6 DURABLE bullets: decisions with reasoning, preferences, patterns, corrections. Skip activity logs and routine Q&A.

Then call the memory-capture MCP tool append_to_daily_log with:
  date=\"$yesterday\"
  source_tool=\"claude-code-sweep\"
  session_context=<one-line theme, under 100 chars>
  content=<bullets as markdown — 1-3 sentences each, include the *why* for any decision>

If transcripts are genuinely low-value, call the tool with a single bullet noting that rather than manufacturing content.

Transcripts:
$transcripts_list" \
  --dangerously-skip-permissions \
  --model sonnet \
  --add-dir "$WIKI_VAULT" \
  >> "$LOG_FILE" 2>&1

SWEEP_EXIT=$?
echo "[$(date)] Sweep finished (exit: $SWEEP_EXIT)" >> "$LOG_FILE"

exit $SWEEP_EXIT
