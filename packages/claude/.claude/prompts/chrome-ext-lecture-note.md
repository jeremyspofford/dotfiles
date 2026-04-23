# Chrome Extension — Lecture Note Shortcut

Body for a Claude Chrome extension shortcut. Set up once via the extension's shortcut/prompt settings; trigger while watching a Udemy video with the transcript open.

## How to install in the Chrome extension

1. Open Claude Chrome extension settings → Shortcuts (or "Saved prompts" depending on version)
2. Create a new shortcut named **lecture-note**
3. Paste the prompt body below
4. Save. Trigger from any Udemy lecture page where the transcript is visible.

## Prompt body

---

You are helping me build a study note from a Udemy lecture transcript currently visible on this page. I'm Jeremy Spofford — Senior DevOps engineer, GCP-heavy background, growing AWS depth, studying for AWS SAA-C03. Skip explanations of Terraform, Kubernetes, Linux, JSON, or general cloud concepts. Explain AWS-specific quirks and exam traps.

## Step 1: Read the page

Read the transcript on this page along with any available metadata: course name, section, lecture number, lecture title, instructor, and the video URL. If the transcript is collapsed or paginated, expand/scroll it first so you have the full thing.

## Step 2: Generate a complete study note

Output the note as a single markdown code block I can copy directly into Obsidian. The path it should be saved to is `~/Obsidian_Vault/Learning/AWS SAA/Lecture <NN> - <Title>.md`. Use this exact structure:

```markdown
---
tags: [aws, <topic>, saa-c03]
type: study
course: <course name>
section: <N - section title>
lecture: <NN>
instructor: <instructor>
video_url: <url>
date_watched: <today's date YYYY-MM-DD>
status: complete
confidence: 0
---

# Lecture <NN> - <Title>

> [!info] Lecture Metadata
> **Course:** ...
> **Section:** ...
> **Instructor:** ...
> **Source:** [Video Link](...)

---

## TL;DR

<one paragraph — the single most important takeaway>

---

## Key Concepts

### <Concept 1>
- ...

### <Concept 2>
- ...

---

## Diagrams / Visuals
<ASCII or mermaid where structural; omit section if not applicable>

---

## Code / Configuration Examples
<only if the lecture had any; don't fabricate>

---

## Important Warnings & Gotchas

> [!warning]
> ...

---

## Exam Tips

> [!tip] Likely on the exam
> - ...

---

## Connections
<placeholder for backlinks — I'll fill these in based on what's already in the folder>
- [[ ]]

---

## References
- <official AWS docs links for any service mentioned>
```

## Step 3: Generate spaced repetition cards

After the note, output a **second** markdown code block containing 8–15 spaced repetition cards in Obsidian Spaced Repetition plugin format. Append these to the same note under a `# Spaced Repetition Cards` heading:

```markdown
# Spaced Repetition Cards

#flashcards/aws/saa-c03/<topic>

Question on one line?
?
Answer on the line(s) below.

Next question?
?
Next answer.
```

Card guidelines:
- Mix card types: factual recall, conceptual ("when would you use X over Y"), cloze deletions for ports/limits/CIDRs (`==443==`), and 1–2 scenario-based ("You need to ___, which service?")
- One concept per card. Atomic answers (≤3 bullets).
- Tag topics from: iam, vpc, ec2, s3, rds, dynamodb, lambda, sqs-sns, cloudfront, route53, elb, ebs, efs, kms, cloudwatch, cloudtrail, organizations, cost, well-architected, migration, disaster-recovery.

## Step 4: Brief report

After both code blocks, in 3 lines:
- The filename to save as
- How many cards generated
- Any concept that's a notorious exam trap and should go in `Exam Weak Spots.md`

## Style

Direct, no preamble, no "Great question!" Don't quote the transcript — distill it into my voice. If the instructor says something wrong or outdated, flag it.
