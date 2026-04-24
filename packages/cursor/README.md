# cursor — Cursor IDE configuration

Cursor IDE rules, MCP server config, and behavior setup. All files are version-controlled here; Cursor consumes them via symlinks into `~/.cursor/`.

## Layout

```bash
cursor/
├── README.md                     ← this file
└── .cursor/
    ├── mcp.json                  ← user-scope MCP servers (memory-capture, Snyk)
    └── rules/
        ├── global-behavior.mdc   ← tone, preferences, work contexts (alwaysApply: true)
        ├── memory-capture.mdc    ← durable-note capture to $WIKI_VAULT (alwaysApply: true)
        └── tutor-mode.mdc        ← pair-programming tutor (manual @tutor-mode)
```

## Deployment (current: manual symlinks)

`cursor/` lives at the dotfiles repo root, NOT under `packages/`, so the main `install.sh` stow loop does not manage it. Symlinks are hand-created on a fresh machine:

```bash
ln -s ~/workspace/dotfiles/cursor/.cursor/mcp.json ~/.cursor/mcp.json
ln -s ~/workspace/dotfiles/cursor/.cursor/rules    ~/.cursor/rules
```

Once linked, any `.mdc` added to `dotfiles/cursor/.cursor/rules/` appears in `~/.cursor/rules/` automatically.

> **Candidate improvement:** move `cursor/` → `packages/cursor/` so stow handles it like `claude`, `git`, `nvim`, etc. Requires breaking the existing manual symlinks and re-stowing. Deferred.

## Rules

### `global-behavior.mdc` (always on)

Tone, directness, never-do list, technical preferences (bun > npm, mise, Terraform, 1Password), coding standards, work contexts (personal/Aria/Alertventure/Vault), and a startup instruction to read `$WIKI_VAULT/Assistant/USER.md` + `MEMORY.md`.

This is the Cursor equivalent of `~/.claude/CLAUDE.md`. Behavior in dotfiles, personal context in the vault — same pattern.

### `memory-capture.mdc` (always on)

Instructs Cursor to call the `append_to_daily_log` MCP tool (from the `memory-capture` server, registered in `mcp.json`) whenever a decision, correction, preference, or pattern worth remembering comes up. Writes to `$WIKI_VAULT/Assistant/memory/YYYY-MM-DD.md`.

Parallel to Claude Code's SessionEnd hook — except Cursor has no equivalent hook, so the rule itself is the forcing function. See the rule file for the trigger list and calibration guidance.

### `tutor-mode.mdc` (manual)

Turns Cursor into a pair-programming tutor instead of a code-completion service. Invoked with `@tutor-mode` in chat. Full details inline in the rule file.

Also available as a Claude Code slash command at `~/.claude/commands/tutor-mode.md` (same behavior, different surface).

## MCP servers

`mcp.json` registers:

- **memory-capture** — TypeScript server at `~/workspace/dotfiles/mcp-servers/memory-capture/`. Same server Claude Code uses. Shared daily-log file; `source_tool` field disambiguates which tool wrote each entry.
- **Snyk** — security scanner integration.

Adding a new server: edit this `mcp.json`, reload Cursor. MCP servers register at session start.

## Adding new rules

Drop a `.mdc` file in `.cursor/rules/` with this frontmatter:

```yaml
---
description: One sentence describing when this rule applies, written so Cursor's agent can decide whether to invoke it.
alwaysApply: false   # or true if it should always be on
globs:               # optional — auto-attach to matching files
  - "**/*.tf"
---
```

Then markdown content below. Three activation modes:

- **Manual** — `alwaysApply: false`, no globs. Invoke with `@rule-name`. (What `tutor-mode` uses.)
- **Auto-attached** — `alwaysApply: false` with `globs:`. Activates when matching files are in context.
- **Always-on** — `alwaysApply: true`. Always in context. (What `global-behavior` and `memory-capture` use.)

Prefer manual/auto-attached for opt-in behaviors. Reserve always-on for rules that must apply to every turn.
