# AI: private side

The tools themselves are public: **github.com/jeremyspofford/ai-toolkit** (Claude Code plugin + Resume as Code template), listed at jeremyspofford.dev/toolkit. This repo holds only what's personal:

| Path | What |
|---|---|
| `packages/ai-toolkit/.config/ai-toolkit/config.yml` | My config for the public skills (clients, email, Jira site). Stowed to `~/.config/ai-toolkit/config.yml` by `./stow.sh`. |
| `ai/routines/` | Exact prompts of my Claude scheduled tasks, for reference and diffing. The tasks themselves live in my Claude account. |
| `claude-plugins/` | Older client-specific commands, superseded by the public `ai-toolkit` skills + config. |

**Rule:** new tools go in `ai-toolkit` (generic, config-driven); only config and client-specific bits go here.

## Install the public tools on a new machine

```bash
./stow.sh ai-toolkit
claude plugin marketplace add jeremyspofford/ai-toolkit
claude plugin install ai-toolkit@jeremyspofford
```
