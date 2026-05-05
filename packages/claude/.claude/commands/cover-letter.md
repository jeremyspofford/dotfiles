Generate a tailored cover letter for a job application, grounded in the application page's crosswalk and the career entity. Output markdown to the vault and `.docx` + `.pdf` deliverables to the Downloads folder, named `jeremy-spofford-{company}-{role}.{ext}`.

Usage: `/cover-letter [application-slug-or-path]`

- `prompt-health-senior-devops` — slug
- `wiki/projects/applications/prompt-health-senior-devops.md` — full path
- `[[prompt-health-senior-devops]]` — wikilink
- No arg: list all files in `$WIKI_VAULT/wiki/projects/applications/` (excluding `index.md` and `*-cover-letter.md`). If exactly one with `application_status` not in (`rejected|declined|withdrawn|accepted`), use it. If multiple, ask which.

If a cover letter already exists at `wiki/projects/applications/{slug}-cover-letter.md`, **warn and ask** before overwriting — cover letters often get hand-edited after generation.

## 1. Preflight — locate pandoc

Pandoc may be installed via apt (`/usr/bin/pandoc`), homebrew, or mise (Jeremy's setup). Resolve the binary in this order:

```bash
PANDOC=""
if command -v pandoc >/dev/null 2>&1; then
  PANDOC="pandoc"
elif command -v mise >/dev/null 2>&1 && mise which pandoc >/dev/null 2>&1; then
  PANDOC="mise exec -- pandoc"
fi
```

If `$PANDOC` is empty: warn the user, generate the markdown source only, skip `.docx` / `.pdf`, and report install commands at the end:

- mise: `mise use -g pandoc@latest`
- Linux/WSL apt: `sudo apt install pandoc`
- macOS: `brew install pandoc`

For PDF specifically, pandoc needs a backend. Detect in this order, and prefer the binary on PATH directly; fall back to `mise exec --` for each:

1. `xelatex` (best output, large install)
2. `pdflatex`
3. `weasyprint` (Python, lightweight)
4. `wkhtmltopdf` (deprecated but common)
5. `libreoffice --headless --convert-to pdf` (uses the .docx as intermediate)

If none of these exist, skip PDF generation gracefully and report. **`.docx` is the primary deliverable** — most recruiters and ATS systems take it directly. PDF is backup, not blocking.

## 2. Resolve Downloads path

```bash
if grep -qi microsoft /proc/version 2>/dev/null; then
  # WSL2 — write to the Windows-side Downloads (accessible from File Explorer / Outlook)
  WIN_USER=$(ls /mnt/c/Users 2>/dev/null | grep -Ev "^(Public|Default|All Users|desktop\.ini)$" | head -1)
  DOWNLOADS="/mnt/c/Users/${WIN_USER}/Downloads"
elif [ "$(uname)" = "Darwin" ] || [ "$(uname)" = "Linux" ]; then
  DOWNLOADS="$HOME/Downloads"
fi
```

Verify the directory exists. If not, fall back to `$HOME/Downloads` and warn.

## 3. Load context

Read in parallel:

- The application page — frontmatter (`company`, `role`, `application_status`, `salary_range`, `interview_date`), crosswalk, gaps & rebuttals, STAR stories, talking points, Interview Rounds table (for recruiter contact), Follow-ups
- `$WIKI_VAULT/wiki/entities/jeremy-spofford-career.md` — Notable Accomplishments (canonical STAR pool), Context Notes (de-emphasis rules — e.g., "Aria Labs off-lead"), tone calibration
- `$WIKI_VAULT/wiki/entities/{company-slug}.md` if it exists — company intel, recruiter contacts under any `## Contacts` section, tech stack, cultural notes
- The JD source clipping (from the application page's `sources:`) — for company-specific language to mirror
- `$WIKI_VAULT/Assistant/USER.md` — personality + voice
- `$WIKI_VAULT/Assistant/MEMORY.md` — current career state + active applications context

## 4. Extract metadata

From the application page frontmatter:

- `{company}` — `company:` field, normalized to slug for filename (lowercase, hyphenated, no spaces)
- `{role}` — derive from the application page filename stem after stripping the company prefix. e.g., `prompt-health-senior-devops` with company slug `prompt-health` yields role slug `senior-devops`. Match the abbreviated convention from existing pages — don't re-expand "Senior DevOps" into "senior-devops-engineer".
- **Filename stem**: `jeremy-spofford-{company}-{role}` — e.g., `jeremy-spofford-prompt-health-senior-devops`
- **Recruiter**: from the Interview Rounds table's "With" column on the most recent screen round, OR from the company entity's `## Contacts` section. Use first name only in salutation when known; "Hiring Manager" otherwise.

## 5. Compose the cover letter

**Hard rules:**

- **250-400 words.** Recruiters skim. A long cover letter signals you don't know what matters.
- **No "I'm excited to apply..."** Open with substance — a story, an alignment, a question they're solving.
- **One signature story, told concretely with numbers.** Pull from the application page's `### N. {Title} (SIGNATURE — use early)` STAR row if marked, else the strongest fit. Compress S/T/A/R into 3-4 sentences of prose, not the structured form.
- **Mirror JD language sparingly.** One or two named tools/concepts from the JD weave in naturally. More than that = obvious pattern-matching.
- **Address gaps only when load-bearing.** If the JD treats a gap as a hard filter (e.g., "must have Kubernetes production experience"), name it and frame the ramp in one sentence — pull from the application page's existing rebuttal. Otherwise don't pre-empt.
- **Career-transition narrative is the lever for senior roles.** If the application page tags `personal-career-transition` as related, surface the why-now-AWS/CKA/SAA arc — that story doesn't fit a resume bullet and is the actual differentiator.
- **Honor Context Notes from the career entity.** If "Aria Labs off-lead" is listed, do not lead with Aria Labs. Mention only if directly relevant.
- **No emojis. No buzzwords** ("synergize", "leverage", "passionate", "rockstar", "guru"). Direct, declarative voice.
- **No salary discussion. No mention of competing applications.**
- **End with a question or a concrete next step**, not "thank you for your consideration."

**Structure (loose, not rigid):**

1. **Opening (1 short paragraph, ~50 words):** Hook on alignment with the company's specific problem or stated direction. Reference something concrete from the JD or company entity, not "I love your mission."
2. **Signature paragraph (~100-150 words):** The signature STAR, prose-form, with the result quantified.
3. **Why this role specifically (~80-120 words):** Pull 2-3 specific JD requirements where you're Strong, weave them with one transferable skill story. If career transition is load-bearing, this is where it goes.
4. **Honest gap acknowledgment (only if needed, ~50 words):** One gap, framed as ramp not deficit. Skip entirely for low-stakes applications.
5. **Closing (1-2 sentences):** Concrete — "Happy to walk through {topic}" or "Available {timeframe} to dig into {specific thing}."

**Salutation:** `Dear {First Name},` if recruiter known; `Dear Hiring Manager,` otherwise.

**Sign-off:** `Best,\n\nJeremy Spofford\njeremyspofford@gmail.com\n[phone if listed in career entity]`

## 6. Write outputs

**Markdown source** → `$WIKI_VAULT/wiki/projects/applications/{page-slug}-cover-letter.md`:

```yaml
---
title: Cover Letter — {Company} / {Role}
type: cover-letter
related: [{page-slug}, jeremy-spofford-career, {company-slug}]
sources: [wiki/projects/applications/{page-slug}.md]
created: YYYY-MM-DD
updated: YYYY-MM-DD
status: current

company: {Company}
role: {Role}
recruiter: {First Last or empty}
generated_for_status: {application_status from page}
---

# Cover Letter — {Company} / {Role}

{cover letter body}
```

**DOCX deliverable** → `${DOWNLOADS}/jeremy-spofford-{company}-{role}.docx`:

```bash
# Optional reference template — set $COVER_LETTER_REFERENCE_DOC to a clean .docx with
# your preferred fonts/margins. Without one, output uses pandoc defaults (Calibri-ish, plain).
REF_ARG=""
[ -n "$COVER_LETTER_REFERENCE_DOC" ] && [ -f "$COVER_LETTER_REFERENCE_DOC" ] && \
  REF_ARG="--reference-doc=$COVER_LETTER_REFERENCE_DOC"

$PANDOC "$MD_PATH" $REF_ARG -o "${DOWNLOADS}/jeremy-spofford-{company}-{role}.docx"
```

Strip the YAML frontmatter from the markdown before piping to pandoc — frontmatter renders as a literal block in the docx otherwise. Either pass `--from markdown-yaml_metadata_block` or pre-process: `sed '/^---$/,/^---$/d'`.

**PDF deliverable** → `${DOWNLOADS}/jeremy-spofford-{company}-{role}.pdf`:

Try in this order based on what's installed:

1. `$PANDOC $MD -o $PDF --pdf-engine=xelatex` (best output, needs TeX)
2. `$PANDOC $MD -o $PDF --pdf-engine=pdflatex`
3. `$PANDOC $MD -o $PDF --pdf-engine=weasyprint` (Python-based, lightweight)
4. `libreoffice --headless --convert-to pdf --outdir $DOWNLOADS $DOCX` (uses the .docx as intermediate — works if `libreoffice` exists)

If none work, skip PDF and report the missing toolchain.

## 7. Update the application page

Edit the application page in two places:

**Frontmatter** — append the cover-letter slug to `related:` if not present:

```yaml
related: [..., {page-slug}-cover-letter]
```

**Follow-ups section** — append a checked item:

```markdown
- [x] Cover letter generated 2026-MM-DD → `[[{page-slug}-cover-letter]]` · DOCX/PDF in Downloads
```

Bump the page's `updated:` field.

## 8. Report to user

Print a concise summary:

```
Cover letter generated for {Company} — {Role}

Source:    wiki/projects/applications/{page-slug}-cover-letter.md
DOCX:      {DOWNLOADS}/jeremy-spofford-{company}-{role}.docx
PDF:       {DOWNLOADS}/jeremy-spofford-{company}-{role}.pdf  (or "skipped — no PDF backend")
Word count: N
Recruiter:  {name or "unknown — addressed 'Hiring Manager'"}
```

Then surface 1-2 specific things worth Jeremy reviewing before sending — e.g., "I leaned on the 30min→2min CI/CD signature story; if you want to swap to {alt}, edit the markdown and re-run." Don't re-narrate the whole letter.

## Safety rules

- **Never overwrite an existing cover-letter markdown without asking** — they often get hand-edited
- **Never put PII beyond what's already in `jeremy-spofford-career.md`** (no addresses, no SSN-equivalent, no DOB)
- **Never reference rejection outcomes** from other applications, even if surfaced in MEMORY.md context
- **Never fabricate accomplishments** — every concrete claim traces back to the career entity's Notable Accomplishments. If the application page has a STAR story not in the career entity, that's a wiki-lint smell — flag it but use it.
- **Don't mirror JD language so closely it reads as scraped.** One or two anchor phrases is fine; full sentences lifted verbatim is a tell.
- **No emojis. No em-dashes if the rest of Jeremy's writing avoids them — match the career entity's voice.**

## Tag registry

`cover-letter` is a new `type:` value. Don't worry about adding it to the Tag Registry — cover letters are deliverables, not wiki knowledge, and don't get ingested into concept/project/entity pages. They live in `wiki/projects/applications/` purely for vault-local discoverability.
