# Obsidian Spaced Repetition — Card Format Cheatsheet

Quick reference for the [obsidian-spaced-repetition](https://github.com/st3v3nmw/obsidian-spaced-repetition) plugin syntax. The plugin is installed in Jeremy's vault.

## Deck tags

Cards belong to a deck via tag. Place the tag at the **top of the section** containing the cards (not as a heading — as an actual tag):

```markdown
#flashcards/aws/saa-c03/iam
```

Hierarchical tags work as nested decks. Conventions for this vault:

| Cert | Tag prefix |
|---|---|
| AWS SAA-C03 | `#flashcards/aws/saa-c03/<topic>` |
| CKA | `#flashcards/k8s/cka/<topic>` |
| AWS AIF-C01 | `#flashcards/aws/aif-c01/<topic>` |
| AWS MLA-C01 | `#flashcards/aws/mla-c01/<topic>` |

Topics for AWS SAA: `iam`, `vpc`, `ec2`, `s3`, `rds`, `dynamodb`, `lambda`, `sqs-sns`, `cloudfront`, `route53`, `elb`, `ebs`, `efs`, `kms`, `cloudwatch`, `cloudtrail`, `organizations`, `cost`, `well-architected`, `migration`, `disaster-recovery`.

## Card formats

### Multi-line (preferred for cert study)

Question on its own line, `?` separator on its own line, answer below. Blank line before and after each card.

```markdown
What does the IAM policy Version "2012-10-17" actually mean?
?
It's the IAM policy language version, not a date you choose. Always use this exact value.
```

### Multi-line reversed

`??` separator creates a card that's also tested in reverse (answer → question).

```markdown
S3 default storage class
??
S3 Standard
```

### Single-line

`::` separator. Compact, good for definitions.

```markdown
Default VPC CIDR block::172.31.0.0/16
```

### Single-line reversed

`:::` separator. Tests both directions.

```markdown
SQS visibility timeout default:::30 seconds
```

### Cloze deletion

Wrap the hidden text in `==highlight==`, `**bold**`, or `{{curly}}` (configurable). Highlight is the default in this vault.

```markdown
A standard SQS queue guarantees ==at-least-once== delivery, while a FIFO queue guarantees ==exactly-once== processing.
```

You can have multiple clozes per sentence — each becomes a separate card.

## Best practices for `/lecture-note`-generated cards

1. **One concept per card.** No "explain everything about X" cards.
2. **Atomic answers.** If the answer needs more than 3 bullets, split it.
3. **Mix card types.** A good lecture batch has factual recall, comparison, scenario, and 1–2 cloze cards.
4. **Avoid yes/no questions.** They're noise — they don't force retrieval.
5. **Avoid leading questions.** "What is the *main* benefit of X?" → instead, "When would you choose X over Y?"
6. **Cloze ports, limits, defaults, CIDRs, and version strings.** They're memorization-heavy and benefit from in-context recall.
7. **Reference the source lecture.** Optional: include `(Lecture 14)` at end of question for traceability.

## Reviewing

- Hotkey: `Ctrl/Cmd+P` → "Spaced Repetition: Open a note for review"
- Or open the SR sidebar pane and click a deck to review just that deck
- Reviews use SM-2 algorithm: Easy / Good / Hard buttons schedule the next review
- 5–15 min/day is the right target — don't binge

## Editing existing cards

Just edit the markdown directly. The plugin tracks card history via `<!-- review history -->` HTML comments it appends. Don't delete those — they preserve your progress on cards you've already studied.
