# Global Claude Instructions

## Who I Am

Jeremy Spofford. I build AI systems. Aria Labs is my initiative — not a client, not a company — it's where I put projects I want AI to have full, autonomous ownership of.

## Work Contexts

Two distinct identities:
- **Personal** — `jeremyspofford` on GitHub, personal projects, this dotfiles repo, lives under `~/workspace/`
- **Aria Labs** — `nova-arialabs` on GitHub, autonomous AI projects, lives under `~/workspace/arialabs/`, git identity switches automatically via `.gitconfig` conditional include

Aria Labs repos are ones where I want AI operating autonomously with minimal hand-holding. Personal repos are things I'm directly driving.

## Environment

- **OS**: Linux (Pop!OS) and WSL2, sometimes macOS
- **Shell**: zsh
- **Dotfiles**: `~/workspace/dotfiles` — GNU Stow, manages shell, git, ssh, nvim, 1password, claude configs
- **Runtime manager**: mise (manages Node, Python, bun, and other runtimes — no nvm)
- **SSH**: 1Password agent at `~/.1password/agent.sock`, Personal vault for personal keys, Aria Labs vault for work keys
- **Editor**: neovim 0.11

Key paths:
- Personal projects: `~/workspace/` 
- Aria Labs work: `~/workspace/arialabs/`
- Dotfiles: `~/workspace/dotfiles/`

## Technical Preferences

- **JS/TS runtime**: bun over npm/node where possible
- **Python**: managed via mise
- **Git**: delta pager, rebase on pull, conventional commits
- **No nvm** — mise handles all runtime versioning
- Prefer SSH over HTTPS for git remotes
- 1Password for all secrets — no credentials on disk

## How I Like to Work

- Be direct and concise. Skip preamble.
- Do the minimum to complete the task. No scope creep — a bug fix is a bug fix, not a refactor opportunity.
- Keep code clean: no speculative abstractions, no comments on obvious things.
- Reuse existing functions and patterns where they fit. If extending behavior that's similar but not identical, refactor to the right abstraction (e.g. a `Vehicle` base class when adding `Truck` alongside `Car`) — but only when there's a concrete need, not in anticipation of hypothetical future ones.
- Don't add features, error handling, or configurability that wasn't asked for.
- Don't summarize what you just did — I can read the output.
- When something is broken, diagnose before switching approaches.
- Ask before taking irreversible or wide-blast-radius actions (pushing, deleting, etc.).

## Project-Specific Configs

Each project has its own `.claude/` directory that extends this global config. When starting a new project, run `/init-project` to scaffold the project-specific Claude config.

## Goals for Claude Setup

Building toward: hooks for automation, agent/subagent workflows, integration with Linear and memory systems. The Claude config itself should be as thoughtfully engineered as the projects it supports.
