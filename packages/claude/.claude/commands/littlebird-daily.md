Ingest a Littlebird daily summary into the wiki: split by project, write/append raw captures, and surface preferences and follow-ups for review. Wiki page creation is left to `/wiki ingest`, which has cross-source context this command does not.

Usage: `/littlebird-daily [--date YYYY-MM-DD]` followed by the pasted summary text.

## Input

$ARGUMENTS

If `$ARGUMENTS` is empty or contains only the optional `--date` flag with no body, ask Jeremy for the summary text. One line, no filler.

## Step 1: Load shared conventions

Read `$WIKI_VAULT/CLAUDE.md` once at the start of execution. The frontmatter format, project slug rules, Tag Registry, and "never modify raw note bodies" rule come from there. Do not duplicate those rules — defer to that file as the source of truth.

If `$WIKI_VAULT` is unset, stop and say: "WIKI_VAULT is not set. Please check your shell config."

## Step 2: Resolve the captured date

- If `--date YYYY-MM-DD` is present in the input, use that.
- Otherwise default to **yesterday** (today's date minus one day). Littlebird summaries describe the previous day's activity, so "yesterday" is the right default.
- Strip the flag from the input before parsing the body.

The resolved date becomes `captured_date` in frontmatter and the filename stem (`YYYY-MM-DD-session.md`).

## Step 3: Parse the summary into threads

Littlebird summaries are prose blocks with topic headers. Split on:

- A short title line (typically capitalized phrase, no terminal punctuation), often followed by a blank line and prose.
- Section breaks (blank lines between distinct topics).

Normalize each thread to a `(title, body)` pair. Preserve the original prose verbatim — do not summarize or compress.

If the summary doesn't parse cleanly, fall back to writing the entire summary as a single thread routed to `personal/general` and flag the parse failure in the review output.

## Step 4: Route each thread to a project

Apply rules in order. First match wins. Use only existing on-disk slugs — check `$WIKI_VAULT/raw/` for which slugs already exist before creating a new one.

| Signal in thread | Destination slug |
|---|---|
| "Nova" / `nova-test-cap` / Cortex / Screenpipe / OpenClaw | `nova` |
| "Alertventure" / `ft-quoting` / specific Alertventure repo | `alertventure/<project>` |
| Dotfiles / shell config / stow / nvim config | `dotfiles` |
| Studying for cert / course / skill-building (Docker, Terraform, AWS SAA, etc.) | `personal/general` |
| Tooling research / browser / app evaluation | `personal/general` |
| Home / family / health / cooking / finance | `personal/<subdomain>` (only if explicit signal) |
| Anything else | `personal/general` |

Note: Nova captures live at `raw/nova/`, **not** `raw/arialabs/nova/`. This is the existing on-disk convention — match it.

If a thread can't be confidently routed, route to `unknown/<dirname>` and set `needs-review: true` on the frontmatter (per `$WIKI_VAULT/CLAUDE.md` "Project resolution" rules). Surface it in the review output.

## Step 5: Group threads by destination, write/append captures

For each unique destination slug:

1. Determine the path: `$WIKI_VAULT/raw/<slug>/<captured_date>-session.md`.
2. **If the file does not exist**, create it with this frontmatter:

   ```yaml
   ---
   source_project: <slug>
   captured_date: YYYY-MM-DD
   session_context: "Littlebird daily summary"
   source: littlebird/daily
   ingested: false
   needs-review: false
   ---
   ```

3. **If the file exists**, append only — never modify existing frontmatter or body content above. Append a new heading block:

   ```markdown


   ## [<captured_date>] Littlebird daily summary

   <!-- Source: Littlebird Routine: Daily Summary -->

   ### <Thread title 1>

   <verbatim prose for thread 1>

   ### <Thread title 2>

   <verbatim prose for thread 2>
   ```

4. Use the `Write` tool for new files, `Edit` (with `replace_all: false` and a unique anchor like end-of-file) or `Read` + `Write` to append to existing files. Never modify content above the append point.

5. Tags: skip the `tags:` frontmatter field for these captures. The Tag Registry in `$WIKI_VAULT/CLAUDE.md` is strict — leave tagging to `/wiki ingest`, which has the discretion to apply approved tags during downstream processing.

## Step 6: Surface candidates for review (do NOT auto-write)

Identify and print these for Jeremy's approval. Each section is optional — omit if empty.

Do **not** surface "durable wiki candidates" or suggest concept/decision/entity pages. Wiki page creation belongs to `/wiki ingest`, which sees multiple raw captures and can cross-reference them. This command's job is raw capture + operational signals only.

### MEMORY.md candidates

Durable preferences, stances, or working-style choices that should land in `Assistant/MEMORY.md` (the curated long-term cache). Format as:

- "<verbatim phrase>" — why it matters in one short clause.

Examples of memory-worthy: explicit "avoiding X" stances, tool/vendor preferences with reasoning, learning-style preferences, recurring values.

### Daily-log candidates

Cross-cutting decisions or patterns that should append to `Assistant/memory/<captured_date>.md` via the `append_to_daily_log` MCP tool. Use `source_tool: "littlebird-daily"`, a one-line `session_context`, and 1-5 bullets as `content`.

Only surface these if they're durable enough to belong in memory — skip ephemeral task-level details.

### Open follow-ups

Tasks paused, debugging unfinished, or known issues to resume. Group by project. Format as:

- **<project slug>**: <follow-up description>

## Step 7: Confirm

Print a tight summary:

- Files written (full paths) with create/append status.
- Counts: M memory candidates, D daily-log candidates, K open follow-ups.
- Any routing failures or `unknown/*` slugs that need review.

Then ask: "Promote any candidates now? (memory / daily-log / none)". On approval, execute the relevant action — direct `Assistant/MEMORY.md` edit for memory items, `append_to_daily_log` MCP tool for daily-log items. Wiki pages are out of scope here; defer to `/wiki ingest`.

## Hard rules

- **Never modify existing raw note bodies** — append-only, frontmatter unchanged. (Per `$WIKI_VAULT/CLAUDE.md`.)
- **Never use the `Write` tool** to edit `Assistant/memory/YYYY-MM-DD.md` — use the `append_to_daily_log` MCP tool. (Per `~/.claude/CLAUDE.md`.) `Assistant/MEMORY.md` (capital, no subdir) is fine to edit directly.
- **Never invent new tags** — only use approved tags from the Tag Registry. Propose new ones via `/wiki tag propose` with explicit approval.
- **Preserve prose verbatim** in raw captures — do not summarize or rewrite Littlebird's text.
- **No wiki page creation here.** Raw captures + MEMORY.md + daily log are the only durable outputs. Concept/decision/entity pages are `/wiki ingest`'s job — it has multi-source context this command lacks, so promoting from a single daily summary tends to produce thin pages. Don't even surface "durable wiki candidates" — it sets the wrong expectation.
