Ingest a Littlebird meeting summary into the wiki: parse the structured sections, route by meeting type, append to the day's session capture, optionally archive the transcript, auto-log Jeremy's action items, and surface MEMORY.md candidates and other-assigned follow-ups for review. Wiki page creation (concepts/decisions/entities) is left to `/wiki ingest`.

Usage: `/littlebird-meeting [--date YYYY-MM-DD] [--project SLUG] [--with PERSON[,PERSON...]] [--meeting-type 1on1|project] [--include-transcript]` followed by the pasted summary text. The transcript may follow the summary in the same paste; auto-detected by `[Me]:`/`[Others]:` line shape.

## Input

$ARGUMENTS

If `$ARGUMENTS` contains only flags with no body, ask Jeremy for the summary text (and transcript if `--include-transcript` is set). One line, no filler.

## Step 0: Print help and exit if --help/-h

If `$ARGUMENTS` is exactly `--help`, `-h`, or the only non-empty token (ignoring leading/trailing whitespace) is `--help` or `-h`, print the usage block below to the user and stop immediately. Do not parse the body, do not load conventions, do not call any tools, do not write any files.

```
================================================================================
/littlebird-meeting — Help
================================================================================

Ingest a Littlebird meeting summary into the wiki: parse sections, route by
meeting type, append to the day's session capture, optionally archive the
transcript, auto-log Jeremy's action items, and surface MEMORY.md and
follow-up candidates for review. Wiki page creation is /wiki ingest's job.

Usage:
  /littlebird-meeting [OPTIONS]
  <paste summary body here>
  [<paste transcript here, if --include-transcript>]

Options:
  --date YYYY-MM-DD       Meeting date (default: today)
  --project SLUG          Override routing (e.g., vividcloud/general)
  --with PERSON[,...]     Attendee name(s); required for 1:1s or skill prompts
  --meeting-type TYPE     1on1 | project (inferred from attendee count if absent)
  --include-transcript    Also archive the transcript to a separate file under
                          raw/<slug>/transcripts/<date>-<title-slug>-transcript.md
  -h, --help              Show this help and exit

Routing rules:
  - 1:1s route by employer relationship (e.g., vividcloud/general for two VC
    coworkers, regardless of which client topics came up).
  - Project meetings route by client/project context (e.g., vividcloud/dematic).
  - Ambiguous routing → skill prompts for --project rather than guessing.

Body:
  - Paste the summary after the flags. Transcript is optional and auto-detected
    by the [Me]:/[Others]: line shape; included only if --include-transcript
    is set, otherwise it's noted-and-skipped.

Side effects (when not in --help mode):
  - Creates or appends raw/<slug>/<date>-session.md (frontmatter on create only;
    body appended for existing files — never modified above the append point).
  - With --include-transcript: writes raw/<slug>/transcripts/<date>-<title>-transcript.md
    with ingested: true (skips /wiki ingest by design).
  - Auto-appends Action Items assigned to "You"/"Me" to Assistant/memory/<date>.md
    via the append_to_daily_log MCP tool. Other-assigned items surface for review.
  - Surfaces MEMORY.md candidates and other-assigned follow-ups for review.
    Does not propose wiki concept/decision/entity pages — defer to /wiki ingest.

Examples:
  # Default — skill prompts for --with
  /littlebird-meeting
  <paste summary>

  # 1:1 with Nick, include transcript
  /littlebird-meeting --with Nick --meeting-type 1on1 --include-transcript
  <paste summary>

  <paste transcript>

  # Project standup, explicit slug, backdated
  /littlebird-meeting --date 2026-05-03 --project vividcloud/dematic --meeting-type project
  <paste summary>

================================================================================
```

## Step 1: Load shared conventions

Read `$WIKI_VAULT/CLAUDE.md` once at the start of execution. The frontmatter format, project slug rules, Tag Registry, and "never modify raw note bodies" rule come from there. Do not duplicate those rules — defer to that file as the source of truth.

If `$WIKI_VAULT` is unset, stop and say: "WIKI_VAULT is not set. Please check your shell config."

## Step 2: Split summary from transcript

Littlebird may emit either the summary alone, or summary followed by transcript. Detect the split:

- The summary uses markdown headers (`# `, `### `) and bullet/checkbox syntax.
- The transcript is anonymized turn-by-turn dialogue — every line begins with `[Me]:` or `[Others]:`.
- The split point is the first `[Me]:` or `[Others]:` line. Everything before is summary; everything from that line onward is transcript.

Fallback: if the input contains an explicit separator like `--- TRANSCRIPT ---` or `## Transcript`, split there.

If `--include-transcript` is set but no transcript is detected, warn and continue with summary only. If a transcript is detected but `--include-transcript` is not set, ignore the transcript and note in the final confirmation that one was present and skipped.

## Step 3: Resolve metadata

- **Date.** If `--date YYYY-MM-DD` is present, use it. Otherwise default to **today** — meeting summaries are typically written same-day. Strip the flag from the input before parsing.
- **Title.** First `# ` heading line in the summary (e.g., `# Terraform, Dependencies, and Blockers`). If absent, fall back to "Meeting" and flag as a parse warning.
- **Attendees.** Use `--with` if provided. Otherwise: the summary itself is anonymized ("the other participant", "you") — names are usually *not* recoverable from the summary alone. If `--with` is missing, ask: "Who was this meeting with? (comma-separated names)". Do **not** guess from name occurrences in topic content — those are usually third parties mentioned, not attendees.
- **Meeting type.** Use `--meeting-type` if provided. Otherwise infer:
  - 2 attendees (Jeremy + 1 other) → `1on1`
  - 3+ attendees, or title/content mentions "standup", "sync", "design review", "demo", "kickoff" → `project`
  - Ambiguous → ask.

## Step 4: Parse summary sections

Littlebird's meeting summary follows a fixed schema. Extract each section verbatim — preserve prose, bullets, bolding, and quoted lines exactly as Littlebird wrote them. Do not summarize or compress.

Expected sections (any may be absent — skip silently):

- `### Executive Summary` — bullet list of high-level themes.
- `### For You` — Jeremy-relevant digest. Rename to **`### Relevant to Me`** in the capture output.
- `### Topics Discussed` — bolded topic headers with bullets and occasional quoted lines.
- `### Decisions` — bolded subject + decision text.
- `### Action Items` — checkbox list with attribution and `(source: ...)` suffix.
- `### Risks / Open Questions` — bolded category + text.

If the summary doesn't match this schema (no recognizable sections), fall back: write the entire summary verbatim under a single `### Summary` subsection, set `needs-review: true` on the capture frontmatter, and flag the parse failure in the confirmation output.

### Action Items: parse into structured form

Each Action Item line typically matches:

```
- [ ] **<assignee>**: <action text>. (source: transcript)
```

Categorize each by assignee:

- `**You**` / `**Me**` → **Jeremy's commitments** (will auto-flow to daily log in Step 8).
- `**Unassigned**` → surface for review.
- Any other name (e.g., `**Nick**`, `**Anthony**`) → **other person's commitment** — surface for review.

Preserve all items in the capture output regardless of assignee.

## Step 5: Determine routing slug

Apply rules in order. First match wins. Use only existing on-disk slugs where possible — check `$WIKI_VAULT/raw/` for which slugs already exist. If the rule produces a slug that doesn't exist on disk, note it in the confirmation output as a new slug being created (don't block on this).

1. **Explicit override.** If `--project SLUG` is set, use it.
2. **1:1 routing — by employer relationship.** If `meeting_type: 1on1`, route to the **shared employer** of the participants. The 1:1 is a relationship/HR artifact, not a project artifact, regardless of what topics it drifted into. If the employer is unambiguous (e.g., known VividCloud coworker), route to `<employer>/general`:
   - VividCloud coworkers (Nick, etc.) → `vividcloud/general`
   - AlertVenture coworkers → `alertventure/general`
   - Personal/non-work 1:1 → `personal/general`
   - If the partner's employer is unknown, ask.
3. **Project meeting routing — by client/project context.** If `meeting_type: project`, route by the dominant client/project signal in title + content:

   | Signal | Destination |
   |---|---|
   | Dematic / DAP / AIML / Dometic agent platform | `vividcloud/dematic` |
   | Control Tower / EDP | `vividcloud/control-tower` or `vividcloud/edp` |
   | Alertventure / `ft-quoting` | `alertventure/ft-quoting` |
   | Nova / Cortex / Screenpipe / OpenClaw | `nova` |
   | Dotfiles / shell config | `dotfiles` |
   | Personal subdomain (home/family/health/etc.) | `personal/<subdomain>` |

4. **Ambiguous.** If routing can't be confidently determined, prompt for `--project`. Do not guess.

Note the existing on-disk convention: Nova captures live at `raw/nova/`, **not** `raw/arialabs/nova/`. Match existing on-disk paths.

## Step 6: Write the meeting capture

Path: `$WIKI_VAULT/raw/<slug>/<captured_date>-session.md`.

**If the file does not exist**, create it with this frontmatter:

```yaml
---
source_project: <slug>
captured_date: YYYY-MM-DD
session_context: "Littlebird meeting summary"
source: littlebird/meeting
ingested: false
needs-review: false
---
```

**If the file exists**, append only — never modify existing frontmatter or body content above. Use `Read` + `Write` to append, or `Edit` with `replace_all: false` and a unique end-of-file anchor.

Append this heading block (whether the file is new or existing):

```markdown


## [<captured_date>] Meeting: <title>

<!-- Source: Littlebird Routine: Meeting Summary -->
<!-- Type: <1on1|project> | Attendees: Jeremy, <other names> -->
<!-- Transcript: <relative path to transcript file, or "not captured"> -->

### Executive Summary

<verbatim from summary>

### Relevant to Me

<verbatim from summary's "For You" section>

### Topics

<verbatim from summary's "Topics Discussed" section>

### Decisions

<verbatim from summary>

### Action Items

- [ ] **Me**: <text> (source: transcript)
- [ ] **<other>**: <text> (source: transcript)

### Risks / Open Questions

<verbatim from summary>
```

Skip the `tags:` frontmatter field for these captures. The Tag Registry in `$WIKI_VAULT/CLAUDE.md` is strict — leave tagging to `/wiki ingest`, which has the discretion to apply approved tags during downstream processing.

## Step 7: Transcript handling (only if `--include-transcript`)

Path: `$WIKI_VAULT/raw/<slug>/transcripts/<captured_date>-<title-slug>-transcript.md`.

`<title-slug>` is the meeting title lowercased, with non-alphanumeric runs collapsed to a single hyphen (e.g., "Terraform, Dependencies, and Blockers" → `terraform-dependencies-and-blockers`).

Frontmatter:

```yaml
---
source_project: <slug>
captured_date: YYYY-MM-DD
source: littlebird/transcript
meeting_title: "<title>"
meeting_attendees: ["Jeremy", "<other>"]
meeting_type: <1on1|project>
ingested: true
ingested_date: <captured_date>
ingested_note: "transcript — reference material, not for /wiki ingest"
---
```

Body: the verbatim transcript, no preprocessing. Reference this path from the summary capture's `<!-- Transcript: ... -->` comment.

Transcripts default to `ingested: true` so `/wiki ingest` skips them. They're reference material, not synthesis input — the summary already distilled them.

## Step 8: Auto-append Jeremy's Action Items to the daily log

For each Action Item assigned to **You**/**Me**, append to the daily log via the `append_to_daily_log` MCP tool. Do this in **one** call per meeting, not per item.

Tool arguments:

- `source_tool`: `"littlebird-meeting"`
- `session_context`: `"Action items from meeting: <title>"`
- `content`: the action item bullets (1-5), each as `"<text>"` — strip the `(source: transcript)` suffix.

Skip this step if there are no items assigned to You/Me.

Do **not** auto-log items assigned to others or `Unassigned` — those aren't your commitments. Surface them in Step 9 instead.

Never use the `Write` tool to edit `Assistant/memory/<date>.md` directly. The MCP tool maintains the frontmatter `sources: []` array atomically under a file lock; direct writes corrupt concurrent edits.

## Step 9: Surface candidates for review (do NOT auto-write beyond Step 8)

Identify and print these for Jeremy's approval. Each section is optional — omit if empty.

Do **not** surface "durable wiki candidates" or "entity candidates" or suggest concept/decision/entity pages. Wiki page creation belongs to `/wiki ingest`, which sees multiple raw captures and can cross-reference them. This command's job is raw capture + auto-logged action items + MEMORY.md and follow-up signals only.

### MEMORY.md candidates

Durable preferences, stances, or working-style choices that should land in `Assistant/MEMORY.md` (the curated long-term cache). MEMORY.md is the assistant's working memory, not the wiki — `/wiki ingest` does not touch it, so this surface is genuinely additive. Format:

- "<verbatim phrase>" — why it matters in one short clause.

Examples of memory-worthy from a 1:1: explicit career stances ("done with consulting/mercenary work"), tool/vendor preferences with reasoning, learning-style observations ("studying for 20 hours felt energizing — wants more deep-work weekends"), recurring values ("leave the job site better than you found it").

### Other-assigned follow-ups

Action Items assigned to **Other** participants or **Unassigned**. These aren't your commitments to track in your daily log, but you may want visibility. Format:

- **<assignee>**: <follow-up>

People, organizations, services, or tools mentioned in the summary already land in the raw capture verbatim. `/wiki ingest` will discover and create entity pages for those that recur across captures — don't pre-empt that here.

## Step 10: Confirm

Print a tight summary:

- Files written (full paths) with create/append status. Include transcript path if applicable.
- Counts: M memory candidates, K other-assigned follow-ups, A action items auto-logged to daily log.
- Any routing failures or `unknown/*` slugs that need review.
- Any parse warnings (missing title, schema fallback, transcript detected-but-skipped, etc.).

Then ask: "Promote any candidates now? (memory / follow-ups / none)". On approval, execute the relevant action — direct `Assistant/MEMORY.md` edit for memory items, `append_to_daily_log` for follow-ups Jeremy wants to track. Wiki pages are out of scope here; defer to `/wiki ingest`.

## Hard rules

- **Never modify existing raw note bodies** — append-only, frontmatter unchanged. (Per `$WIKI_VAULT/CLAUDE.md`.)
- **Never use the `Write` tool** to edit `Assistant/memory/YYYY-MM-DD.md` — use the `append_to_daily_log` MCP tool. (Per `~/.claude/CLAUDE.md`.) `Assistant/MEMORY.md` (capital, no subdir) is fine to edit directly.
- **Never invent new tags** — only use approved tags from the Tag Registry. Propose new ones via `/wiki tag propose` with explicit approval.
- **Preserve prose verbatim** in raw captures and transcripts — do not summarize or rewrite Littlebird's text.
- **Auto-log only Jeremy's own Action Items** to the daily log — others' commitments surface for review. Vetted commitments by Jeremy bypass the surface-and-wait pattern because they passed both Jeremy's mouth and Littlebird's parser.
- **Transcripts archive separately** under `raw/<slug>/transcripts/` with `ingested: true` from the start — they are reference material for `/wiki query`, not synthesis input for `/wiki ingest`.
- **No wiki page creation here.** Raw captures + transcript archives + MEMORY.md + daily log are the only durable outputs. Concept/decision/entity pages are `/wiki ingest`'s job — it has multi-source context this command lacks. Don't even surface "durable wiki candidates" or "entity candidates" — it sets the wrong expectation.
- **Route 1:1s by employer relationship, not topic.** A 1:1 between two VC employees that drifts into Dematic talk still routes to `vividcloud/general` — the artifact type is "VC-internal relationship", not "Dematic project work".
