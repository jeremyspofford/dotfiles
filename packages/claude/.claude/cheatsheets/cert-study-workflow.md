# Cert Study Workflow

The repeatable loop for going from Udemy video to exam-ready knowledge. Read this in conjunction with `flashcard-format.md` and `style-picker.md`.

## The Loop

```
┌──────────────────────────────────────────────────────────────┐
│  1. Watch lecture (1.25-1.5x)                                 │
│       │                                                       │
│       ▼                                                       │
│  2. Capture transcript                                        │
│       │  (Chrome ext shortcut OR copy-paste into Claude Code) │
│       ▼                                                       │
│  3. /lecture-note  ─────────►  Generates note + SR cards      │
│       │                         in vault, updates _Index,    │
│       │                         flags weak spots             │
│       ▼                                                       │
│  4. Skim generated note, fix anything wrong                   │
│       │                                                       │
│       ▼                                                       │
│  5. /quiz-me <note path>  ──►  Socratic active recall         │
│       │                                                       │
│       ▼                                                       │
│  6. Append misses → Exam Weak Spots                           │
│       │                                                       │
│       ▼                                                       │
│  7. Daily SR review in Obsidian (5-15 min)                    │
└──────────────────────────────────────────────────────────────┘
```

## Style Selection

| Phase | Claude Style | Why |
|---|---|---|
| `/lecture-note` | **Normal** | Pure summarization, no Socratic dance needed |
| First-pass concept explanation | **Explanatory** | You want depth, not questions |
| `/quiz-me` | **Learning** | Forced retrieval = encoding |
| Mid-incident lookup at work | **Normal** or **Explanatory** | Speed > pedagogy |

See `style-picker.md` for more.

## Model Selection

| Task | Model | Notes |
|---|---|---|
| `/lecture-note`, daily flashcard generation, `/quiz-me` | **Sonnet 4.6** | 90% case |
| Hard concept synthesis ("compare VPC peering vs TGW vs PrivateLink") | **Opus 4.6** | Save for the hard stuff |
| Quick "wait, what's the default ___" lookups | **Haiku 4.5** | Fastest |

## Per-Cert Setup (one-time)

1. Create a Claude.ai Project named `<Cert> Study`
2. Paste contents of `~/workspace/dotfiles/claude/saa-c03-project-instructions.md` (or equivalent for the cert) into project instructions
3. Upload official exam guide PDF to project knowledge
4. Vault folder `Learning/<Cert Name>/` should contain:
   - `_Index.md` — MOC linking all lecture notes (auto-created/updated by `/lecture-note`)
   - `Exam Weak Spots.md` — running list of concepts you blow on quizzes
   - `Practice Test Log.md` — track scores over time (manual)

## Daily Habit

| When | Time | What |
|---|---|---|
| Morning | 5 min | Obsidian SR review |
| Lunch (optional) | 15-30 min | Watch 1-2 lectures, run `/lecture-note` |
| Evening | 15-30 min | `/quiz-me` on the day's notes |
| End of week | 10 min | Skim Exam Weak Spots, regenerate cards for anything still fuzzy |

## Anti-Patterns

- ❌ Re-watching videos passively (zero retention gain)
- ❌ Highlighting/copy-pasting transcripts as "notes" — `/lecture-note` does this; your job is recall
- ❌ Skipping the quiz step because the topic "felt easy" while watching
- ❌ Running multiple certs in parallel — finish one, then start the next
- ❌ Generating SR cards but never reviewing them (just makes Obsidian heavier)
- ❌ Letting Exam Weak Spots become a graveyard — if a concept stays there for 2 weeks, dedicate a whole quiz session to it

## Where things live

| Thing | Path |
|---|---|
| Vault | `~/Obsidian_Vault/` |
| Lecture template | `~/Obsidian_Vault/Templates/Udemy Lecture - Template.md` |
| Per-cert lecture notes | `~/Obsidian_Vault/Learning/<Cert>/Lecture NN - Title.md` |
| Per-cert MOC | `~/Obsidian_Vault/Learning/<Cert>/_Index.md` |
| Per-cert weak spots | `~/Obsidian_Vault/Learning/<Cert>/Exam Weak Spots.md` |
| Slash commands | `~/.claude/commands/` |
| Cheatsheets | `~/.claude/cheatsheets/` |
| Project instructions | `~/workspace/dotfiles/claude/saa-c03-project-instructions.md` (and future per-cert siblings) |
