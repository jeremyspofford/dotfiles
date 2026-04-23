#!/usr/bin/env bash
# session-end-dump.sh — SessionEnd hook (command type)
#
# Reads hook input JSON from stdin (session_id, transcript_path, cwd),
# then detaches a headless claude to:
#   (1) write a session dump to $WIKI_VAULT/raw/sessions/
#   (2) call the memory-capture MCP append_to_daily_log tool
#
# The heavy work is detached via nohup+disown so the hook returns in ms —
# Claude Code can finish exiting cleanly while the dump happens in background.

set -uo pipefail

# Source env — same pattern as run-scout.sh / daily-log-sweep.sh
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
LOG_FILE="$LOG_DIR/session-end.log"

mkdir -p "$LOG_DIR"

# Read hook JSON from stdin (if available)
HOOK_INPUT=""
if [ ! -t 0 ]; then
  HOOK_INPUT=$(cat)
fi

parse_field() {
  # Usage: parse_field <field_name> <json>
  local field="$1"
  local json="$2"
  [ -z "$json" ] && { echo ""; return; }
  command -v python3 >/dev/null 2>&1 || { echo ""; return; }
  echo "$json" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('$field', ''))
except Exception:
    print('')
" 2>/dev/null
}

TRANSCRIPT_PATH=$(parse_field transcript_path "$HOOK_INPUT")
SESSION_CWD=$(parse_field cwd "$HOOK_INPUT")
SESSION_ID=$(parse_field session_id "$HOOK_INPUT")

# No transcript → nothing to do
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  echo "[$(date)] No valid transcript_path (got: '${TRANSCRIPT_PATH:-empty}') — skipping" >> "$LOG_FILE"
  exit 0
fi

# Size guard — don't waste a headless claude on a 2-message session
TRANSCRIPT_SIZE=$(stat -c%s "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
if [ "$TRANSCRIPT_SIZE" -lt 4096 ]; then
  echo "[$(date)] Transcript too small (${TRANSCRIPT_SIZE}B) — skipping" >> "$LOG_FILE"
  exit 0
fi

if [ ! -x "$CLAUDE_BIN" ]; then
  echo "[$(date)] claude binary not found at $CLAUDE_BIN — aborting" >> "$LOG_FILE"
  exit 1
fi

TODAY=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)

mkdir -p "$WIKI_VAULT/raw/sessions"

echo "[$(date)] Dispatching session-end dump for ${SESSION_ID:-unknown} (cwd: $SESSION_CWD, size: ${TRANSCRIPT_SIZE}B)" >> "$LOG_FILE"

# Detach the heavy work so the hook returns fast. `nohup` + `&` + `disown`
# ensures the spawned claude survives Claude Code's own process exiting.
nohup "$CLAUDE_BIN" \
  --print "A Claude Code session just ended. Read its transcript at $TRANSCRIPT_PATH (JSONL, one object per line — focus on user/assistant text, skip tool_use/tool_result entries). The session was run from: $SESSION_CWD.

Do TWO things:

(1) Use the Write tool to create a session dump at $WIKI_VAULT/raw/sessions/${TIMESTAMP}-session-dump.md with this frontmatter:
---
source: session/[infer domain/project from cwd or conversation]
source_project: [domain/project — e.g. personal/general, alertventure/ft-quoting, arialabs/nova]
captured_date: $TODAY
captured_at: [ISO datetime]
session_context: [one line describing what was worked on]
ingested: false
---

In the body, capture durable content only: key decisions (with reasoning), technical insights, patterns identified, project status changes, corrections worth preserving. Skip trivial/routine exchanges.

(2) Call the memory-capture MCP tool append_to_daily_log with:
  date=\"$TODAY\"
  source_tool=\"claude-code-session-end\"
  session_context=[one line, under 100 chars]
  content=[3-8 curated bullet points — decisions with reasoning, preferences, patterns, corrections; each 1-3 sentences]

If the transcript has nothing substantive (quick question, trivial task, already captured elsewhere), SKIP both writes — don't manufacture content." \
  --dangerously-skip-permissions \
  --model sonnet \
  --add-dir "$WIKI_VAULT" \
  >> "$LOG_FILE" 2>&1 &
disown $!

echo "[$(date)] Background dump spawned (pid $!)" >> "$LOG_FILE"
exit 0
