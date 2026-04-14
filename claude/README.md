# claude — dotfiles package

GNU stow package containing all Claude-related config that should follow Jeremy across machines.

## What stows where

This package mirrors `$HOME/.claude/` — when `install.sh` runs `stow claude`, everything under `.claude/` ends up at `~/.claude/`.

```
.claude/
├── CLAUDE.md            → ~/.claude/CLAUDE.md            # Global persona/preferences for Claude Code
├── settings.json        → ~/.claude/settings.json        # Permissions, hooks, defaults
├── commands/            → ~/.claude/commands/            # Custom slash commands
│   ├── init-project.md
│   ├── lecture-note.md  #  /lecture-note   — transcript → study note + SR cards
│   └── quiz-me.md       #  /quiz-me        — Socratic active-recall session
├── cheatsheets/         → ~/.claude/cheatsheets/         # Quick-reference docs
│   ├── cert-study-workflow.md
│   ├── flashcard-format.md
│   └── style-picker.md
├── projects/            → ~/.claude/projects/            # Claude.ai Project instructions (one per project)
│   └── (CKA, AIF-C01, etc. as added)
└── prompts/             → ~/.claude/prompts/             # Standalone prompts (Chrome ext shortcuts, etc.)
    └── chrome-ext-lecture-note.md
```

## What does NOT stow

`.stow-local-ignore` excludes top-level docs from stowing (otherwise they'd land in `~/`):

- `README.md` — this file
- `saa-c03-project-instructions.md` — original location, kept for git history; canonical home now `.claude/projects/saa-c03.md`

## Sync to Obsidian Vault

The vault assistant (running via filesystem MCP from `~/Obsidian_Vault/CLAUDE.md`) can read directly from `~/.claude/` once stowed — no separate symlinks needed. If you want cheatsheets visible inside the vault for browsing in Obsidian itself, symlink:

```bash
ln -sf ~/.claude/cheatsheets ~/Obsidian_Vault/Assistant/cheatsheets
```

## Slash commands

Files in `.claude/commands/*.md` become Claude Code slash commands. Filename minus `.md` is the command name. The file body is the prompt sent when invoked.

| Command | Purpose |
|---|---|
| `/init-project` | Scaffold per-project Claude config (extends built-in `/init`) |
| `/lecture-note` | Read a Udemy transcript and generate study note + SR cards in the vault |
| `/quiz-me` | Socratic active-recall quiz on a given note or topic |
