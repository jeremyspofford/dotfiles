# Course Import — Design Spec

**Date:** 2026-04-15
**Author:** Jeremy Spofford
**Status:** Approved

---

## Problem

The existing `/lecture-note` workflow captures individual lectures as you watch them, but there's no way to see the full course curriculum in Obsidian or know how many videos to watch tonight to stay on schedule. Skipping a night has no consequence — the schedule doesn't adapt.

---

## Solution

Two new files + one small change to the existing command + a Dataview block:

1. **`chrome-ext-course-import.md`** — Chrome extension shortcut prompt that reads the Udemy curriculum sidebar and outputs a structured markdown table
2. **`course-import.md`** — Claude Code slash command that merges the table into `_Index.md`, stores exam/schedule config in frontmatter, and writes `remaining_count` + `remaining_minutes` scalars the Dataview block reads
3. **`lecture-note.md`** — minor update to handle the new Duration column when writing index rows, and to update the remaining scalars after each capture
4. **Dataview block** added to `Study Heatmap.md` — reads frontmatter scalars to compute tonight's watch target

---

## Architecture

```
Udemy page (player or overview — curriculum visible in both)
  → Chrome ext /course-import prompt reads curriculum sidebar
  → Outputs markdown table: lecture #, title, section, duration
  → User pastes into Claude Code /course-import
  → Merges with _Index.md (preserves complete rows, adds new as todo)
  → Stores exam_date, study_days, remaining_count, remaining_minutes in _Index.md frontmatter
  → Dataview block in Study Heatmap.md reads frontmatter scalars — no table parsing needed
```

---

## Component 1: Chrome Extension Prompt

**File:** `claude/.claude/prompts/chrome-ext-course-import.md`
**Trigger:** `/course-import` shortcut saved in Claude Chrome extension

**Behavior:**
- Reads the full course curriculum from whatever is visible: player sidebar or course overview curriculum section
- Includes lectures and hands-on labs; skips quizzes and coding exercises
- Normalizes duration to whole minutes (e.g. `5:23` → `5m`, `1:02:15` → `62m`)
- Uses Udemy's displayed lecture numbers if visible; otherwise sequences from 1
- Infers cert folder name from course title (e.g. "Ultimate AWS Certified Solutions Architect Associate" → `AWS SAA`)

**Output format:**
```
## Course Import: <Course Title>
> cert: <cert-folder-name>
> platform: Udemy

| # | Title | Section | Duration |
|---|---|---|---|
| 31 | Budget Setup | 5 - EC2 Fundamentals | 3m |
| 32 | EC2 Basics | 5 - EC2 Fundamentals | 11m |
```

The `cert` field is the vault subfolder name under `Learning/` (e.g. `AWS SAA`, `CKA`). Claude Code validates this against what actually exists before proceeding.

---

## Component 2: `/course-import` Command

**File:** `claude/.claude/commands/course-import.md`

**Inputs:** Pasted extension output (markdown table with header block)

**Steps:**

### 1. Parse
Extract from the pasted markdown:
- Course title
- Cert folder name (from `> cert:` line)
- Full lecture table (columns: #, Title, Section, Duration)

### 2. Locate and validate vault path
Resolve cert folder: `$WIKI_VAULT/Learning/<cert>/`

**Cert validation:** List the actual directories under `$WIKI_VAULT/Learning/`. If the inferred cert name doesn't match any of them exactly, show the user the available options and ask them to confirm the correct folder before continuing. Never operate on a folder that doesn't exist.

Read existing `_Index.md`. If it doesn't exist, error and stop.

### 3. First-run setup
Check if `exam_date` frontmatter field exists in `_Index.md`.

If the existing `target_date` field is present but `exam_date` is not, read `target_date` as the starting value and ask the user to confirm or update it to a full date (e.g. `2026-05` → `2026-05-25`).

If neither exists, ask the user:
- **Exam target date** (e.g. `2026-05-25`)
- **Study days** for this cert (e.g. `Mon, Wed, Fri`)

Store in `_Index.md` frontmatter:
```yaml
exam_date: 2026-05-25
study_days: [Mon, Wed, Fri]
```

### 4. Merge lectures
Match by title (case-insensitive, trimmed whitespace). For each imported lecture:

| Match | Action |
|---|---|
| Exists, status `complete` | Preserve all fields; add Duration if column is missing |
| Exists, status `todo` | Update Duration if missing; leave status/confidence intact |
| Not found | Add new row: `status: todo`, `confidence: —`, Duration from import |

Rows in the existing index that don't appear in the import are left untouched (handles Udemy course reorganizations without destroying history).

**Title drift detection:** If an imported title has no exact match but has a fuzzy match (>90% similarity, e.g. Levenshtein distance) against an existing `todo` row, warn the user:
```
Warning: "EC2 Basics Hands On" (import) closely matches "EC2 Basics - Hands On" (index).
Treating as new row. If this is the same lecture, manually merge and remove the duplicate.
```
Do not auto-merge on fuzzy match — let the user decide.

### 5. Write `_Index.md`
Updated table schema (6 columns):
```
| # | Title | Section | Duration | Status | Confidence |
```

Duration stored as integer minutes with `m` suffix (e.g. `5m`, `62m`). Missing durations stored as `—`.

Also update the `## Sections covered` checklist: add any new sections found in the import.

**Update frontmatter scalars** after every merge:
```yaml
remaining_count: <count of rows where status != complete>
remaining_minutes: <sum of Duration for those rows, as integer>
```

Rows with Duration `—` (no duration data) contribute `0` to `remaining_minutes`. They are counted in `remaining_count` but excluded from the time estimate.

These are what the Dataview block reads. They are always recomputed from scratch on each `/course-import` run, so they stay accurate.

### 6. Report
```
Imported: 94 lectures (67 new, 27 already in index)
Complete: 16 preserved
Duration: 8h 42m total, 7h 15m remaining
_Index.md updated.
```

---

## Component 3: `lecture-note.md` Update

**File:** `claude/.claude/commands/lecture-note.md`

**Change to Step 4 (Update the _Index.md):**

When writing a row to the index, use the 6-column format:
```
| NN | [[Lecture NN - Title]] | Section Name | — | complete | — |
```

Column order: `#`, `Title`, `Section`, `Duration`, `Status`, `Confidence`. Duration is always `—` when written by `/lecture-note` (duration isn't available from the transcript).

If the lecture already exists in the index (added by a prior `/course-import` run), update its Status to `complete` and preserve Duration. Do not add a duplicate row.

After updating the table, recompute and update the `remaining_count` and `remaining_minutes` frontmatter scalars (decrement by the newly completed lecture's values).

---

## Component 4: Dataview Block

**File:** `~/Obsidian_Vault/Learning/AWS SAA/Study Heatmap.md`
**Position:** New section at the top, before the heatmap calendar

**Logic:** Reads scalar frontmatter values from `_Index.md` — no raw file parsing, no table traversal.

1. Read `_Index.md` frontmatter: `exam_date`, `study_days`, `remaining_count`, `remaining_minutes`
2. Count remaining occurrences of `study_days` weekdays between today and `exam_date` (inclusive of today if it's a study day and no lecture has been captured yet today)
3. Compute: `ceil(remaining_count / remaining_days)` → tonight's lecture count
4. Compute: `ceil(remaining_minutes / remaining_days)` → tonight's minutes

**Reading frontmatter from another file in DataviewJS:**
```js
const idx = dv.page("Learning/AWS SAA/_Index")
const examDate = idx.exam_date
const remaining = idx.remaining_count
const remainingMin = idx.remaining_minutes
const studyDays = idx.study_days  // e.g. ["Mon", "Wed", "Fri"]
```

This is standard DataviewJS — `dv.page()` returns a page object with all frontmatter fields. No `app.vault.read()` needed.

Note: this Dataview block is cert-specific. Each cert's `Study Heatmap.md` needs its own block pointing at its own `_Index` path.

**Display:**
```
Tonight's Target
──────────────────────────
Watch 3 lectures (~28 min)
42 remaining · 18 study days left · exam 2026-05-25
──────────────────────────
```

**Edge cases:**
- `remaining_days = 0`: show "Exam is today (or past) — review weak spots"
- `remaining_count = 0`: show "All lectures complete — run practice exams"
- `_Index.md` missing `exam_date` or `remaining_count`: show "Run /course-import to set up schedule"

---

## Files to Create / Modify

| Action | File | Notes |
|---|---|---|
| Create | `claude/.claude/prompts/chrome-ext-course-import.md` | New extension shortcut |
| Create | `claude/.claude/commands/course-import.md` | New slash command |
| Modify | `claude/.claude/commands/lecture-note.md` | 6-column row format + update remaining scalars in Step 4 |
| Modify | `~/Obsidian_Vault/Learning/AWS SAA/Study Heatmap.md` | Add Tonight's Target block |
| Modify | `~/Obsidian_Vault/Learning/AWS SAA/_Index.md` | Add Duration column + frontmatter fields |

All dotfiles changes stowed via the `claude` package.

---

## Out of Scope

- Support for platforms other than Udemy (add later)
- Automatic sync (user triggers `/course-import` manually)
- Modifying the heatmap calendar itself
- `/lecture-note` capturing video duration from the player

---

## Success Criteria

1. Running `/course-import` from a Udemy page populates `_Index.md` with all course lectures and their durations in under 2 minutes
2. Re-running `/course-import` after watching lectures preserves all `complete` rows
3. `Study Heatmap.md` shows an accurate "Watch X lectures tonight" target that increases automatically after a skipped night
4. Title drift warnings surface when Udemy renames a lecture, preventing silent duplicates
5. The existing `/lecture-note` flow still works without modification to the user's workflow
