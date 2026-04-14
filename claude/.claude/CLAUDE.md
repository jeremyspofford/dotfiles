# Global — Jeremy Spofford

## Core Operating Rule

Do not proceed with any substantive task unless you are at least 95% certain
you understand what I am requesting.

## Required Decision Process

For every request:

1. Interpret the request
2. Estimate whether you understand it with at least 95% confidence
3. If below 95%, ask the minimum number of focused clarifying questions needed and stop
4. Do not guess through major ambiguity or silently invent missing requirements
5. Once at 95%+ confidence, proceed directly
6. For risky, destructive, security-sensitive, or costly actions, restate the goal,
   constraints, and likely impact before acting

## Who I Am

Jeremy Spofford — cloud/DevOps engineer studying for AWS SAA-C03. I work across
multiple repos and contexts (Obsidian vault, portfolio site, infrastructure projects).
Be direct, skip pleasantries, have opinions, and get things done.

## Global Preferences

- YAML frontmatter on all Obsidian notes (tags, type, created, plus type-specific fields)
- No emojis unless I explicitly ask
- Direct communication — skip filler and pleasantries
- Brutal honesty over agreeableness — push back when I'm wrong
- Have opinions — recommend the approach you'd actually use
- Security first — always flag security concerns, never skip them

## Coding Standards

- TypeScript over JavaScript when the project supports it
- Prefer existing patterns in a codebase over introducing new ones
- Security is non-negotiable — never skip auth, validation, or sanitization
- Tests should protect against real regressions, not chase coverage percentages
- Infrastructure as Code (Terraform) — no manual cloud resource creation

## Agent Fleet

Repos with .claude/agents/ contain autonomous review agents that run via GitHub Actions:

| Agent | Focus | Priority |
|-------|-------|----------|
| security-audit | Secrets, injection, auth, CVEs, infra security | 1 |
| performance-review | Bundle size, Web Vitals, rendering, cold starts | 2 |
| architecture-review | Separation of concerns, code organization, dead code | 3 |
| api-quality | Consistency, error handling, validation, CORS | 4 |
| frontend-quality | Accessibility, SEO, TypeScript quality, UX | 5 |
| test-coverage | Critical paths without tests, edge cases, integration gaps | 6 |
| dependency-health | CVEs, outdated packages, unused deps, auto-merge bumps | 7 |

Agents create GitHub issues tagged agent-fleet. The dependency-health agent can
auto-merge safe bumps (patch/minor) when tests pass.

## Global Slash Commands

### /review [scope]
On-demand codebase review. Runs security, performance, architecture, API, frontend,
test coverage, and dependency checks inline. Accepts agent names or file paths to scope.

### /note [content]
Intelligent Obsidian note creator. Classifies content (study, code-pattern, how-to,
reference), auto-picks vault location, formats with full YAML frontmatter.
Note: for content generated during active work sessions, prefer /wiki capture —
it writes to the correct raw/ path and sets ingested: false for later processing.
Use /note for standalone reference material that doesn't need wiki ingest.

---

## Wiki Vault

Your Obsidian wiki vault is at $WIKI_VAULT. This variable is set conditionally
by OS in .zshrc/.bashrc. If it is not set, do not attempt any wiki operations —
tell the user: "WIKI_VAULT is not set. Please check your shell config."

Full operational detail for all wiki workflows lives in $WIKI_VAULT/CLAUDE.md.
Read that file before executing any /wiki command.

### Passive capture rule

While working in any repository, if you learn something worth preserving —
a decision made, a pattern identified, a problem solved, an approach that worked
or failed — write a brief rough note to:

  $WIKI_VAULT/raw/[domain]/[project]/[YYYY-MM-DD]-session.md

Use resolve-project-path logic to infer [domain]/[project] from CWD (strips
$HOME/workspace/ prefix). If today's note already exists, append to it.

Frontmatter for all raw notes:
---
source_project: [domain]/[project]
captured_date: YYYY-MM-DD
session_context: "one line describing what you were working on"
ingested: false
---

Keep captures fast and rough. Do not stop to organize.

Do NOT capture for:
- Repos containing a .nowiki file at root
- Paths matching WIKI_IGNORE_PATTERNS in ~/.claude/hooks/ignore-patterns.sh
- Worktree subdirectories (resolve to main worktree root, capture there instead)

### /wiki capture [--project domain/project] [--type decision|pattern|reference|note] [--tags tag1,tag2]
Deliberate mid-session capture. Infer --project from CWD if omitted.
Default --type is note. Use approved tags from $WIKI_VAULT/CLAUDE.md tag registry only.
Propose new tags via /wiki tag propose before using unapproved ones.

### /wiki ingest [domain/project]
Process all raw notes with ingested: false. Follow full ingest workflow in
$WIKI_VAULT/CLAUDE.md. No argument = ingest all pending across all domains.

### /wiki query <question>
Answer from the wiki. Read wiki/index.md first, drill into relevant pages,
cite sources. Offer to file valuable answers back as new wiki pages.

### /wiki lint [domain/project]
Audit wiki for contradictions, orphan pages, stale claims, missing concept pages,
formatting violations. Scoped to domain/project if provided, otherwise full vault.

### /wiki status
Report: last ingest date per domain, pending raw note count (ingested: false),
total wiki page count, pages marked status: needs-review.

### /wiki tag propose <tagname> [--category <category>]
Propose a new tag for the approved registry. Identify existing pages it would
back-fill. Get explicit user approval before writing anything. On approval:
add to registry in $WIKI_VAULT/CLAUDE.md, apply to new content, back-fill
identified pages, log the change in wiki/log.md.
