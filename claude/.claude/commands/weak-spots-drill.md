Run a focused active-recall drill on concepts I've been blowing on quizzes. This is `/quiz-me` but narrower — pull exclusively from the cert's `Exam Weak Spots.md` file. Use this when you've watched a bunch of lectures and need to hammer the things that aren't sticking.

## Inputs

- `$ARGUMENTS` — optional cert name (`saa-c03`, `cka`, etc.). Defaults to AWS SAA-C03.

## Steps

### 1. Locate the weak spots file

Map cert name → folder:
- `saa-c03` → `Learning/AWS SAA/Exam Weak Spots.md`
- `cka` → `Learning/CKA/Exam Weak Spots.md`
- `aif-c01` → `Learning/AWS AIF/Exam Weak Spots.md`
- `mla-c01` → `Learning/AWS MLA/Exam Weak Spots.md`

If the file doesn't exist or is empty, tell Jeremy and stop. There's nothing to drill.

### 2. Parse the entries

Read every entry under every date heading (excluding the "Resolved" section). Build an internal pool of weak-spot concepts.

If a concept appears under multiple date headings, weight it higher — it's a chronic problem and should come up more often in the drill.

### 3. Run the drill

**Style: Learning. Hard mode.**

- 15 questions by default unless Jeremy says otherwise.
- Every question should target a weak-spot concept. No "warm-up" questions on stuff he already knows.
- Mix question types just like `/quiz-me`: recall, scenario, comparison, "what would happen if".
- Ask one at a time. Wait for an answer. No info-dump.
- If he gets a chronic-weak-spot question right, ask a *harder follow-up* on the same concept to verify it actually stuck.
- If he gets a question wrong, **don't soften it.** This is the explicit drill — he knows what he signed up for. Tell him what was wrong, give the correct answer concisely, and add the concept back into rotation later in the session.

### 4. Wrap up

After the 15th question (or when he says stop):

**Score breakdown** — exact numbers, no theater:
- Right: X
- Partial: Y
- Wrong: Z

**Movement decisions** — for each weak-spot concept that was tested:
- **Got it right twice in this session** → propose moving to the Resolved section. Show the exact line you'd move and ask for confirmation before editing the file.
- **Got it wrong** → keep in place, append today's date as a re-occurrence under today's heading.
- **Got it right once** → leave it alone, will retest next drill.

**Dedicated study suggestion** — if any concept is now appearing 3+ times across date headings, recommend a dedicated lecture rewatch or doc-reading session on that specific topic. Be opinionated about what to read.

## Style

**Learning style. No softening, no praise theater.** This command is the high-pressure variant. Jeremy explicitly invoked it to be hammered on the things he keeps missing — be the assistant that takes that seriously.
