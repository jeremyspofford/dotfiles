---
name: cheatsheet
description: Display a tldr-style quick reference of all available slash commands with descriptions and usage examples. Use when user says "/cheatsheet", "list commands", "what commands are available", "show me all skills", or "help with slash commands".
---

# Cheatsheet — Slash Command Quick Reference

Generate a concise, tldr-style reference card for all available slash commands. The output should be scannable, grouped logically, and include brief examples.

## Process

### 1. Discover invocable items

The cheatsheet exists to surface things you *type* — auto-triggered skills (the ones Claude invokes when their description matches conversation context) don't belong here. Scan two source families with different inclusion rules:

**Always-include (user-invocable by definition — they live in `commands/` directories):**

- `~/.claude/commands/*.md` — personal slash commands. **Description = first non-empty line** of the file. These do not use YAML frontmatter; the convention is a one-line description on line 1, then body.
- `~/.claude/plugins/cache/*/*/*/commands/*.md` — plugin slash commands. Path layout: `cache/<source>/<plugin>/<version>/commands/<name>.md`. **Description = `description:` field in YAML frontmatter.**

**Conditionally-include (skills require the user-invocable filter below):**

- `~/.claude/skills/*/SKILL.md` — personal skills. Description from YAML frontmatter.
- `~/.claude/plugins/cache/*/*/*/skills/*/SKILL.md` — plugin skills. Path layout: `cache/<source>/<plugin>/<version>/skills/<name>/SKILL.md`. Description from YAML frontmatter.

For each SKILL.md found, extract `name` and `description`, then apply the **user-invocable filter**:

**INCLUDE the skill if EITHER:**
- Its description mentions a slash invocation pattern — `/<name>`, `/[arg]`, or similar (e.g., `/note [content]`, `/quiz-me`, `/dev-script`). Strongest signal — the author explicitly describes how the user invokes it.
- Its description starts with an **action verb** describing what the skill *produces or does* — "Generate", "Run", "Create", "Display", "Build", "Engage", "Trains", "Import", "Track", "Add", "Publish", etc. These read as commands the user types.

**EXCLUDE the skill if its description starts with:**
- "Use when..." — signals an auto-trigger pattern Claude matches against context, not a command you type.
- "You MUST use this..." or similar imperatives directed at Claude.
- "This skill should be used when..." — same auto-trigger family.
- "Use this skill when..." — same auto-trigger family.

When in doubt, **exclude**. False negatives (a skill missing from the cheatsheet) are recoverable by `/cheatsheet --include-skill <name>` or by editing the skill's description. False positives clutter the output with skills the user never invokes — much harder to notice and harder to clean up.

Also check `~/.claude/CLAUDE.md` for any global slash commands defined there (look for `/command` patterns in skill tables or sections).

### 1b. Deduplicate

If the same name appears across multiple sources, prefer in this order: **personal command > personal skill > plugin command > plugin skill**. This way, a personal override of a plugin command wins, matching how the runtime resolves invocations.

### 2. Categorize

Group skills into these categories based on what they do:

| Category | Skills that... |
|----------|---------------|
| Planning & Strategy | Plan, review plans, brainstorm, scope decisions |
| Development | Write code, TDD, design interfaces, create scripts |
| Testing & QA | Test applications, find bugs, debug |
| Code Review | Review diffs, PRs, code quality |
| Design & UX | Design systems, visual QA, frontend |
| DevOps & Shipping | Ship, deploy, PRs, releases, docs |
| Safety & Scope | Restrict edits, warn on destructive ops |
| Utilities | Everything else — browser, config, help |

Use your judgment to place skills. A skill can only appear in one category.

### 3. Format output

Print the cheatsheet using this exact format. Use a tldr/tldc style — command name, one-line description, then 1-2 example invocations:

```
SLASH COMMAND CHEATSHEET
========================

PLANNING & STRATEGY
-------------------

  /office-hours
  Brainstorm and stress-test product ideas before building.
  $ /office-hours
  $ /office-hours "Should I build a CLI tool for X?"

  /grill-me
  Exhaustive interrogation of a plan or design decision.
  $ /grill-me

  ...

DEVELOPMENT
-----------

  /tdd
  Test-driven development workflow — red, green, refactor.
  $ /tdd
  $ /tdd "add user registration endpoint"

  ...
```

Rules for the output:

- **Command name** on its own line, indented 2 spaces
- **Description** on the next line, indented 2 spaces — one sentence, lowercase start unless proper noun
- **Examples** prefixed with `$ ` — show 1-2 realistic invocations
- Keep descriptions under 70 characters when possible
- Within each category, sort alphabetically by command name
- Skip any skill named `cheatsheet` (don't list yourself)
- If a skill's description is too long or jargon-heavy, rewrite it to be human-friendly
- End with a footer: `Run /[command] to use any skill. Run /cheatsheet to see this again.`

### 4. Handle arguments

If the user passes an argument like `/cheatsheet dev` or `/cheatsheet qa`:
- Filter to only show skills matching that keyword (match against name, description, or category)
- Use the same format but skip the category headers if only one category matches

If the user passes `--verbose` or `-v`:
- Include a second line under the description noting where the skill lives (e.g., `source: gstack`, `source: personal`, `source: plugin/sentry`)
