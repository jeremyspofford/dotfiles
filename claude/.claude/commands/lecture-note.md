Read a Udemy lecture transcript and generate a complete study note in the Obsidian vault, plus spaced repetition flash cards. This is the cornerstone of the cert study workflow — see `~/.claude/cheatsheets/cert-study-workflow.md` for the full loop.

## Inputs

- `$ARGUMENTS` — one of:
  - A path to a transcript file (`.txt`, `.md`, `.vtt`, `.srt`)
  - A YouTube/Udemy URL (only if a fetch tool is available)
  - Pasted transcript text following the command
  - If empty: ask which lecture and where the transcript is

Optional flags the user may include in `$ARGUMENTS`:
- `--course=<course slug>` — defaults to current cert in progress
- `--section=<N - Title>`
- `--lecture=<N>` — lecture number
- `--title=<Lecture Title>`

## Steps

### 1. Locate the cert context

Default cert is **AWS SAA-C03** unless `$ARGUMENTS` says otherwise. Map the cert to its vault folder:

| Cert | Folder | Flashcard tag prefix |
|---|---|---|
| AWS SAA-C03 | `Learning/AWS SAA/` | `#flashcards/aws/saa-c03` |
| CKA | `Learning/CKA/` | `#flashcards/k8s/cka` |
| AWS AIF-C01 | `Learning/AWS AIF/` | `#flashcards/aws/aif-c01` |
| AWS MLA-C01 | `Learning/AWS MLA/` | `#flashcards/aws/mla-c01` |

If the folder doesn't exist, create it along with `_Index.md` and `Exam Weak Spots.md`.

### 2. Read the template

Read `~/Obsidian_Vault/Templates/Udemy Lecture - Template.md`. Use it as the structural skeleton — every section must be present in the output, even if some are short.

### 3. Process the transcript

Read the transcript. Don't quote it. Distill it into Jeremy's voice — direct, technical, no filler. He's a Senior DevOps engineer with GCP-heavy background and growing AWS depth, so:

- **Skip** explanations of Terraform syntax, Kubernetes basics, Linux fundamentals, what JSON is, what an API is.
- **Explain** AWS-specific service quirks, IAM nuance, exam traps, and anything where AWS does it differently than GCP.
- **Flag** anything where the instructor is wrong, outdated, or oversimplifying. AWS changes constantly — verify with web search if a service limit, pricing, or feature claim seems suspect.

### 4. Fill in the note

Write to `Learning/<Cert Folder>/Lecture <NN> - <Title>.md`. Use `Lecture 14 - IAM Policies.md` as the reference for tone and density. Required sections:

- **Frontmatter** — tags, type: study, course, section, lecture, instructor, video_url, date_watched (today), status: complete, confidence: 0
- **TL;DR** — one paragraph. The single most important takeaway.
- **Key Concepts** — H3 per concept, bullets underneath. Include diagrams (ASCII or mermaid) where the concept is structural.
- **Code / Configuration Examples** — only if the lecture had any. Don't fabricate.
- **Important Warnings & Gotchas** — `> [!warning]` callouts for things that bite people in the exam or in production.
- **Exam Tips** — `> [!tip]` callout. Be specific: "Know the difference between X and Y", "Memorize this default value", etc.
- **Connections** — `[[backlinks]]` to related lecture notes already in the same folder. Check what exists with `list_directory` before linking.
- **References** — links to AWS docs for any service mentioned.

### 5. Generate spaced repetition cards

Append a `# Spaced Repetition Cards` section with **8–15 cards** in Obsidian Spaced Repetition plugin format:

```
#flashcards/<cert tag prefix>/<topic>

Question on one line?
?
Answer on the line(s) below.

Next question?
?
Next answer.
```

Card guidelines:
- **Mix card types**: factual recall, conceptual ("when would you use X over Y"), cloze deletions for ports/limits/CIDRs (`==443==`), and one or two scenario-based ("You need to ___, which service?").
- **One concept per card.** No "explain everything about IAM" cards.
- **Atomic answers.** If the answer needs more than 3 bullets, split into multiple cards.
- **Topic tag** picked from: `iam`, `vpc`, `ec2`, `s3`, `rds`, `dynamodb`, `lambda`, `sqs-sns`, `cloudfront`, `route53`, `elb`, `ebs`, `efs`, `kms`, `cloudwatch`, `cloudtrail`, `organizations`, `cost`, `well-architected`, `migration`, `disaster-recovery`. Add new topics as needed but keep them short and lowercase.

Reference: `~/.claude/cheatsheets/flashcard-format.md` for the full plugin syntax.

### 6. Update the cert MOC

Read `Learning/<Cert Folder>/_Index.md`. Add a row to the lecture table for the new note (lecture number, title, link, status). Keep the table sorted by lecture number. If `_Index.md` doesn't exist, create it from the structure used in other cert folders.

### 7. Flag weak-spot candidates

If any concept in this lecture is the kind of thing that's notorious for tripping people up on the exam (deny-overrides-allow, S3 bucket policy vs IAM policy, VPC peering non-transitive, etc.), append a single line to `Learning/<Cert Folder>/Exam Weak Spots.md` under today's date heading. Don't dump everything — only the genuine traps.

### 8. Report

Tell Jeremy in 3–5 lines:
- The note path created
- How many SR cards were generated
- Any concepts flagged to weak spots
- Anything you couldn't determine and need him to fill in (e.g., video URL if not in transcript metadata)
- One sentence: what to quiz on first when he's ready

Don't summarize the lecture content itself — he just watched it.

## Style

This task is **Normal style**, not Learning style. Pure summarization and structuring. The Learning style happens later in `/quiz-me`.
