# memory-capture

MCP server that writes curated notes to Jeremy's personal assistant daily
logs at `$WIKI_VAULT/Assistant/memory/YYYY-MM-DD.md`. Called from both
Claude Code and Cursor.

## Environment

- `WIKI_VAULT` (required) — absolute path to the Obsidian vault root.

## Tools

### `append_to_daily_log`

Appends a section to the target day's log file. Creates the file (with a
skeleton) if missing. Merges the calling tool into the frontmatter
`sources` array. Atomic under `proper-lockfile`.

Arguments:
- `content` (string, required) — markdown body to append
- `session_context` (string, required) — one-line header describing the work
- `source_tool` (string, required) — `"claude-code"` | `"cursor"` | ...
- `timestamp` (string, optional) — ISO datetime; defaults to now
- `date` (string, optional) — `YYYY-MM-DD`; defaults to today

Returns: `{ path, bytes_written, section_added, sources_updated }`.

## Running

```bash
bun run start
# or
bun run src/index.ts
```

See the spec at `docs/superpowers/specs/2026-04-21-memory-robustness-design.md`
for full design context.
