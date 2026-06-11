Generate a focused interview prep document from an existing job application wiki page. Optimized for quick pre-interview review: STAR stories, gap rebuttals, questions, and talking points in a single scannable page rendered by Quartz.

Usage: `/interview-prep [company-role-slug | company name]`

- If no argument: find application pages with an `interview_date` within the next 14 days. If exactly one, use it. If multiple, ask. If none, list pages with `application_status: screen` or `interview`.
- If a prep page already exists at `wiki/projects/interview-prep/{slug}-interview-prep.md`, warn and stop — don't overwrite unless `--force` is passed.

---

## 1. Load context

Read in parallel:
- Application page: `$WIKI_VAULT/wiki/projects/applications/{slug}.md`
- `$WIKI_VAULT/Assistant/USER.md` — framing rules, de-emphasis notes

## 2. Extract from the application page

Pull these sections (always present in `/apply-to-job` output):

| What | Where in source |
|------|-----------------|
| Round info, date, interviewers | `interview_date` frontmatter + `next_action` + Interview Rounds table |
| Lead With | Talking Points → Lead With subsection |
| De-emphasize / Avoid | Talking Points → De-emphasize + Avoid subsections |
| STAR Stories | STAR Stories Queued section (all of them) |
| Gap Rebuttals | Gaps & Rebuttals section (all gaps and partials) |
| Questions | Questions for the Interviewer section (all tiers) |
| Cultural Notes | Talking Points → Cultural Notes subsection |
| Company intel for "Why Here" | Company Intel section — stage, stack signals, what drew you to this specifically |

## 3. Generate the prep document

Save to: `$WIKI_VAULT/wiki/projects/interview-prep/{company-slug}-interview-prep.md`

Create the `wiki/projects/interview-prep/` directory if it does not exist (`mkdir -p`).

### Frontmatter

```yaml
---
title: {Company} Interview Prep
type: interview-prep
tags: [personal]
related: [{page-slug}, jeremy-spofford-career]
sources: ["wiki/projects/applications/{page-slug}.md"]
created: {today}
updated: {today}
status: current

company: {Company}
role: {Role}
interview_date: {from source frontmatter, or blank}
---
```

### Body structure

```markdown
# {Company} — Interview Prep

**Round:** {round name from Interview Rounds table, or "Screen" if only one entry}
**Date:** {interview_date + time + timezone, from frontmatter or next_action}
**With:** {interviewers from Interview Rounds table or next_action}

---

## Tell Me About Yourself

> Memorize the **opening** and **closing** sentences. Improvise the middle.
> Target: ~90 seconds spoken. Don't rush it.

{Generate a 3-paragraph spoken script using this structure:}

**Past** — Who you are + the single strongest proof point with its metric. Draw from the signature STAR story result and the top Lead With talking point. 2–3 sentences.

**Present** — What you're focused on now and why it's intentional (not reactive). Draw from the current cert/learning arc and active role framing. 2 sentences.

**Why Here** — One specific reason this company and this role, using language from the Company Intel section. Reference something concrete from their stack or stated direction. End with a forward hook that hands the conversation back to them. 1–2 sentences.

_Example shape (fill with real content from the source page):_

> "I'm a DevOps engineer with {X} years in cloud infrastructure, most recently owning the full GCP environment at a consulting firm — including the CI/CD pipelines, IaC architecture, and secrets infrastructure. One of my proudest results there was cutting a 30-minute GitLab CI pipeline down to 2 minutes through change-detection and parallelization — that kind of leverage is what I'm after in this kind of role.
>
> Right now I'm deepening my AWS specialization — SAA-C03 in flight, CKA on deck — because the work I want to do next is on AWS-native infrastructure at production scale.
>
> What pulled me toward {Company} specifically is that you're actively adding GitLab CI — which is where I have the most depth — and pairing it with Terraform and ArgoCD, which is exactly the stack I've built around. I'd love to dig into how that transition is going."

---

## Lead With

- {talking point 1 — most distinctive, include metric if present}
- {talking point 2}
- {talking point 3}
{add up to 2 more if in source}

---

## STAR Stories

> Lead with **Story #1** — introduce it within the first 10 minutes.

### 1. {Story title} — LEAD WITH THIS
**S:** {situation, 1 sentence}
**T:** {task, 1 sentence}
**A:** {action, 1–2 sentences}
**R:** {result — always include the metric. If missing: `[metric missing — add before interview]`}
**Maps to:** {requirement ref from source}

### 2. {Story title}
{same format, no LEAD WITH marker unless the source flags a second signature story}

{...all STAR stories from source, in the same order as source}

---

## Gap Rebuttals

> Read these once before the call. If a gap comes up, say your version of this — don't recite verbatim.

### {Gap name}
> {Pre-formulated rebuttal — blockquote format. 2–4 sentences. Copy from source, tighten if wordy.}

{...all gaps first, then partials. Omit Strong matches — those don't need rebuttals.}

---

## Questions to Ask

### Hiring Manager / Team Lead
1. {question}

### Engineering Leadership
1. {question}

### Peer Engineers
1. {question}

### Recruiter / HR
1. {question}

{Include only tiers that have questions in the source. Don't invent questions.}

---

## Avoid

- {thing to avoid — copied from source Avoid list}

---

## Cultural Notes

- {note from source Cultural Notes}
```

## 4. Report

Tell the user:
- Prep page path
- Round, date, interviewers (one line)
- Counts: N STAR stories, N gap rebuttals, N questions
- One line: "Source page is [[{page-slug}]] — edit there, then regenerate prep."

Keep report under 8 lines.

---

## Rules

- **Never invent content.** Pull only from the source application page.
- **Rebuttals always in blockquotes.** Makes them scannable and easy to reference aloud.
- **STAR results always include the metric.** Flag missing ones with `[metric missing — add before interview]`.
- **Preserve source story order.** The signature story is already first in the source — keep it first.
- **One prep doc per application.** Filename: `{company-slug}-interview-prep.md`. For a later round, regenerate with updated round info rather than creating `-prep-2.md`.
- **Prep docs live in `wiki/projects/interview-prep/`**, not `wiki/projects/applications/`. Same split as cover letters: keeps the application-pipeline Dataview clean and gives prep docs their own index. `type: interview-prep` is a deliverable type (like `cover-letter`) — don't add it to the Tag Registry, and don't use `type: project`, which would leak into application Dataview queries.
- **Don't edit the prep doc directly.** It's generated from the source page. If information changes, update the source and regenerate with `--force`.
