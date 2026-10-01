# AI toolkit

The source of truth for my AI commands, skills, scheduled routines, and reusable prompts.

- `toolkit.yml` is the manifest. Every entry has `public: true|false`.
- Entries marked `public: true` are exported to the Toolkit page on jeremyspofford.dev by `export_toolkit.py`. Everything else stays in this (private) repo.
- A public entry may point at a separate, sanitized `public_source` file when the real one contains client names, emails, or internal hostnames. **Never** mark a file public that contains those.

## Layout

| Path | What |
|---|---|
| `routines/` | Prompts for scheduled tasks (Claude scheduled tasks run these; keep the task prompt short and point it at a versioned procedure) |
| `prompts/` | Reusable prompts to paste into a chat |
| `../claude-plugins/` | Claude Code plugin: commands and skills (Jira, timesheet) |

## Publish to the site

```bash
python3 ~/workspace/dotfiles/ai/export_toolkit.py ~/workspace/personal/portfolio
cd ~/workspace/personal/portfolio && git add src/data/toolkit && git commit -m "chore(toolkit): sync from dotfiles" && git push
```

The monthly resume routine also runs this export, so the page stays current.

## Scheduled tasks live in the Claude account

The task definitions themselves (name, schedule, which computer) live in Claude, not here. Each task's prompt should be the short "pull the repo and follow this file" form, with the real instructions versioned in git. When a task changes, update its entry here.
