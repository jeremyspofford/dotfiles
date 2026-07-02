Generate a stage-specific interview prep artifact (markdown + HTML companion) for a job application Jeremy already has running. Composes from the application page's crosswalk + STAR queue + signature row plus the career entity. Closes with a backfill block surfacing any evidence that should be promoted into `jeremy-spofford-career.md`.

Usage: `/prep-interview <slug> [stage]`

- `<slug>` = the application page stem, e.g. `sardine-devops`, `jellyfish-senior-platform`. Must already exist at `$WIKI_VAULT/wiki/projects/applications/{slug}.md`.
- `[stage]` ∈ `recruiter | technical | hiring-manager | exec`. Default: `recruiter`.

Pre-flight checks (stop with a clear message if any fail):

- Application page exists at `$WIKI_VAULT/wiki/projects/applications/{slug}.md`. If missing, suggest running `/apply-to-job` first.
- Stage is one of the four allowed values. If invalid, list the four and stop.
- If output files (`{slug}-{stage}.md` or `.html`) already exist, warn and ask whether to overwrite. **Never silently clobber.**

## 1. Load context

Read in parallel:

- `$WIKI_VAULT/wiki/projects/applications/{slug}.md` — crosswalk, STAR queue, signature row, gap rebuttals, salary anchor, Lead With (the canonical inputs for this command)
- `$WIKI_VAULT/wiki/entities/jeremy-spofford-career.md` — full Notable Accomplishments pool, Context Notes, skills inventory
- `$WIKI_VAULT/wiki/entities/{company-slug}.md` — company intel; derive `{company-slug}` from the application page's `related:` array
- `$WIKI_VAULT/Assistant/USER.md` — personality + de-emphasis defaults
- `$WIKI_VAULT/Assistant/MEMORY.md` — current career state + recurring framing rules (sole-infra guardrail, IAM trust-policy recall gap, K8s honest framing, Aria Labs off-lead)
- `$WIKI_VAULT/wiki/projects/applications/sardine-devops-call.html` — **gold-standard reference for HTML format, palette, layout, density**. The new command's HTML output matches this style — color-coded panels, header bar, quick-facts strip, three-column primary grid, STAR triggers table, company cheat sheet, print-friendly CSS.
- `$WIKI_VAULT/wiki/projects/applications/sardine-devops.md` Talking Points + STAR Stories sections — gold-standard reference for **what content goes where**.

## 2. Stage-specific section matrix

Compose the artifact from the section set for the chosen stage. **Section identity is consistent across stages; section content shifts.** The HTML companion mirrors the markdown 1:1 — same sections, color-coded panels, dense layout.

### Recruiter (~30 min, non-technical screen)

1. **Opening Script** — 60s + 30s backup. Six beats: Identity → Current → Prior → Signature → Why now → Invitation. Compose from career entity + application page's `summary:`. Bold the load-bearing phrases.
2. **Lead With** (green panel) — 3–5 talking points anchored to the application page's **Strong (signature)** crosswalk row + measurable-outcome stories. Number them.
3. **Salary Script** (yellow panel) — anchor at upper-third of the JD's `salary_range`. Three scripts: when asked for a number, when pushed back, when asked current salary. Hard rule: never disclose current salary (paycut framing).
4. **Don't Volunteer** (red panel) — gap-by-gap deflects, drawn from the application page's "De-emphasize" + "Avoid" sections. Include the Aria Labs off-lead line (always). Each item: the trap + the deflect script in italics.
5. **Questions to Ask** (blue panel, 2-column grid) — non-technical, JD-informed: Product, Growth, Investors, Hiring, Loop, Comp, Their take. 6–8 questions max. Each is JD-specific — reference named tools, stated responsibilities, company context.
6. **STAR Triggers** (grey panel, table) — "if they say X, tell story Y." 5–6 light entries; recruiters rarely go deep. Each row maps trigger keywords → story number + 1-line summary.
7. **Company cheat sheet** — Mission/Product, Customers + Investors as chip rows, Tech stack with simpleicons icons, **Your Stack Overlap** (Strong/Closing/Gap), Regulatory lens.

### Technical (~60–90 min, IC/engineer panel)

1. **Opening Script** — 45s, technical lean. Compress to: Identity → Current technical scope → Prior technical scope → Signature pattern → Invitation. Skip "why now" — they're not screening for fit, they're screening for capability.
2. **STAR Library** (full table, all 9+ stories from the application page) — every story with S/T/A/R compressed to 4 lines, plus the trigger keywords + map-to-requirement column. This is the primary content.
3. **System Design Priming** (green panel) — for each major requirement area in the JD, name the pattern Jeremy has shipped and can whiteboard. E.g., module promotion → Backstage + per-env Terraform; CI velocity → change detection + parallelization + density runners; cost → tiered Cloud Run; reliability → cert automation via Pub/Sub + Secret Manager. 3–5 patterns, each with a 2-line "how I'd draw this on a whiteboard."
4. **Code-Talk Priming** (yellow panel) — language fluency declarations Jeremy will own (Bash daily 7y, TypeScript app-layer, Terraform/HCL 3.6y) vs. what to flag rusty (Python since MMC) vs. what's greenfield (Go). Include a "if they ask for live code" line.
5. **Hard-Problem Rotation** — 3–4 stories pre-mapped to "tell me about a time" prompts: hardest bug, hardest tradeoff, hardest disagreement, biggest impact. Pull from application page STAR queue + career entity Notable Accomplishments.
6. **Gap Rebuttals** (red panel) — copy directly from application page's "Gaps & Rebuttals" section. These are the rehearsable scripts.
7. **Technical Questions to Ask** (blue panel, 2-column grid) — architecture decisions, on-call shape, deploy philosophy, scaling pain, observability spend, GitOps maturity, tool friction. 6–10 questions.
8. **Watch-outs** (red panel, distinct from Don't Volunteer) — recall-under-pressure risks pulled from MEMORY.md (IAM trust-policy `assume_role_policy` `jsonencode` shape — date-stamped via Prompt Health), K8s production gap honest framing, sole-infra framing guardrail (GCP-era ≠ AWS-era).

### Hiring Manager (~45 min, eng director / EM)

1. **Opening Script** — 60s, scope/impact lean. Lead with team shape and ownership, not pattern names.
2. **Why Leaving + Why Us** (purple panel) — two scripts, each ~3 sentences. "Why leaving" frames the paycut + AWS arc + growth-stage motivation without trashing current employer. "Why us" anchors to one specific thing about THIS company (mission, stage, team, customer base) drawn from the company entity.
3. **Leadership-Adjacent Stories** (green panel) — 3–4 cross-team / force-multiplier stories. Lead with #9 Tyler support-call reduction (50% biz-outcome) and the Backstage signature (force multiplier for application teams). Skip the deep-technical stories — they belong in the technical sheet.
4. **Career Arc Framing** (grey panel) — where Jeremy wants to be in 3–5 years. One paragraph. Anchors: senior IC → staff IC → platform-team lead arc (do NOT pre-commit to people management). Reference the GCP→AWS arc as evidence of self-directed specialization choice.
5. **Salary Re-anchor** (yellow panel) — only renders if salary wasn't fully settled in the recruiter call. Same scripts as recruiter sheet, slightly grown up. Drop the current-salary deflect (it's settled by now); keep the anchor + pushback.
6. **Questions to Ask the HM** (blue panel, 2-column grid) — team composition (size, IC vs lead mix, recent hires + departures), recent wins + struggles, the team's #1 pain right now, what does great look like for this hire in 12 months, what derails new hires here, roadmap.
7. **Reverse-Interview Red Flags** (red panel) — what Jeremy is listening FOR (and against): handwaving on attrition, fuzzy answers on "what does great look like," vague roadmap, "we move fast" without "and here's how we don't break things," no on-call structure. 4–6 items.

### Exec (~30 min, CTO/VP/C-suite — often final round)

1. **Compressed Opening** — 30s. Identity → signature → why now. Three sentences. Bold each load-bearing phrase. **No technical jargon below the C-suite altitude.**
2. **Business-Outcome STAR** (green panel, table) — every story reframed in business language. Backstage pipeline → "decoupled module evolution from consumer adoption, accelerated platform team's effective leverage across N application teams." 30→2 CI → "15x developer feedback-loop reduction translates to N+ developer-hours/week reclaimed." Cloud Run tiering → "material non-prod spend reduction at constant prod SLO." Pick 4–5 stories max, drop the rest.
3. **Strategic Questions to Ask** (blue panel) — 4–6 questions at altitude. Examples: "What's the 3-year tech bet you'd defend in front of the board even if it slipped a quarter?" "What's the biggest non-technical risk to the engineering org right now?" "What's a priority for engineering that wouldn't be obvious from the product roadmap?" "How does the platform/devops function ladder up to the company's primary commercial motion?" Tailor at least one to the company's specific industry (fintech → regulatory direction; AI → model-cost trajectory; etc.) using the company entity.
4. **Why Us + Why This Seat** (purple panel) — strategic-lens version. ~4 sentences. Anchor to (a) the company's commercial bet, (b) what platform engineering looks like inside that bet, (c) why Jeremy specifically fits *this* moment of the company, (d) what Jeremy wants to learn from this exec / org.
5. **Equity + Total Comp** (yellow panel) — grown-up version. Equity structure questions, vesting, strike timing, cliff, refresher cadence, what triggers acceleration. **No salary anchor here** — by exec round, base is settled.
6. **One Sharp Industry Question** (single highlight panel) — one well-informed question demonstrating Jeremy understands what the company is actually trying to build. Industry-specific, drawn from the company entity. The "I did the homework at depth" signal.
7. **Don't Go Into** (red panel, short) — implementation weeds, technical gaps in detail, Aria Labs as anything more than a one-line side-mention. Stay altitude.

## 3. Markdown output

Write to `$WIKI_VAULT/wiki/projects/applications/{slug}-{stage}.md`.

Frontmatter:

```yaml
---
title: {Company} {Role} — {Stage Title} Prep
type: project
tags: [personal]
related: [{slug}, jeremy-spofford-career, {company-slug}, personal-career-transition]
sources: ["wiki/projects/applications/{slug}.md", "wiki/entities/jeremy-spofford-career.md"]
created: {today}
updated: {today}
status: current

application: "[[{slug}]]"
stage: {stage}
call_date:
companion_html: "{slug}-{stage}.html"
---
```

Body structure — **always begins with the HTML link callout**:

```markdown
# {Company} · {Role} · {Stage Title} Prep

> [!tip] [Open polished HTML cheat sheet →]({slug}-{stage}.html)
> Two-column color-coded layout, optimized for desktop / print. Markdown below is the canonical version — renders on mobile, syncs everywhere.

**Call**: {date if known} · **Match**: {summary from application page} · **Anchor**: {signature row}
```

Then render each section as an Obsidian callout with the matching color:

| Section type | Callout |
|---|---|
| Opening Script | `> [!example]` (purple-ish in default themes) |
| Lead With / System Design / Leadership Stories / Business STAR | `> [!success]` (green) |
| Salary / Code-Talk / Equity | `> [!warning]` (yellow) |
| Don't Volunteer / Gap Rebuttals / Watch-outs / Don't Go Into / Red Flags | `> [!danger]` (red) |
| Questions to Ask | `> [!question]` (blue) |
| STAR Triggers / STAR Library / Hard-Problem Rotation | `> [!note]` (grey) — tables inside |
| Company cheat sheet / Career Arc | `> [!info]` (cyan) |
| Why Us / Why Leaving / Industry question highlight | `> [!quote]` (subtle accent) |

Tables (STAR Triggers, STAR Library) render as markdown tables inside the callout — Obsidian renders these cleanly. Mobile-readable.

End the markdown body with the backfill block (section 5).

## 4. HTML companion output

Write to `$WIKI_VAULT/wiki/projects/applications/{slug}-{stage}.html`.

**Structure** — match `sardine-devops-call.html` exactly:

- Inline `<style>` block at top (no external CSS dependency, no JS). Color palette: green/yellow/red/blue/grey/purple per the existing CSS variables. `@media print` block for clean printing.
- Topbar with company logo (best-effort from `https://logo.clearbit.com/{domain}` or the company's Ashby/Lever org image; `onerror=this.style.display='none'` so a missing logo doesn't break layout), title (`{Role} · {Stage Title} Prep`), subtitle (date + context), and a right-side match-strength chip.
- Pacing reminder strip (yellow tint) — adapt the line to the stage. Recruiter: "Pause. Let them drive." Technical: "Think out loud. They're scoring approach, not just answers." HM: "Be the candidate they'd want on the team — calm, scoped, curious." Exec: "Stay altitude. Numbers and outcomes, not implementation."
- Quick-facts strip (4 stats from the company entity — customers, scale, raised, headcount, whatever's loudest).
- Section panels in the order defined by the stage matrix. Three-column primary grid (`.three-col`) for Lead/Salary/Don't (recruiter) or System Design/Code-Talk/Watch-outs (technical) or Stories/Career-Arc/Red-Flags (HM) or Business-STAR/Equity/Don't-Go-Into (exec).
- Questions panel: 2-column grid with colored tag chips per category.
- STAR table panel: same `triggers-table` styling as Sardine — left column trigger keywords, right column story.
- Company cheat sheet: 3-column grid (mission/customers/stack), with simpleicons logos for tech stack (`https://cdn.simpleicons.org/{slug}`).
- Footer line: `Generated {today} · Full crosswalk in {slug}.md · Career source-of-truth: jeremy-spofford-career.md`.

**Density rule**: the entire artifact should be 1–2 screen-heights on a laptop. Don't pad. Cut sentences ruthlessly. Use chips, tags, short bullets.

**Exec sheet is visually quieter**: drop the quick-facts strip, drop simpleicons row. Three panels max in the primary grid. Larger whitespace.

## 5. Backfill block (required, always)

Last section of the markdown (not the HTML — this is operational, not for the call):

```markdown
> [!important] Backfill into [[jeremy-spofford-career]] after the call
> Evidence surfaced during this prep that should be promoted into Notable Accomplishments or Context Notes so future applications inherit it:
> - {accomplishment or framing rule that came up in prep but isn't in the career entity yet}
> - {...}
>
> **Process**: after the call, append these to `wiki/entities/jeremy-spofford-career.md` (Notable Accomplishments for stories, Context Notes for framing rules). Update `updated:` date. Log the backfill in `wiki/log.md` as a `update | career-entity backfill from {slug}-{stage} prep` entry.
```

If nothing surfaced (rare — usually something does), render the block with a single line: `- None this round. Stories and framing already covered in the career entity.`

**How to identify backfill candidates while generating the artifact**:

- Stories referenced in the application page or company-research that don't appear in `jeremy-spofford-career.md` Notable Accomplishments
- Framing rules invoked during prep (e.g., "don't open with FinOps gap") that aren't yet in Context Notes
- Recall-risk patterns (IAM trust policy, K8s production gap) that surface in Watch-outs and aren't yet codified in MEMORY.md `Preferences & Decisions`

The Sardine recruiter prep surfaced **Cloud Run per-env Terraform tiering** and **autoscaling GitLab runner fleet with multi-executor density** as cost-optimization accomplishments — both currently in MEMORY.md but **not** in `jeremy-spofford-career.md` Notable Accomplishments. That's the kind of gap this block exists to close.

## 6. Update application page

Append one line to the application page's `## Follow-ups` checklist:

```markdown
- [ ] **Run `/prep-interview {slug} {next-stage}`** ~24h before the {next-stage} round
```

…where `{next-stage}` is the natural successor (recruiter → technical, technical → hiring-manager, hiring-manager → exec). Skip if already present. **Don't otherwise modify the application page.**

Add a `prep_artifacts:` field to the application page frontmatter if missing; append the new artifact's relative path:

```yaml
prep_artifacts:
  - {slug}-recruiter.md
  - {slug}-technical.md   # appended on next run
```

## 7. Indexes + log

**`wiki/projects/index.md`** — no change. The application page already exists in the Job Applications section; the prep artifacts hang off it via `companion_html` + `prep_artifacts`, not as standalone index entries.

**`wiki/log.md`** — insert after the header, before the most recent entry:

```
## [{today}] capture | {Company} {Role} {stage} prep — {N} sections, {M} STAR stories pre-mapped

Created:
- projects/applications/{slug}-{stage}.md — markdown canonical
- projects/applications/{slug}-{stage}.html — companion polished view

Updated:
- projects/applications/{slug}.md — appended follow-up, added prep_artifacts
```

## 8. Report

Tell the user, concisely:

- **Files written**: 2 paths (markdown + HTML).
- **Stage**: which one + section count.
- **Anchor**: the Signature row from the application page (one line).
- **Backfill queue**: count of items + a one-line preview of the most important one.
- **Open the HTML**: `open {absolute-path-to-html}` (macOS) so Jeremy can verify it renders right before the call.

Keep under 12 lines. The artifacts are the deliverable.

---

## Rules

- **The application page is the source of truth.** Crosswalk, STAR queue, Lead With, gap rebuttals all live there. This command composes — it does not re-derive. If the application page is thin, the prep artifact will be thin. The fix is to deepen the application page (or run `/apply-to-job` again), not to invent content here.
- **The career entity is the second source of truth.** Stories, Context Notes (Aria Labs off-lead, sole-infra framing, salary anchor), and recurring rules come from there. Never invent.
- **MEMORY.md `Preferences & Decisions` is the third.** IAM recall-under-pressure, K8s gap framing, sole-infra ownership-scope correction — these are recurring framing rules that propagate into Watch-outs and Talking Points.
- **Stage discipline.** Don't put exec content in a recruiter sheet. Don't put implementation weeds in an exec sheet. The matrix is opinionated for a reason — recruiters don't need system design, execs don't need code-talk priming.
- **HTML is the companion, markdown is canonical.** Always write both. Always link from markdown → HTML via relative path in a tip callout near the top. Never write only the HTML.
- **Density over prose.** Bullets, chips, tables, short scripts. The artifact gets scanned in the 5 minutes before a call; it does not get read like a memo.
- **Print-friendly CSS.** `@media print` block is required. Jeremy may print the HTML.
- **No emojis** in either output (USER.md preference; the tip callout's link arrow `→` is fine, that's not an emoji).
- **One signature anchor per stage.** Don't dilute. Pull it directly from the application page's `Strong (signature)` crosswalk row.
- **The Backfill block is required.** Never skip it, even if empty (render the empty form). It's how the career entity grows across applications instead of staying static.
- **Overwrite protection.** If `{slug}-{stage}.{md,html}` already exists, warn and ask. Don't silently clobber prior work or Jeremy's edits to the prep sheet.
- **Reference, don't duplicate.** The application page already has STAR stories with full S/T/A/R detail. The prep artifact should cite story numbers + 1-line summaries, not re-paste the full STAR. Exception: technical stage's STAR Library can render compressed S/T/A/R (4 lines each) because that's the primary content.
