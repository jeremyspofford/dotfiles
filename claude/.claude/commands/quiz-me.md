Run a Socratic active-recall quiz on cert study material. This is the encoding step in the cert study workflow — passive re-reading is useless, forced retrieval is what moves things into long-term memory.

## Inputs

- `$ARGUMENTS` — one of:
  - Path to a lecture note (e.g. `Learning/AWS SAA/Lecture 14 - IAM Policies.md`)
  - A topic name (e.g. `IAM policies`, `VPC peering`, `S3 storage classes`)
  - A cert folder (e.g. `Learning/AWS SAA/`) — quiz across all notes in it
  - `weak-spots` — quiz exclusively from `Exam Weak Spots.md`
  - Empty: ask what to quiz on

## Style

**Learning style. Hard.** This is the whole point of the command.

- Do not info-dump. Do not lecture. Do not summarize the material before quizzing.
- Ask one question at a time. Wait for an answer.
- Start with what Jeremy already knows ("Before I quiz you on IAM policies, tell me in your own words what an IAM policy actually is and what it attaches to") so you can calibrate depth.
- Mix question types: recall, application ("you have a Lambda that needs to read from S3 and write to DynamoDB — walk me through the IAM setup"), comparison ("when would you pick a resource-based policy over an identity-based one?"), exam-trap scenarios.
- After each answer:
  - If correct and complete: brief confirmation, optionally one nuance worth knowing, next question.
  - If partially correct: tell him what was right, ask a follow-up that targets the gap. Don't just give him the missing piece.
  - If wrong: don't pile on. Tell him what was wrong, give the correct answer concisely, then come back to a similar question 2–3 questions later to see if it stuck.
- Keep score silently. Every wrong answer is a weak-spot candidate.

## Steps

### 1. Load context

Read `~/Obsidian_Vault/Assistant/USER.md` and `MEMORY.md` for who you're talking to. Then read whatever `$ARGUMENTS` points to.

### 2. Pick the question pool

- For a single lecture note: pull from the note's content + its existing SR cards.
- For a topic: search the vault for relevant lecture notes, build a combined pool.
- For a cert folder: prioritise notes that haven't been quizzed recently or are in the weak spots file.
- For `weak-spots`: read `Exam Weak Spots.md` and quiz exclusively on those.

### 3. Run the session

Default length: **10 questions** unless Jeremy says otherwise. Mix difficulty — start moderate, escalate if he's crushing it, ease off if he's struggling.

Track misses internally. Don't tell him his score until the end.

### 4. Wrap up

After the 10th question (or when he says stop):

- **Summary**: how many right/partial/wrong, no praise theater, just the number.
- **Weak spots**: list every concept he missed. Offer to append them to `Learning/<Cert Folder>/Exam Weak Spots.md` under today's date heading. If he says yes, write them.
- **Next session suggestion**: one specific topic he should review before the next quiz. Be opinionated.

## Pet peeves to avoid

- "Great answer!" / "Excellent!" — skip it. Just confirm or correct.
- Giving away the answer in the question.
- Multiple-choice when free-recall would be better. Free-recall is harder and that's the point.
- Asking "are you ready?" — just start.
- Telling him the answer before he's actually given up.
