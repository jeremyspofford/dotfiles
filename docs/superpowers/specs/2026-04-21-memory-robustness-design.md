---
title: Memory Capture Robustness — Design Spec
date: 2026-04-21
status: draft
author: jeremyspofford
---

# Memory Capture Robustness — Design Spec

## Problem

Jeremy's daily assistant memory logs at `$WIKI_VAULT/Assistant/memory/YYYY-MM-DD.md`
have gaps. Two observed failure modes from April 2026:

- **2026-04-17**: A scout-agent-only day. `SubagentStop` hooks fired for five
  fetches, but no `SessionEnd` event triggered an append. Daily log stayed at
  55 bytes (skeleton only).
- **2026-04-18**: A session happened (file timestamp 21:33) but ended abnormally
  (closed terminal, killed process). `SessionEnd` hook never fired. Daily log
  stayed at 55 bytes.

Separately, there's no memory-capture path for Cursor IDE at all. Anything
worth keeping that happens while working in Cursor is lost.

## Goals

- Memory appends to the daily log should fire reliably from Claude Code,
  surviving abnormal session exits.
- Cursor should have parity — both "worth keeping" (in-session) and
  "session wrap" captures land in the same daily log.
- The trigger surface and file format should be consistent across tools.
- Configuration must live in `~/workspace/dotfiles/` and propagate to
  `~/.claude/` and `~/.cursor/` via GNU Stow.
- Design the memory-capture system as an independent unit that can be
  extracted from dotfiles into its own repository once it proves reliable.

## Non-goals

- Cursor hook parity. Cursor has no `SessionStart`/`SessionEnd` hook system;
  we will not build an external file-watcher or polling daemon to simulate one.
  Cursor's side remains best-effort, dependent on AI rule compliance.
- Content validation, tag enforcement, or ingestion triggering — separate
  concerns handled elsewhere (`/wiki ingest`, tag registry, etc.).
- Multi-file writes. This tool appends to today's daily log only. Session dumps
  to `raw/sessions/` and wiki page writes stay separate.

## Architecture

```
┌────────────────────────┐      ┌────────────────────────┐
│  Claude Code           │      │  Cursor IDE            │
│  (hooks + rules)       │      │  (rules only)          │
└───────────┬────────────┘      └───────────┬────────────┘
            │ stdio (MCP JSON-RPC)          │ stdio (MCP JSON-RPC)
            ▼                               ▼
        ┌─────────────────────────────────────────┐
        │   memory-capture MCP server             │
        │   TypeScript + bun, stdio transport     │
        │                                         │
        │   tool: append_to_daily_log             │
        └──────────────────┬──────────────────────┘
                           │ locked, atomic file I/O
                           ▼
         $WIKI_VAULT/Assistant/memory/YYYY-MM-DD.md
```

Three trigger paths into the MCP server:

1. **"Worth keeping" (both tools, in-session).** The AI judges that something
   durable is happening (decision, preference, correction, explicit request)
   and calls `append_to_daily_log`. Triggered by rules in the global
   `CLAUDE.md` and in Cursor's `rules/memory-capture.mdc`.
2. **End of session (both tools).** Claude Code: existing `SessionEnd` hook
   prompt is rewritten to call the tool. Cursor: the rule file instructs the
   AI to call once more at session wrap.
3. **`SessionStart` catch-up (Claude Code only).** New `SessionStart` shell
   hook detects an empty prior-day log, emits a reminder that causes the AI
   to read yesterday's transcripts and fill the gap via the MCP tool. Cursor
   has no equivalent path.

## Dotfiles layout

```
~/workspace/dotfiles/
├── claude/                         # existing stow package (unchanged layout)
│   └── .claude/
│       ├── CLAUDE.md               # updated: point at MCP tool
│       ├── settings.json           # updated: register MCP server
│       └── hooks/
│           ├── init-daily-log.sh           # unchanged
│           ├── catchup-daily-log.sh        # NEW
│           └── (SessionEnd prompt rewritten in settings.json)
├── cursor/                         # reorganized stow package
│   └── .cursor/
│       ├── mcp.json                # NEW (merged from existing ~/.cursor/mcp.json)
│       └── rules/
│           ├── tutor-mode.mdc      # moved from cursor/rules/
│           └── memory-capture.mdc  # NEW
├── mcp-servers/                    # NEW — NOT a stow package
│   ├── README.md
│   └── memory-capture/             # self-contained, extraction-ready
│       ├── package.json
│       ├── tsconfig.json
│       ├── src/
│       │   ├── index.ts            # stdio server entry point
│       │   ├── tools/
│       │   │   └── append-daily-log.ts
│       │   └── lib/
│       │       ├── frontmatter.ts  # read/merge/serialize gray-matter
│       │       ├── paths.ts        # resolve $WIKI_VAULT, date → filepath
│       │       └── lock.ts         # proper-lockfile wrapper
│       └── tests/
│           ├── frontmatter.test.ts
│           ├── append.test.ts
│           ├── tool.test.ts
│           └── integration.test.ts
└── docs/superpowers/specs/         # this document
```

Rationale for sibling placement:

- `mcp-servers/` is not a Stow package. Servers are invoked by absolute path
  from config — symlinking serves no purpose.
- Each server is self-contained with its own `package.json`. No imports from
  outside its own directory. Vault location comes from the `WIKI_VAULT` env
  var, never hardcoded. This is the extraction contract: `git subtree split
  --prefix=mcp-servers/memory-capture` produces a clean standalone history
  when it's time to extract.

## Component — memory-capture MCP server

### Tool: `append_to_daily_log`

```typescript
append_to_daily_log({
  content: string,            // markdown body to append (bullets or prose)
  session_context: string,    // one-line header describing the current work
  source_tool: string,        // "claude-code" | "cursor" | future
  timestamp?: string,         // ISO datetime; defaults to new Date().toISOString()
  date?: string,              // YYYY-MM-DD; defaults to today — used for catch-up writes
})
// returns: { path, bytes_written, section_added, sources_updated }
```

The return value is deliberately observable — the caller sees what changed
and can surface the result. Silent success is a bug source.

### File operation (read-modify-write, locked)

Atomic sequence for every append:

1. Resolve target path: `$WIKI_VAULT/Assistant/memory/<date>.md`.
2. Acquire an exclusive lock on the file via `proper-lockfile`
   (creates a `<file>.lock` sibling; auto-released on process exit).
3. If the file is missing, write the skeleton:
   ```yaml
   ---
   date: <date>
   ingested: false
   sources: []
   ---

   # <date>
   ```
4. Parse existing frontmatter with `gray-matter`. If `sources` is missing or
   doesn't include `source_tool`, merge it in (deduped).
5. Serialize frontmatter, append a new section:
   ```
   ## Session: <session_context> — <source_tool> @ <HH:MM>

   <content>
   ```
6. Write atomically: write to `<path>.tmp`, `fs.rename` to `<path>`, release
   the lock.

### Concurrency rationale

Both tools could write concurrently — Jeremy working in Claude Code on one
terminal while Cursor's AI writes from another. Without a lock, the standard
read-modify-write race on the frontmatter will corrupt it. `proper-lockfile`
is battle-tested and widely used.

**Stale-lock handling.** `proper-lockfile` does not auto-clean on crash by
default — it relies on a `stale` timeout and optional `onCompromised`
callback. Config for this server:

```typescript
await lockfile.lock(filepath, {
  stale: 10_000,           // a lock older than 10s is considered stale
  retries: { retries: 10, minTimeout: 50, maxTimeout: 500 },
  onCompromised: (err) => { /* log + rethrow; AI surfaces */ },
});
```

If a process crashes mid-write, the lockfile sibling (`<path>.lock`) remains
on disk but is treated as stale after 10 seconds — subsequent writes
reacquire cleanly. The 10-retry budget covers transient contention between
Claude Code and Cursor writing within the same sub-second window.

A dedicated concurrency test fires 10 parallel calls and asserts all 10
sections land and `sources` is consistent. A separate crash-simulation test
SIGKILLs a writer mid-operation and asserts the next writer reacquires.

### Environment contract

- `WIKI_VAULT` — required. If unset, the tool returns a structured error
  rather than guessing a path. The calling AI surfaces this to Jeremy.
- `$HOME` — used only for tilde expansion if `$WIKI_VAULT` contains `~`.

### Deliberately out of scope (YAGNI)

- No auto-ingest trigger on write. Auto-ingest already runs on files with
  `ingested: false`; this tool just respects that flag.
- No tag enforcement or content validation. The tool trusts the AI.
- No writes to `raw/`, `wiki/`, or anywhere outside `Assistant/memory/`.
  Split into separate tools if/when needed.

## Component — Claude Code integration

### MCP server registration (`settings.json`)

```json
"mcpServers": {
  "memory-capture": {
    "command": "bun",
    "args": ["run", "/home/jeremy/workspace/dotfiles/mcp-servers/memory-capture/src/index.ts"],
    "env": { "WIKI_VAULT": "/home/jeremy/Obsidian_Vault" }
  }
}
```

### `SessionEnd` hook rewrite

The current `SessionEnd` hook is a `type: prompt` that tells Claude to
(a) write a session dump to `raw/sessions/` via the Write tool, and (b)
append a curated summary to the daily log via the Write tool.

Half (a) stays unchanged — session dumps go to `raw/`.

Half (b) is rewritten to call the `append_to_daily_log` MCP tool with
`source_tool: "claude-code"`, `session_context: "<one-liner>"`, and 3-8
curated bullets as `content`.

### `SessionStart` catch-up hook — `hooks/catchup-daily-log.sh`

```bash
#!/usr/bin/env bash
# Detects empty prior-day logs, emits a reminder for the AI to fill.
# Shell does the cheap "is there a gap?" check; AI does the expensive
# "summarize the transcript" work — and only when needed.
#
# Output contract: this hook emits Claude Code's documented hook JSON
# protocol with hookSpecificOutput.additionalContext. That field is
# injected into the session as contextual guidance the AI reads before
# its first response.

set -euo pipefail
WIKI_VAULT="${WIKI_VAULT:-$HOME/Obsidian_Vault}"

# Portable "yesterday" — GNU and BSD date differ.
if date -v-1d +%Y-%m-%d >/dev/null 2>&1; then
  yesterday=$(date -v-1d +%Y-%m-%d)           # BSD (macOS)
else
  yesterday=$(date -d yesterday +%Y-%m-%d)    # GNU (Linux/WSL)
fi

log="$WIKI_VAULT/Assistant/memory/$yesterday.md"

[ -f "$log" ] || exit 0                                   # nothing to catch up

# Populated check — use structure, not byte count.
# Skeleton has no "## Session:" headings; any real append has at least one.
if grep -q '^## Session:' "$log" 2>/dev/null; then
  exit 0                                                  # already has at least one session section
fi

# Portable transcript-date filter. `find -newermt` is GNU-only; use reference
# files with touch -t instead (portable BSD/GNU syntax: [[CC]YY]MMDDhhmm).
yesterday_touch="${yesterday//-/}"                        # 2026-04-20 → 20260420
start_ref=$(mktemp) && touch -t "${yesterday_touch}0000" "$start_ref"
end_ref=$(mktemp)   && touch -t "${yesterday_touch}2359" "$end_ref"

transcripts=$(find "$HOME/.claude/projects" -name "*.jsonl" \
  -newer "$start_ref" ! -newer "$end_ref" 2>/dev/null)

rm -f "$start_ref" "$end_ref"

[ -n "$transcripts" ] || exit 0                           # no transcripts from yesterday

# JSON escaping for additionalContext payload. Uses python3 if available;
# degrades gracefully if not (skips catch-up rather than emitting malformed JSON).
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
' "$yesterday" "$transcripts_list")

cat <<EOF
{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": $context}}
EOF

exit 0
```

**Critical specifics verified by this design:**

- **Populated check uses structure, not size.** Previous byte-threshold approach
  (size < 100) was unsafe because a valid short catch-up append could fall
  below 100 bytes and re-fire. Checking for `^## Session:` is unambiguous:
  the skeleton never has that line; any real append always does.
- **Portable `date` and `stat`.** BSD (macOS) and GNU (Linux) syntaxes are
  detected and used accordingly. Supports Jeremy's occasional macOS use.
- **JSON hook output protocol.** `SessionStart` shell hooks can inject text
  into the session by emitting `{"hookSpecificOutput": {"hookEventName":
  "SessionStart", "additionalContext": "..."}}`. This is the documented path;
  plain stdout is NOT guaranteed to reach the AI as context.
- **Transcript-date filter (portable).** Uses `touch -t [[CC]YY]MMDDhhmm`
  (BSD/GNU common syntax) to create sentinel reference files at the start
  and end of yesterday, then `find -newer START ! -newer END`. This works
  on both macOS and Linux. `find -newermt` would be simpler but is
  GNU-only.
- **Python 3 as a soft dependency.** Used only to JSON-escape the
  `additionalContext` payload. If `python3` isn't on PATH, the hook exits
  silently rather than emit malformed JSON — catch-up is best-effort, not
  mission-critical, and better to skip than to break the session.
- **Caveat on mtime-based selection.** Any file that happens to be touched
  by another process on the target day (unlikely for `~/.claude/projects/*.jsonl`,
  which Claude Code owns exclusively, but possible via backup tools) would
  be included. Acceptable trade-off — the AI is told to skim and can judge.

### Hook ordering in `settings.json`

`SessionStart` hooks run in the order they appear in the `settings.json`
array. The catch-up hook MUST be listed after `init-daily-log.sh` so that
today's skeleton exists before catch-up logic runs:

```json
"SessionStart": [
  { "matcher": "", "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/init-daily-log.sh", "timeout": 10 }] },
  { "matcher": "", "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/catchup-daily-log.sh", "timeout": 10 }] },
  { "matcher": "", "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/auto-ingest.sh", "timeout": 30 }] }
]
```

### `CLAUDE.md` update (global, `~/.claude/CLAUDE.md`)

Replace the existing "write to files immediately when relevant" instruction
with an explicit MCP-first policy:

- Use `append_to_daily_log` for all daily-log entries.
- Use `Write` for `raw/` session dumps, wiki pages, and everything else.
- The `sources` frontmatter array is maintained by the MCP tool; do not
  edit daily log frontmatter directly.

## Component — Cursor integration

### Stow package reorganization

Current `~/workspace/dotfiles/cursor/` has `rules/tutor-mode.mdc` and a README
but is not Stow-shaped (no `.cursor/` root inside the package). Reshape to:

```
dotfiles/cursor/
├── .cursor/
│   ├── mcp.json                    # merged from existing ~/.cursor/mcp.json
│   └── rules/
│       ├── tutor-mode.mdc          # moved
│       └── memory-capture.mdc      # new
└── README.md
```

Then `stow -d ~/workspace/dotfiles -t ~ cursor` symlinks
`~/.cursor/mcp.json` and `~/.cursor/rules/*.mdc` to the dotfiles copies.

**Existing file merge step.** `~/.cursor/mcp.json` already exists (352 bytes).
Implementation must read its current contents and merge them into the
dotfiles copy before stowing — not overwrite.

### `~/.cursor/mcp.json`

```json
{
  "mcpServers": {
    "memory-capture": {
      "command": "bun",
      "args": ["run", "/home/jeremy/workspace/dotfiles/mcp-servers/memory-capture/src/index.ts"],
      "env": { "WIKI_VAULT": "/home/jeremy/Obsidian_Vault" }
    }
  }
}
```

Plus whatever existing servers are already configured (merged from the
current file).

**Env var fallback.** If verification during implementation finds that
Cursor's MCP loader ignores the `env` key, fall back to exporting
`WIKI_VAULT` globally from `~/.zshenv` (which both interactive shells AND
GUI-launched processes like Cursor inherit on Linux/macOS). The server
already reads `process.env.WIKI_VAULT` with no config-level coupling — the
env-injection mechanism is swappable.

### `~/.cursor/rules/memory-capture.mdc`

```markdown
---
description: Capture durable notes to the personal assistant vault
alwaysApply: true
---

# Memory capture

When something worth keeping comes up — a decision made, a pattern identified,
a correction, a preference expressed, or an explicit "remember this" — call
the `append_to_daily_log` MCP tool with:

- `source_tool`: "cursor"
- `session_context`: one line describing the current work
- `content`: 1-5 bullet points in plain markdown
- `timestamp`: current ISO datetime

At the end of a session (or when clearly wrapping up), call it once more
with a 3-8 bullet summary under the same `session_context`.

Do NOT use the Write tool to edit `Assistant/memory/*.md` directly — always
go through the MCP tool so the frontmatter `sources` array stays consistent.
```

### Known asymmetry

Cursor gets no catch-up equivalent because Cursor has no hook system. If
the MCP tool call fails or the AI skips it in a session, that Cursor session
is lost. We accept this trade-off for now and will revisit if empty Cursor
days become a visible pattern.

## Data flow

### Happy path — "worth keeping" mid-session

1. AI (in either tool) decides content is durable.
2. AI calls `append_to_daily_log` via MCP.
3. Server acquires lock on today's log.
4. Server creates the file from skeleton if missing.
5. Server merges `source_tool` into `sources` array.
6. Server appends a new `## Session: ...` section with the content.
7. Server writes atomically and releases lock.
8. Server returns observable result to AI.

### Catch-up path — Claude Code, abnormal prior exit

1. New Claude Code session starts → `init-daily-log.sh` creates today's
   skeleton.
2. `catchup-daily-log.sh` runs → detects yesterday's log has no
   `## Session:` headings AND a transcript exists for that date → emits
   Claude Code hook JSON with `additionalContext` describing the gap.
3. AI receives `additionalContext` as part of session initialization, reads
   the named transcripts.
4. AI calls `append_to_daily_log` with `date=<yesterday>` and
   `source_tool="claude-code-catchup"`.
5. Server writes to yesterday's file (same tool, same code path, different date).

**Why `claude-code-catchup` is a distinct `source_tool`** (not `claude-code`):
catch-up entries are reconstructed from transcript, not live observation —
they're one step removed from the actual session. The distinct tag lets
future queries distinguish "written live" from "reconstructed," and makes
it obvious in the frontmatter `sources` array when a day depended on
catch-up (a signal that the real session ended abnormally).

## Error handling

| Failure                                        | Response                                                                                         |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `$WIKI_VAULT` unset                            | Tool returns structured error; AI surfaces to user                                               |
| Vault path doesn't exist                       | Tool returns structured error                                                                    |
| File lock contention                           | `proper-lockfile` retries with jitter, up to 10 attempts; errors if exhausted                    |
| Frontmatter parse failure (existing file)      | Tool returns structured error with file path; Jeremy fixes by hand                               |
| Disk full / write error                        | Tmp file left in place (easy manual recovery); lock released; error returned                     |
| Concurrent `sources` merge race                | Prevented by lock — never observed at the app layer                                              |
| Catch-up hook finds no transcript              | Shell script exits 0 silently; no reminder emitted                                               |
| Catch-up hook finds transcript, AI ignores it  | Next session's catch-up fires again — idempotent until the log gains at least one `## Session:` heading  |

## Testing strategy

### Unit tests (`bun test`)

- **`frontmatter.test.ts`** — merge dedup, field preservation, skeleton creation.
- **`append.test.ts`** — section header formatting, position (appended not
  prepended), empty-body handling.
- **`tool.test.ts`** — happy path, missing `WIKI_VAULT`, invalid date format,
  atomicity under simulated interrupt.

All tests use a throwaway temp directory as their `WIKI_VAULT`. No real
vault touched.

### Integration test

Spawn the stdio server as a subprocess, send one real JSON-RPC request,
assert resulting file state. Catches wiring/serialization bugs that
unit tests miss.

### Concurrency test

Fire 10 parallel `append_to_daily_log` invocations. Assert:
- All 10 sections present in the final file.
- `sources` array correctly deduped.
- No frontmatter corruption.

### Manual test plan

1. Fresh day, no log file → tool creates skeleton + appends first section.
   Verify frontmatter and body.
2. Existing skeleton from `init-daily-log.sh` hook → tool appends, `sources`
   array has one entry.
3. Simulated abnormal prior exit: write a 55-byte skeleton dated yesterday,
   drop a dummy transcript in `~/.claude/projects/test/*.jsonl`, start a new
   Claude Code session, confirm the catch-up reminder appears in session
   context and the AI fills the gap.
4. Open Cursor in a repo, ask it to remember something, confirm the entry
   lands with `source_tool: "cursor"` and `sources: [cursor]` (or merged
   with `claude-code` if that tool wrote earlier today).

### Deliberately not tested

- The AI's judgment on what constitutes "worth keeping" — not unit-testable.
- Cursor's rule compliance — outside our control.
- Obsidian's rendering of the output — visual check only.

## Extraction path

When `memory-capture` has proven reliable in daily use (suggested threshold:
30 days with no frontmatter corruption, no silent data loss, at least one
abnormal-exit recovery working end-to-end), extract it:

```bash
cd ~/workspace/dotfiles
git subtree split --prefix=mcp-servers/memory-capture -b memory-capture-extract
# push to new repo
git push git@github.com:jeremyspofford/mcp-memory-capture.git memory-capture-extract:main
```

Then in `dotfiles/claude/.claude/settings.json` and
`dotfiles/cursor/.cursor/mcp.json`, replace the absolute path with:

```json
"args": ["x", "github:jeremyspofford/mcp-memory-capture"]
```

Or publish to npm and use `"args": ["x", "mcp-memory-capture"]`.

Because the server never reaches into dotfiles for anything (no shared libs,
no shared config), the subtree split produces a clean standalone history on
day one.

## Decisions log

| Decision                                      | Chose                              | Over                                                       | Rationale                                                                                                                                 |
| --------------------------------------------- | ---------------------------------- | ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Abnormal-exit recovery mechanism              | `SessionStart` catch-up hook       | Cron sweeper; accept the gap                               | Self-healing, no external infra, fires exactly when you need the log current.                                                             |
| Cursor integration strategy                   | Shared MCP server + rule file      | Rule file only; external file watcher                      | Deterministic format via shared tool; weaker AI-compliance guarantee acceptable; file watcher is brittle and depends on Cursor internals. |
| Attribution                                   | Frontmatter `sources: []` + tool name in section header | Body-only tag; no attribution                              | Obsidian indexes frontmatter (Dataview, tag pane); section header gives human-readable context when scrolling.                            |
| Tool surface                                  | One tool (`append_to_daily_log`)   | Two tools (`capture_worth_keeping` + `end_session_summary`) | YAGNI. End-session behavior has no divergence yet; single tool is easier to prompt reliably.                                              |
| Language/runtime                              | TypeScript + bun                   | Python + uv                                                | Matches Jeremy's stated preferences; bun runs `.ts` directly, no build step needed locally.                                               |
| MCP server location in dotfiles               | `mcp-servers/` (sibling, not Stow) | Inside `claude/` stow package                              | Not symlinked — invoked by absolute path. Sibling placement signals "shared infra, not tool-specific."                                    |
| Concurrency primitive                         | `proper-lockfile`                  | In-process mutex; no locking                               | Multiple processes could write simultaneously (Cursor + Claude Code); battle-tested; auto-releases on crash.                              |
| Cursor catch-up                               | None (accept the gap)              | External file watcher; polling daemon                      | Cursor has no hook system; an external watcher is brittle and over-engineered for a marginal gain.                                        |

## Open questions

None currently blocking implementation.
