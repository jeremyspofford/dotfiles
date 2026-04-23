# Claude Style Picker

When to use which Claude.ai conversation style. Set in the chat UI before starting a conversation.

## TL;DR

| If you want to... | Use |
|---|---|
| Be told the answer | **Explanatory** |
| Build the answer yourself | **Learning** |
| Get something done with no pedagogy | **Normal** |
| Brainstorm or vent | **Normal** |
| Cram for an exam | **Learning** + occasional **Explanatory** |

## The styles

### Normal
Default. Direct, answers questions, no Socratic dance, no extra depth unless asked. Best for: work tasks, code, drafting, mid-incident debugging, "just tell me X."

### Explanatory
Optimized for *you already want the answer, just make it land well*. Gives thorough explanations with the reasoning, worked examples, and the "why" behind the "what." Patient expert mode. Best for: first encounter with a hard concept, understanding a system you've never seen before, deep dives where you want context not just facts.

### Learning
Optimized for *you want to build the understanding yourself*. Socratic — leans on leading questions, checks what you know first, breaks things into steps, asks you to articulate concepts back. Best for: studying for certs, internalizing something you need to retain long-term, debugging your own thinking on a topic.

## Cert study mapping

| Stage | Style | Notes |
|---|---|---|
| Watching the Udemy video | n/a | Just watch. Don't open Claude yet. |
| `/lecture-note` running | **Normal** | Pure summarization task. |
| Reading the generated note | n/a | Skim, fix anything wrong. |
| First-pass concept I struggled with | **Explanatory** | "Explain X like I'm a senior DevOps from GCP-land trying to map this to AWS." |
| `/quiz-me` session | **Learning** | The whole point. |
| Reviewing weak spots | **Learning** | Same as quiz. |
| Daily SR review in Obsidian | n/a | No Claude needed — the plugin runs the review. |

## Anti-patterns

- ❌ Using **Learning** when you're under time pressure and just need the answer. It'll Socratically interrogate you and you'll get frustrated.
- ❌ Using **Explanatory** for a quick lookup. You'll get a 3-paragraph essay when you wanted a 1-line answer.
- ❌ Using **Normal** for cert encoding. You'll get told the answer instead of having to retrieve it, and retention will be worse.
- ❌ Switching styles mid-conversation hoping for a different vibe. Just start a new chat — styles are conversation-scoped.

## Switching mid-flow

If you're in a Learning-style quiz and you genuinely need a real answer (not a Socratic prompt), you can say: *"Drop the Socratic thing for a sec — just tell me the answer to ___, then we'll continue."* Claude will accommodate.
