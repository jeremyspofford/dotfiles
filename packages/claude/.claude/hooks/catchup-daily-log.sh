#!/usr/bin/env bash
# catchup-daily-log.sh — SessionStart hook
#
# Detects when yesterday's daily log is empty (no ## Session: headings) but
# transcripts from that date exist, and emits Claude Code's hook JSON
# protocol with additionalContext telling the AI to fill the gap.

set -euo pipefail

WIKI_VAULT="${WIKI_VAULT:-$HOME/Obsidian_Vault}"

# Portable "yesterday" — BSD date has -v, GNU date has -d
if date -v-1d +%Y-%m-%d >/dev/null 2>&1; then
  yesterday=$(date -v-1d +%Y-%m-%d)
else
  yesterday=$(date -d yesterday +%Y-%m-%d)
fi

log="$WIKI_VAULT/Assistant/memory/$yesterday.md"

[ -f "$log" ] || exit 0

# Structural check: any H2 heading means the log has been curated already.
# This treats topical H2s ("## Topic — tagline", the 2026-04-16 canonical
# style) the same as legacy "## Session: ..." entries. Catchup only fires
# when the log has just the auto-generated skeleton (H1 title only).
if grep -q '^## ' "$log" 2>/dev/null; then
  exit 0
fi

# Portable transcript-date filter: use touch -t sentinels + find -newer.
# touch -t [[CC]YY]MMDDhhmm is BSD/GNU-common.
yesterday_touch="${yesterday//-/}"
start_ref=$(mktemp)
end_ref=$(mktemp)
trap 'rm -f "$start_ref" "$end_ref"' EXIT
touch -t "${yesterday_touch}0000" "$start_ref"
touch -t "${yesterday_touch}2359" "$end_ref"

transcripts=$(find "$HOME/.claude/projects" -name "*.jsonl" \
  -newer "$start_ref" ! -newer "$end_ref" 2>/dev/null || true)

[ -n "$transcripts" ] || exit 0

# Python 3 used only for JSON-escaping the additionalContext string.
# Soft dep: skip silently if not available.
command -v python3 >/dev/null 2>&1 || exit 0

transcripts_list=$(printf '%s' "$transcripts" | sed 's/^/- /')

context=$(python3 -c '
import json, sys
date = sys.argv[1]
log_path = sys.argv[2]
transcripts = sys.argv[3]
msg = f"""[catchup-needed] Yesterday'"'"'s log ({date}) has only the auto-generated skeleton — no curated content. Transcripts from that date exist and may contain durable knowledge worth recording.

Daily log file: {log_path}

Please:

1. Briefly skim the transcripts listed below.
2. Decide whether anything durable came out of yesterday — decisions with rationale, preferences expressed, project milestones, corrections worth preserving, patterns or insights future sessions should reference.
3. If yes: use the Edit tool on {log_path} to add topical H2 sections in the Assistant/memory/2026-04-16.md style. Descriptive section titles (e.g. `## Portfolio redesign — warm-document aesthetic`), NOT `## Session: X — claude-code-catchup @ HH:MM`. Prefer bold sub-markers (**Goal:** / **Key decisions:** / **Open questions:**) where they fit. Do NOT call append_to_daily_log — write directly with Edit.
4. If nothing durable was found, do NOT write. An empty day is fine — Assistant/memory/ is a curated knowledge store, not an activity log.

Transcripts:
{transcripts}
"""
print(json.dumps(msg))
' "$yesterday" "$log" "$transcripts_list") || exit 0

# Defensive: if python3 produced empty output, skip rather than emit malformed JSON
[ -n "$context" ] || exit 0

cat <<EOF
{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": $context}}
EOF

exit 0
