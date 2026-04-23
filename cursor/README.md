# cursor — rules for Cursor IDE

Reusable Cursor rules I drop into projects to get specific AI behaviors. Not stowed (Cursor rules live in per-project `.cursor/` directories, not in `$HOME`).

## Layout

```bash
cursor/
├── README.md              ← this file
└── rules/
    └── tutor-mode.mdc     ← pair-programming tutor (manual activation)
```

## Installation

Cursor reads rules from `.cursor/rules/*.mdc` in each project. To use a rule in a specific project:

```bash
mkdir -p <project>/.cursor/rules
cp ~/workspace/dotfiles/cursor/rules/tutor-mode.mdc <project>/.cursor/rules/
```

Or symlink so updates to dotfiles propagate:

```bash
mkdir -p <project>/.cursor/rules
ln -s ~/workspace/dotfiles/cursor/rules/tutor-mode.mdc <project>/.cursor/rules/tutor-mode.mdc
```

Commit the rule file in the target project so collaborators get the same behavior — or `.gitignore` `.cursor/` if it's only for me.

## Rules

### `tutor-mode.mdc`

**What it does:** Turns Cursor's agent into a pair-programming tutor instead of a code-completion service. Forces Cursor to:

- Calibrate what I already know before explaining
- Introduce one concept at a time
- Hand the keyboard back to me for the actual editing
- Wait for me to answer checkpoint questions instead of barreling forward
- Recap what was learned at the end

**When to use it:**

- ✅ Learning a new technology (Docker, K8s, Terraform, a new framework)
- ✅ Studying for a cert and want to write code rather than just read docs
- ✅ Refactoring code where you want to understand the principles, not just ship the diff
- ❌ Mid-incident production debugging
- ❌ Boilerplate/scaffolding work that has no learning opportunity
- ❌ Anything with a hard deadline

**How to activate:**

The rule has `alwaysApply: false`, which means it's manually invoked. In Cursor chat:

```text
@tutor-mode help me rewrite this Dockerfile
```

The `@tutor-mode` reference pulls the rule into context for that conversation.

Alternative: set `alwaysApply: true` in the rule's frontmatter to make tutor mode the default for that project. Useful for dedicated learning repos.

**Escape hatches** (drop tutor mode mid-conversation):

| Phrase | Effect |
| --- | --- |
| `just do it` / `just fix it` | Skip teaching for THIS request, do the work |
| `fast mode` | Stay in normal mode for the rest of the conversation |
| `I'm in a hurry` | Same as fast mode + skip the recap |
| `give me the answer` | Stop the Socratic stuff for this one question |
| `back to tutor mode` | Re-engage tutor mode after fast mode |

**Pairs with the Claude Code variant:**

The same behavior is also available as a Claude Code slash command at `~/.claude/commands/tutor-mode.md`. Use `/tutor-mode` in any Claude Code session for the same experience without needing Cursor.

## Adding new rules

Drop a `.mdc` file in `rules/` with this frontmatter:

```yaml
---
description: One sentence describing when this rule applies, written so Cursor's agent can decide whether to invoke it.
alwaysApply: false   # or true if it should always be on
globs:               # optional — auto-attach to matching files
  - "**/*.tf"
---
```

Then markdown content below.

Three rule activation modes Cursor supports:

- **Manual** — `alwaysApply: false`, no globs. Invoke with `@rule-name`. (What `tutor-mode` uses.)
- **Auto-attached** — `alwaysApply: false` with `globs:`. Activates when files matching the glob are in context.
- **Always-on** — `alwaysApply: true`. Always in context for the project.

Prefer manual or auto-attached for behavioral rules like tutor mode. Reserve always-on for project-wide conventions (code style, naming, file layout).
