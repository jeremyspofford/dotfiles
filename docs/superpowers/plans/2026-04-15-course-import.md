# Course Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `/course-import` Chrome extension shortcut + Claude Code slash command that imports a full Udemy course curriculum into `_Index.md` and drives a live "tonight's target" Dataview block in `Study Heatmap.md`.

**Architecture:** The Chrome extension prompt reads the Udemy curriculum sidebar and outputs a structured markdown table. The user pastes that into `/course-import`, which merges it into `_Index.md` (preserving completed rows), stores exam config and remaining-lecture scalars in frontmatter, and writes the Dataview block that reads those scalars to compute tonight's target. The existing `/lecture-note` command gets a small update to maintain the scalars on each capture.

**Tech Stack:** Markdown prompt files (Claude Code commands), DataviewJS (Obsidian plugin), YAML frontmatter

**Spec:** `docs/superpowers/specs/2026-04-15-course-import-design.md`

---

## File Map

| Action | File | Responsibility |
|---|---|---|
| Create | `claude/.claude/prompts/chrome-ext-course-import.md` | Chrome extension shortcut — reads Udemy curriculum, outputs table |
| Create | `claude/.claude/commands/course-import.md` | Slash command — merges curriculum into `_Index.md`, sets frontmatter scalars |
| Modify | `claude/.claude/commands/lecture-note.md` | Update Step 4 to write 6-column rows and decrement remaining scalars |
| Modify | `~/Obsidian_Vault/Learning/AWS SAA/Study Heatmap.md` | Add Tonight's Target DataviewJS block at top |
| Modify | `~/Obsidian_Vault/Learning/AWS SAA/_Index.md` | Add frontmatter fields (`exam_date`, `study_days`, `remaining_count`, `remaining_minutes`) |

Note: vault files (`Study Heatmap.md`, `_Index.md`) are outside the dotfiles repo — edit them directly. Dotfiles changes stow via the `claude` package.

---

## Task 1: Chrome Extension Prompt

**Files:**
- Create: `claude/.claude/prompts/chrome-ext-course-import.md`

- [ ] **Step 1: Create the prompt file**

```markdown
# Chrome Extension — Course Import Shortcut

Body for a Claude Chrome extension shortcut. Set up once via the extension's shortcut/prompt settings; trigger from any Udemy course page (video player or course overview) where the curriculum is visible.

## How to install in the Chrome extension

1. Open Claude Chrome extension settings → Shortcuts (or "Saved prompts")
2. Create a new shortcut named **course-import**
3. Paste the prompt body below
4. Save. Trigger from any Udemy page with the curriculum sidebar or curriculum section visible.

## Prompt body

---

You are helping me import a full Udemy course curriculum into my Obsidian study vault. I'm Jeremy Spofford — Senior DevOps engineer studying for cloud/DevOps certifications.

## Step 1: Read the curriculum

Read the full course curriculum from this page. It may appear in:
- The **sidebar** on the video player page (collapsible section list on the left)
- The **curriculum section** on the course overview/landing page (expandable section list)

Expand all collapsed sections before reading so you have the full list.

Include: video lectures, hands-on labs.
Skip: quizzes, coding exercises, practice tests — anything that is not a video lecture.

## Step 2: Infer the cert folder

From the course title, infer the cert folder name used in my Obsidian vault:
- "Ultimate AWS Certified Solutions Architect Associate" → `AWS SAA`
- "Certified Kubernetes Administrator (CKA)" → `CKA`
- Use your best judgment for other courses. I will confirm if wrong.

## Step 3: Output the curriculum table

Output a single markdown code block in this exact format:

```markdown
## Course Import: <Course Title>
> cert: <cert-folder-name>
> platform: Udemy

| # | Title | Section | Duration |
|---|---|---|---|
| 31 | Budget Setup | 5 - EC2 Fundamentals | 3m |
| 32 | EC2 Basics | 5 - EC2 Fundamentals | 11m |
```

Rules:
- Use Udemy's displayed lecture numbers if visible. If not, sequence from 1.
- Duration: normalize to whole minutes. `5:23` → `5m`. `1:02:15` → `62m`. Round up.
- Section: use the section number and title exactly as shown (e.g. `5 - EC2 Fundamentals`).
- Title: use the lecture title exactly as shown on Udemy.
- One row per lecture. Section name goes in the Section column — no section header rows.

## Step 4: Brief report

After the code block, 2 lines:
- Total lectures found
- Any sections where duration data was missing or unclear
```

- [ ] **Step 2: Verify file exists in the right location**

```bash
ls claude/.claude/prompts/
```

Expected: `chrome-ext-course-import.md` appears alongside `chrome-ext-lecture-note.md`.

- [ ] **Step 3: Commit**

```bash
git add claude/.claude/prompts/chrome-ext-course-import.md
git commit -m "feat(study): add course-import Chrome extension shortcut prompt"
```

---

## Task 2: `/course-import` Slash Command

**Files:**
- Create: `claude/.claude/commands/course-import.md`

- [ ] **Step 1: Create the command file**

```markdown
Import a full Udemy course curriculum into the vault and set up the dynamic study schedule.

Usage: /course-import <paste the markdown output from the Chrome extension course-import shortcut>

The user will paste output generated by the Chrome extension. Your job:

## 1. Parse

Extract from the pasted markdown:
- Course title (from the `## Course Import: <title>` line)
- Cert folder name (from the `> cert: <name>` line)
- Lecture table (all rows under the `| # | Title | Section | Duration |` header)

## 2. Validate cert folder

List actual directories under `$WIKI_VAULT/Learning/`:

```bash
ls "$WIKI_VAULT/Learning/"
```

If the cert folder from the import exactly matches one of those directories, proceed.

If it doesn't match, show the user the available options and ask which folder to use:
```
The imported cert "AWS SAA" doesn't match any folder in $WIKI_VAULT/Learning/.
Available: [list them]
Which folder should this import go to?
```

Wait for confirmation before continuing. Never operate on a folder that doesn't exist.

Read `$WIKI_VAULT/Learning/<cert>/_Index.md`. If it doesn't exist, stop and tell the user.

## 3. First-run setup

Check the `_Index.md` frontmatter for `exam_date`.

**If `exam_date` already exists:** skip setup entirely, use existing values.

**If `target_date` exists but `exam_date` does not:**
Ask: "Your current target_date is `<value>`. What's the full exam date? (e.g. `2026-05-25`)"
Ask: "Which days of the week are study days for this cert? (e.g. `Mon, Wed, Fri`)"

**If neither exists:**
Ask: "What's your target exam date? (e.g. `2026-05-25`)"
Ask: "Which days of the week are study days for this cert? (e.g. `Mon, Wed, Fri`)"

Store in `_Index.md` frontmatter:
```yaml
exam_date: YYYY-MM-DD
study_days: [Mon, Wed, Fri]
```

## 4. Merge lectures

Match imported lectures to existing index rows by title (case-insensitive, trimmed whitespace).

For each imported lecture, apply the first matching rule:

| Condition | Action |
|---|---|
| Exact title match, status `complete` | Preserve all fields. If Duration column didn't exist yet, add it with the imported duration. |
| Exact title match, status `todo` | Update Duration if the cell is `—`. Leave status and confidence intact. |
| No exact match, fuzzy match >90% against any existing `todo` row | Warn the user (see below). Add as new `todo` row anyway. |
| No match | Add new row: `status: todo`, `confidence: —`, Duration from import. |

Rows in the existing index that don't appear in the import are left untouched.

**Fuzzy match warning format** (note: `(index, todo)` and "Adding as" are intentional refinements over the spec's example — they clarify why the match is flagged):
```
Warning: "EC2 Basics Hands On" (import) closely matches "EC2 Basics - Hands On" (index, todo).
Adding as new row. If these are the same lecture, manually merge and remove the duplicate.
```

## 5. Write _Index.md

Write the updated table with the 6-column schema:
```
| # | Title | Section | Duration | Status | Confidence |
```

Duration format: integer minutes with `m` suffix (e.g. `5m`, `62m`). Missing durations: `—`.

Update the `## Sections covered` checklist: add any new sections from the import as `⬜ Section N — Title`.

Compute and write frontmatter scalars:
```yaml
remaining_count: <count of rows where Status != complete>
remaining_minutes: <sum of Duration integers for those rows; treat — as 0>
```

## 6. Report

```
Imported: <total> lectures (<new> new, <existing> already in index)
Complete: <n> preserved
Duration: <total_h>h <total_m>m total, <rem_h>h <rem_m>m remaining
_Index.md updated.
```

List any fuzzy-match warnings after the report.
```

- [ ] **Step 2: Verify the command is recognized**

```bash
ls claude/.claude/commands/ | grep course
```

Expected: `course-import.md` appears.

- [ ] **Step 3: Commit**

```bash
git add claude/.claude/commands/course-import.md
git commit -m "feat(study): add /course-import slash command"
```

---

## Task 3: Update `lecture-note.md` for Duration Column

**Files:**
- Modify: `claude/.claude/commands/lecture-note.md`

The existing Step 4 writes a 5-column row format. It needs to handle the new 6-column schema and maintain the remaining scalars.

- [ ] **Step 0: Pre-edit verification**

Before editing, confirm the target block exists verbatim:

```bash
grep -c "Format: \`| NN | \[\[Lecture NN" claude/.claude/commands/lecture-note.md
```

Expected output: `1`. If output is `0`, the file has changed — read the current Step 4 and adjust the replacement accordingly before continuing.

- [ ] **Step 1: Update Step 4 in `lecture-note.md`**

Replace the existing Step 4 block:

```markdown
## 4. Update the _Index.md

- Add a row to the Lectures table in the cert folder's `_Index.md`
- Format: `| NN | [[Lecture NN - Title]] | Section Name | complete | — |`
- Update the Sections covered checklist if this lecture changes a section's status
```

With:

```markdown
## 4. Update the _Index.md

Check whether the `_Index.md` Lectures table has a Duration column (6 columns) or not (5 columns).

**If the lecture already exists in the index (added by a prior `/course-import` run):**
- Find the row by lecture number or title
- Update its Status to `complete`; preserve the existing Duration value
- Do not add a duplicate row

**If adding a new row to a 6-column table:**
```
| NN | [[Lecture NN - Title]] | Section Name | — | complete | — |
```

**If adding a new row to a 5-column table (pre-course-import):**
```
| NN | [[Lecture NN - Title]] | Section Name | complete | — |
```

Update the Sections covered checklist if this lecture completes a section.

**Update remaining scalars** (only if `remaining_count` exists in `_Index.md` frontmatter):
- Read the completed row's Duration value
- Decrement `remaining_count` by 1
- If Duration was a numeric value (not `—`), parse the integer and decrement `remaining_minutes` by that amount
- Write both updated values back to frontmatter
```

- [ ] **Step 2: Verify the edit is clean**

```bash
grep -n "remaining_count\|6-column\|Duration column" claude/.claude/commands/lecture-note.md
```

Expected: all three terms appear in the file.

- [ ] **Step 3: Commit**

```bash
git add claude/.claude/commands/lecture-note.md
git commit -m "feat(study): update /lecture-note to handle Duration column and remaining scalars"
```

---

## Task 4: Add Tonight's Target Block to Study Heatmap

**Files:**
- Modify: `~/Obsidian_Vault/Learning/AWS SAA/Study Heatmap.md`

- [ ] **Step 1: Add the DataviewJS block at the top of Study Heatmap.md**

Insert this section at the very top of the file, before the existing `# Study Heatmap` heading:

````markdown
## Tonight's Target

```dataviewjs
const idx = dv.page("Learning/AWS SAA/_Index")

if (!idx || !idx.exam_date || idx.remaining_count === undefined) {
  dv.paragraph("> [!info] Tonight's Target\n> Run `/course-import` to set up the study schedule.")
} else {
  const examDate = new Date(idx.exam_date)
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  examDate.setHours(0, 0, 0, 0)

  const remaining = idx.remaining_count
  const remainingMin = idx.remaining_minutes || 0

  const dayMap = { Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6 }
  const rawDays = Array.isArray(idx.study_days) ? idx.study_days : [idx.study_days]
  const studyDayNums = rawDays.map(d => dayMap[d]).filter(d => d !== undefined)

  let studyDaysLeft = 0
  const cursor = new Date(today)
  while (cursor <= examDate) {
    if (studyDayNums.includes(cursor.getDay())) studyDaysLeft++
    cursor.setDate(cursor.getDate() + 1)
  }

  if (studyDaysLeft === 0) {
    dv.paragraph("> [!warning] Exam is today (or past) — review weak spots.")
  } else if (remaining === 0) {
    dv.paragraph("> [!success] All lectures complete — run practice exams.")
  } else {
    const n = Math.ceil(remaining / studyDaysLeft)
    const m = Math.ceil(remainingMin / studyDaysLeft)
    const msg =
      `> [!info] Tonight's Target\n` +
      `> Watch **${n} lecture${n === 1 ? "" : "s"}** (~${m} min)\n` +
      `> ${remaining} remaining · ${studyDaysLeft} study days left · exam ${idx.exam_date}`
    dv.paragraph(msg)
  }
}
```

---

````

- [ ] **Step 2: Verify the file opens without syntax errors**

Open `Study Heatmap.md` in Obsidian. Confirm:
- The callout renders (even if it says "Run /course-import to set up the schedule" since `exam_date` isn't set yet)
- No DataviewJS error in the block
- The existing heatmap calendar below it still renders

- [ ] **Step 3: No commit needed** — vault files are outside the dotfiles repo.

---

## Task 5: Bootstrap _Index.md and Do First Run

**Files:**
- Modify: `~/Obsidian_Vault/Learning/AWS SAA/_Index.md`

This task wires everything together. The `/course-import` command handles the frontmatter and column migration — this task verifies the end-to-end flow.

- [ ] **Step 0: Pre-flight — read current _Index.md state**

```bash
head -30 ~/Obsidian_Vault/Learning/AWS\ SAA/_Index.md
```

Confirm:
- The file exists and has valid YAML frontmatter
- The Lectures table is present (look for the `| # | Title |` header)
- Note how many columns the table currently has (5 = pre-import, 6 = already migrated)

If the frontmatter or table is malformed, fix it manually before running `/course-import`.

- [ ] **Step 1: Open the Udemy AWS SAA course page in Chrome**

Navigate to the course (player page or overview). Confirm the curriculum sidebar or curriculum section is visible.

- [ ] **Step 2: Run the extension shortcut**

Trigger the `course-import` shortcut in the Claude Chrome extension. Verify the output contains:
- `## Course Import: Ultimate AWS Certified Solutions Architect Associate`
- `> cert: AWS SAA`
- A table with `#`, `Title`, `Section`, `Duration` columns
- Rows starting from where IAM left off (lecture 31 or similar)

If the table is missing sections or truncated: manually expand all curriculum sections on the Udemy page and re-trigger the shortcut. If duration data is absent for some sections, note them — the import can proceed with `—` for those rows.

- [ ] **Step 3: Run `/course-import` in Claude Code**

Paste the extension output. Walk through the prompts:
- Confirm cert folder: `AWS SAA`
- Set exam date: `2026-05-25`
- Set study days: `Mon, Wed, Fri`

- [ ] **Step 4: Verify _Index.md was updated**

Check `~/Obsidian_Vault/Learning/AWS SAA/_Index.md`:

```bash
head -20 ~/Obsidian_Vault/Learning/AWS\ SAA/_Index.md
```

Verify frontmatter contains:
```yaml
exam_date: 2026-05-25
study_days: [Mon, Wed, Fri]
remaining_count: <some number>
remaining_minutes: <some number>
```

Also verify the Lectures table now has 6 columns with Duration populated.

- [ ] **Step 5: Verify Study Heatmap shows the target**

Open `Study Heatmap.md` in Obsidian. The Tonight's Target block should now show something like:
```
Watch 3 lectures (~28 min)
94 remaining · 18 study days left · exam 2026-05-25
```

- [ ] **Step 6: Stow the dotfiles changes**

```bash
stow -d ~/workspace/dotfiles -t ~ claude
```

Verify no errors (WSL stow warnings about BUG in find_stowed_path are harmless).

---

## Verification Scenarios

After Task 5 completes, manually verify these edge cases:

| Scenario | How to test | Expected |
|---|---|---|
| Skip a night | Note that `remaining_count` stays same, check heatmap next day | Tonight's Target count increases |
| Watch a lecture | Run `/lecture-note`, open Study Heatmap | remaining_count decrements by 1 |
| Re-run course-import | Run `/course-import` again with full curriculum | Completed rows preserved, counts updated |
| Title drift | Manually add a row with a similar-but-different title to index, run course-import | Warning shown, duplicate row added |
| All complete | Set all rows to complete | "All lectures complete" callout |
| Exam date past | Set exam_date to a past date | "Exam is today (or past)" callout |
