Generate a structured job application page from a clipping, with requirements crosswalk against Jeremy's career entity, gap rebuttals, STAR stories pre-mapped to requirements, tiered interviewer questions, and talking points. Move the clipping to `raw/personal/job-search/` and wire bidirectional links.

Usage: `/apply-to-job [path-to-clipping]`

- If no path given: list all files in `$WIKI_VAULT/clippings/` that look like job postings (have a `source:` URL in frontmatter, H2 or H1 containing role-ish words: Engineer/Manager/Developer/Architect/Lead/Director). If exactly one, use it. If multiple, ask which. If none, stop.
- If the clipping already has `ingested: true`, warn the user and stop.
- If an application page with the derived slug already exists, warn and stop — don't silently overwrite.

## 1. Load context

Read in parallel:

- The clipping file
- `$WIKI_VAULT/wiki/entities/jeremy-spofford-career.md` — skills inventory + Notable Accomplishments + Context Notes (the source of truth)
- `$WIKI_VAULT/Assistant/USER.md` — personality + de-emphasis rules
- `$WIKI_VAULT/Assistant/MEMORY.md` — current career state
- `$WIKI_VAULT/CLAUDE.md` — Tag Registry (authoritative list)
- `$WIKI_VAULT/wiki/projects/applications/avive-senior-devops.md` — gold-standard reference page for format/tone. Match its structure.

## 2. Parse the clipping

Extract:

- **Company**: from title (split on " - " or " @ " or "at ") or H1/H2
- **Role**: the other half of the title/heading
- **Source URL**: `source:` frontmatter field
- **Salary range**: regex body for patterns like `\$[\d,]+\s*[-–]\s*\$[\d,]+` or "Anticipated salary range"; `"not listed"` if absent
- **Required vs Preferred requirements**: parse bullets under headings matching `/required|essential|must.?have|qualifications/i` (required) and `/preferred|nice.?to.?have|bonus/i` (preferred). If only one list is present, treat as required.
- **Company intel**: first 1-2 paragraphs of any "About Us" section, or the JD's opening paragraphs
- **Tech stack signals**: named tools, languages, cloud providers, observability stacks

Slugs (lowercase, hyphenated, no spaces):

- `{company-slug}` — e.g., "Avive Solutions" → `avive`; "Prompt Health" → `prompt-health`
- `{role-slug}` — e.g., "Senior DevOps Engineer" → `senior-devops`; "Staff Platform Engineer" → `staff-platform`
- `{page-slug}` = `{company-slug}-{role-slug}` — final filename stem

## 3. Generate the requirements crosswalk

For **every** required and preferred line item:

- Match against the career entity skills inventory + accomplishments
- Classify: **Strong** / **Partial** / **Gap**
- Write a concrete evidence cell — years, specific project, named accomplishment. Don't hand-wave.
- Flag the strongest unique match (if any) as **Strong (signature)** — at most one per application, the unicorn hook.

Present as two tables (Required, Preferred) with columns: `#`, `Requirement`, `My Profile`, `Match`, `Evidence`.

Tally at the end of each table: `Required scoring: X Strong / Y Partial / Z Gap.`

## 4. Gaps & Rebuttals

For each Partial or Gap, write a first-person rebuttal in a blockquote (1-3 sentences):

- Name the gap honestly
- Anchor to transferable experience (named projects, years, similar tech)
- Give ramp-time estimate if relevant ("days to weeks", "weeks to months")
- Don't overclaim. "Rusty" is rusty; "never used" is never used.

## 5. STAR Stories Queued

From the career entity's **Notable Accomplishments** section, pick 5-7 most relevant to this JD. For each, write:

```
### N. {Title} ({SIGNATURE — use early} if applicable)
**S**: Situation
**T**: Task
**R**: Action
**R**: Result
**Maps to**: Required #N / Preferred #N — how to deploy it
```

The SIGNATURE story is the one matching the **Strong (signature)** crosswalk row. Flag only one.

## 6. Questions for the Interviewer

Tiered by audience. Draw specifics from the JD — reference named tools, stated responsibilities, company context. No generic questions.

- **For the hiring manager / team lead**: team shape, scope/IC-vs-lead, pain points, cadence, on-call
- **For engineering leadership**: architecture direction, compliance posture, security ownership
- **For peer engineers**: observability, tool friction, GitOps maturity, stack-specific probes
- **For the recruiter / HR**: location, remote policy, interview loop, timeline

5-15 questions total. Prioritize within each tier.

## 7. Talking Points for Jeremy

Four subsections:

- **Lead With**: 3-5 strongest hooks (signature story, measurable outcomes, ownership framing)
- **De-emphasize**: things to keep off-lead. **Always check the career entity's Context Notes** for per-topic rules (e.g., "Aria Labs off-lead") and propagate them here.
- **Avoid**: overclaims, dated experience, irrelevant threads
- **Cultural Notes**: if the company is mission-driven, regulated, in a distinctive vertical, or has a visible cultural pattern — name it and advise how to engage authentically

## 8. Write the application page

Path: `$WIKI_VAULT/wiki/projects/applications/{page-slug}.md`

Frontmatter:

```yaml
---
title: {Company} — {Role}
type: project
tags: [personal, {cloud-tag-if-applicable-and-registered}]
related: [jeremy-spofford-career, {company-slug}, personal-career-transition]
sources: ["raw/personal/job-search/{page-slug}-jd.md"]
created: {today}
updated: {today}
status: current

company: {Company Full Name}
role: {Role Title}
source_url: {URL}
salary_range: "{as-listed}" | "not listed"
application_status: screen
applied_date:
interview_date:
next_action: {e.g., prep for first interview; confirm remote policy}
---
```

Body — match the Avive page structure exactly:

1. H1 + Summary + Match strength
2. Company Intel (what they do, stage, stack signals, open questions)
3. Requirements Match (Required + Preferred tables)
4. Gaps & Rebuttals
5. STAR Stories Queued
6. Questions for the Interviewer
7. Talking Points for Jeremy
8. Interview Rounds (empty table with header row: Round, Date, With, Format, Focus, Outcome, Notes)
9. Follow-ups (checklist of 4-6 standard items: thank-you email, LinkedIn research, press research, confirm logistics)
10. Related (wikilinks: career, career-transition, company entity, `{page-slug}-jd` for raw JD + external URL)

## 9. Company entity — create or update

Path: `$WIKI_VAULT/wiki/entities/{company-slug}.md`

**If missing**, create using the entity template. Sections:

- One-paragraph description (what they do, mission)
- Snapshot (industry, stage, product, URL, funding signal)
- Tech Stack (inferred from JD)
- Context for Jeremy (stack overlap, fit notes, recruitment status)
- Related (wikilink back to the application page + career entity)

**If exists**, update only: append to "Related" a link to this new application page; refresh `updated:` date. **Preserve** any existing context notes — they were added deliberately.

## 10. Move and backlink the clipping

1. `mkdir -p $WIKI_VAULT/raw/personal/job-search/`
2. Move: `$WIKI_VAULT/clippings/{original-filename}.md` → `$WIKI_VAULT/raw/personal/job-search/{page-slug}-jd.md`
3. Augment moved file's frontmatter (preserve everything already there, add these fields):

```yaml
source_project: personal/job-search
captured_date: {original `created:` date, or today if absent}
session_context: "Job posting captured via Web Clipper — {Role} at {Company}"
ingested: true
ingested_date: {today}
ingested_into: "[[{page-slug}]]"
```

Also append `"job-posting"` to the tags list.

Never modify the body of the clipping.

## 11. Update indexes

**`wiki/projects/index.md`** — add under a "Job Applications" section. Create the section if it doesn't exist (place after the main list). Format:

```
- [[{page-slug}]] — {Company} · {Role} · **{status}** · {one-line stack summary from JD}
```

Bump the frontmatter `updated:` date.

**`wiki/entities/index.md`** — only if the company entity was created this run:

```
- [[{company-slug}]] — {one-line company summary}; active application target
```

Bump `updated:` date.

## 12. Append to wiki/log.md

Insert **after** the log header lines and **before** the most recent `## [YYYY-MM-DD]` entry (newest first, per existing pattern):

```
## [{today}] capture | {Company} {Role} application — {required-strong}/{required-total} required, {preferred-strong}/{preferred-total} preferred matched strong

Source: `raw/personal/job-search/{page-slug}-jd.md`

Created:
- projects/applications/{page-slug} — crosswalk, {N} STAR stories, tiered questions, talking points
- entities/{company-slug} — company stub  [omit line if entity pre-existed]

Updated:
- projects/index.md — added to Job Applications
- entities/index.md — added {company-slug}  [omit line if entity pre-existed]
```

## 13. Report

Tell the user, concisely:

- **Page**: full path
- **Match**: `{Req-Strong}S / {Req-Partial}P / {Req-Gap}G required; {Pref-Strong}S / {Pref-Partial}P / {Pref-Gap}G preferred`
- **Signature match**: the unicorn hook (or "none flagged" if not applicable)
- **Top gaps**: up to 3, one line each
- **Suggested next action**: specific, from the `next_action` frontmatter value
- **File moves**: source clipping → new raw path

Keep the report under 15 lines. The page itself is the deliverable — don't re-summarize its contents.

---

## Rules

- **Never invent skills or accomplishments.** Ground every crosswalk cell and STAR story in the career entity. If the entity doesn't support a claim, flag it as a Gap and rebut honestly.
- **Tag Registry is authoritative.** Only use tags from `$WIKI_VAULT/CLAUDE.md`. If a cloud provider isn't registered, fall back to `[personal]` only — don't invent tags.
- **Context Notes propagate.** The career entity's "Context Notes" section contains per-role framing rules (Aria Labs off-lead, AWS-as-arc framing, VividCloud ownership story). Propagate these into the Talking Points section of every application.
- **One signature story per application.** Don't dilute the unicorn. Pick the single strongest unique match and flag only that one.
- **Honesty over optimism in gaps.** "Rusty" is rusty. "Never used" is never used. Ramp estimates must be defensible.
- **No orphans.** Every artifact created must have bidirectional links — application ↔ entity, application ↔ raw JD, indexes updated.
- **Overwrite protection.** If the target application page already exists, stop and warn. Don't clobber prior work (or user edits).
- **Never modify clipping body.** Frontmatter augmentation only. The clipping is immutable source.
