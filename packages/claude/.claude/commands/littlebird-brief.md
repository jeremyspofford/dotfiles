Ingest a Littlebird morning brief: split priorities/meetings/risks by project, write/append raw captures, build a session todo list, and surface time-critical follow-ups for review.

Usage: `/littlebird-brief [--date YYYY-MM-DD] [--no-todos]` followed by the pasted brief text.

## Input

$ARGUMENTS

If `$ARGUMENTS` is empty or contains only flags with no body, ask Jeremy for the brief text. One line, no filler.

## Step 0: Print help and exit if --help/-h

If `$ARGUMENTS` is exactly `--help`, `-h`, or the only non-empty token (ignoring whitespace) is `--help` or `-h`, print the usage block below and stop. Do not parse the body, load conventions, or write files.

```
================================================================================
/littlebird-brief — Help
================================================================================

Ingest a Littlebird morning brief into the wiki: route priorities/meetings/
risks by project, append to today's session captures, build a TodoWrite list
for the session, and surface time-critical risks for review.

Usage:
  /littlebird-brief [OPTIONS]
  <paste brief body here>

Options:
  --date YYYY-MM-DD  Brief date (default: today — briefs describe today's plan)
  --no-todos         Skip TodoWrite population (default: build session todos)
  -h, --help         Show this help and exit

Lifecycle:
  Briefs are forward-looking and ephemeral. They get archived to raw captures
  for context (so they appear alongside daily summaries when working in a
  project), but they are NOT promoted to wiki/ pages — operational items, not
  architectural decisions. /wiki ingest will skip these by default.

Side effects:
  - Creates or appends raw/<slug>/<date>-session.md per project mentioned.
    Frontmatter on create only; body appended for existing files.
  - Builds a TodoWrite list for the session from priorities + critical risks
    (skip with --no-todos).
  - Surfaces time-critical risks (deadlines, blockers) for explicit review.
  - Does NOT auto-log to Assistant/memory/ — briefs are session-scoped.

Examples:
  # Default — today's brief, build session todos
  /littlebird-brief
  <paste brief>

  # Backdate (e.g., catching up on yesterday's brief)
  /littlebird-brief --date 2026-05-04
  <paste brief>

  # Brief without populating todos (just archive + risk surface)
  /littlebird-brief --no-todos
  <paste brief>

================================================================================
```

## Step 1: Load shared conventions

Read `$WIKI_VAULT/CLAUDE.md` once at start. Frontmatter format, project slug rules, Tag Registry, and "never modify raw note bodies" come from there. Defer to that file as the source of truth.

If `$WIKI_VAULT` is unset, stop and say: "WIKI_VAULT is not set. Please check your shell config."

## Step 2: Resolve the captured date

- If `--date YYYY-MM-DD` is present, use it.
- Otherwise default to **today**. Morning briefs describe today's plan, so "today" is the right default. (Contrast with `/littlebird-daily`, which defaults to yesterday.)
- Strip the flag from the input before parsing.

The resolved date becomes `captured_date` in frontmatter and the filename stem.

## Step 3: Parse the brief into sections

Littlebird morning briefs follow a fixed schema with emoji-prefixed section headers. Extract each section verbatim — preserve prose, bullets, sub-bullets, and bolding exactly. Do not summarize.

Expected sections (any may be absent — skip silently):

- `🎯 Top Priorities` — bullet list, often with sub-bullets for multi-part items.
- `🗓️ Meetings and Preparation` — meeting list with prep notes.
- `⚠️ Critical Risks and Follow-ups` — usually grouped under sub-headers (e.g., "Infrastructure and Technical Debt", "Career and Assessments"). Risks have implicit or explicit deadlines.

If the brief doesn't match this schema (no recognizable sections), fall back: write the entire brief verbatim under `## [<date>] Littlebird morning brief` to `personal/general`, set `needs-review: true`, and flag the parse failure in the confirmation output.

## Step 4: Route each item to a project

Each bullet under each section is an "item". Route items individually — a single brief typically spans 4-6 distinct project slugs.

Apply rules in order. First match wins. Use only existing on-disk slugs where possible — check `$WIKI_VAULT/raw/` for which slugs already exist. If a rule produces a slug that doesn't exist on disk, note it in the confirmation output as a new slug being created (don't block).

| Signal in item | Destination slug |
|---|---|
| `ft-quoting` / Alertventure / MR !500 / Dematic-style auto-merge in alertventure context | `alertventure/ft-quoting` |
| Nova / Screenpipe / Cortex / OpenClaw / `break-it` branch | `nova` |
| VC-### ticket / VividCloud stand-up / S3 bucket policy / SSE-KMS / Drew Millecchia | `vividcloud/general` |
| Terragrunt / Terraform refactor / cloud provider comparison (VC project meeting context) | `vividcloud/general` |
| Dotfiles / shell config / mise / nvim | `dotfiles` |
| <!-- TODO: Jeremy — fill in routing for the rest. Today's brief includes: --> |   |
| <!-- 1. AWS Health alerts on `georgies-kitchen-development` account (RDS MySQL EOL). --> |   |
| <!--    Is this an alertventure client, vividcloud client, or its own slug? --> |   |
| <!-- 2. Career follow-ups: Avive Solutions feedback, HCSS application, Prompt Health --> |   |
| <!--    assessment. Suggest `personal/career` (new slug) vs. `personal/general`? --> |   |
| <!-- 3. Anything else recurring you want pre-mapped? --> |   |
| Anything else | `personal/general` |

If an item can't be confidently routed, route to `unknown/<dirname>` and set `needs-review: true` on the frontmatter. Surface it in the review output.

Note the existing on-disk convention: Nova captures live at `raw/nova/`, **not** `raw/arialabs/nova/`. Match existing on-disk paths.

## Step 5: Group items by destination, write/append captures

For each unique destination slug:

1. Path: `$WIKI_VAULT/raw/<slug>/<captured_date>-session.md`.
2. **If the file does not exist**, create it with this frontmatter:

   ```yaml
   ---
   source_project: <slug>
   captured_date: YYYY-MM-DD
   session_context: "Littlebird morning brief"
   source: littlebird/brief
   ingested: false
   needs-review: false
   ---
   ```

3. **If the file exists**, append only — never modify existing frontmatter or body content above. Use `Read` + `Write` to append, or `Edit` with `replace_all: false` and a unique end-of-file anchor.

4. Append this heading block (whether new or existing):

   ```markdown


   ## [<captured_date>] Littlebird morning brief

   <!-- Source: Littlebird Routine: Morning Brief -->

   ### Top Priorities

   <verbatim items routed to this slug from 🎯 section>

   ### Meetings and Preparation

   <verbatim items routed to this slug from 🗓️ section>

   ### Critical Risks and Follow-ups

   <verbatim items routed to this slug from ⚠️ section, preserving sub-headers
   like "Infrastructure and Technical Debt" if present>
   ```

   Skip subsections that have no items routed to this slug.

5. Skip the `tags:` frontmatter field. The Tag Registry is strict — leave tagging to `/wiki ingest`.

## Step 6: Build the session TodoWrite list

Skip this step if `--no-todos` is set.

<!-- TODO: Jeremy — define which brief items become session todos and at what -->
<!-- granularity. Possible mappings: -->
<!-- -->
<!-- (a) Every Top Priority bullet → one todo. Sub-bullets become separate todos -->
<!--     when each is independently actionable (e.g., VC-313 and VC-385 are -->
<!--     separate todos, not a combined "S3 Bucket Policy Implementation" todo). -->
<!--     Critical Risks with explicit deadlines (RDS EOL July 31) → todo with -->
<!--     deadline noted. Meetings → todos only when prep is required. -->
<!-- -->
<!-- (b) Top-level only — sub-bullets stay as activeForm context. Less granular, -->
<!--     less satisfying to check off, but matches how the brief reads. -->
<!-- -->
<!-- (c) Hybrid — Top Priorities at sub-bullet granularity (because those are -->
<!--     the day's actual work units), Critical Risks at top level (because -->
<!--     they're flags, not tasks), Meetings only if prep is mentioned. -->
<!-- -->
<!-- Pick one and fill in this step with the chosen mapping rule. The default -->
<!-- expectation in the rest of the skill is option (c) — adjust if you pick -->
<!-- something else. -->

After building the list, call `TodoWrite` once with all todos. Each todo's `content` is the imperative form ("Unblock MR !500 in ft-quoting"), `activeForm` is the present-continuous form ("Unblocking MR !500 in ft-quoting"), and `status` starts as `pending`.

## Step 7: Surface time-critical risks for explicit review

Identify items with hard deadlines or blocking dependencies and print them for Jeremy's acknowledgment. These are the items most likely to slip if buried in prose. Format:

- **<deadline or trigger>**: <brief description> — routed to `<slug>`.

Examples from a typical brief:
- **July 31 EOL**: RDS MySQL 8.0 on georgies-kitchen-development account hits standard end-of-life. Upgrade now to avoid extended support charges Aug 1 — routed to `<slug>`.
- **Blocking**: MR !500 CI failure blocking Dematic-style auto-merge — routed to `alertventure/ft-quoting`.

If no time-critical items exist, omit this section.

## Step 8: Confirm

Print a tight summary:

- Files written (full paths) with create/append status.
- Counts: N priorities, M meetings, K risks; T todos populated (or "skipped per --no-todos").
- New slugs created (if any) — flag for awareness.
- Any routing failures or `unknown/*` slugs that need review.
- Any parse warnings (schema fallback, missing emoji headers, etc.).

Then ask: "Anything to escalate? (file as durable wiki page / append to MEMORY.md / none)". On approval, execute via `/wiki capture` for raw items or direct `Assistant/MEMORY.md` edit for memory items. Default expectation is **none** — briefs are operational, not architectural.

## Hard rules

- **Never modify existing raw note bodies** — append-only, frontmatter unchanged. (Per `$WIKI_VAULT/CLAUDE.md`.)
- **Never use the `Write` tool** to edit `Assistant/memory/YYYY-MM-DD.md` — use the `append_to_daily_log` MCP tool. (Per `~/.claude/CLAUDE.md`.) `Assistant/MEMORY.md` is fine to edit directly.
- **Never invent new tags** — only approved tags from the Tag Registry. Propose new ones via `/wiki tag propose`.
- **Preserve prose verbatim** in raw captures — do not summarize or rewrite Littlebird's text.
- **Briefs do not auto-promote to wiki/** — they are operational/session-scoped. `/wiki ingest` should skip these by default; only escalate via Step 8 confirmation.
- **Do not auto-append to the daily log.** Briefs are forward-looking — the day's actual work and decisions get captured by `/littlebird-daily` (retrospective) and `/littlebird-meeting` the following day. The brief is the plan, not the record.
