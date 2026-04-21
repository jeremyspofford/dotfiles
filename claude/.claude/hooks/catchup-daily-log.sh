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

# Structural check: any real append has at least one "## Session:" heading
if grep -q '^## Session:' "$log" 2>/dev/null; then
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
msg = f"""[catchup-needed] Yesterday'"'"'s log ({sys.argv[1]}) has no session entries yet, but transcripts from that date exist. Please:

1. Read these transcripts briefly
2. Extract 3-6 durable bullets (decisions, insights, preferences, patterns)
3. Call append_to_daily_log with:
     date="{sys.argv[1]}"
     source_tool="claude-code-catchup"
     session_context="<inferred from transcript>"
     content="<3-6 bullets as markdown>"

Transcripts:
{sys.argv[2]}
"""
print(json.dumps(msg))
' "$yesterday" "$transcripts_list") || exit 0

# Defensive: if python3 produced empty output, skip rather than emit malformed JSON
[ -n "$context" ] || exit 0

cat <<EOF
{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": $context}}
EOF

exit 0
