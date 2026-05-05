---
description: Role-aware engineering orchestrator. Brainstorms, plans, executes, and reviews multi-step engineering work with specialized role agents.
---

# /engineer

Args: $ARGUMENTS

You are executing the `/engineer` slash command — the primary entry point for the
engineering stack. Your job is to parse the arguments above, route to the right
skill or sub-handler, and respect the worktree precondition.

## Routing

Parse the first whitespace-delimited token of `$ARGUMENTS`:

- `--help` or `help` → print the **Usage** block below and stop. Do nothing else.
- `plan` → invoke the `engineering-orchestrator` skill with `mode=plan-only` and
  the rest of `$ARGUMENTS` (everything after `plan`) as the problem statement.
  The orchestrator should produce a plan and stop before execution.
- `review` → invoke the `ensemble-review` skill against the current branch's
  recent diff (compared to its merge base with the default branch). No problem
  statement is needed; the diff is the input.
- `roles` → list the contents of the plugin's `agents/` directory. For each
  agent file, print the agent name and the `description` from its frontmatter.
  Resolve `<plugin-root>` as the parent directory of the `commands/` directory
  containing this file (i.e., this command lives at `<plugin-root>/commands/engineer.md`,
  so the agents are at `<plugin-root>/agents/*.md`). Emit a compact table.
- `visionary` → invoke the `visionary-pass` skill. Pass through any remaining
  arguments (e.g. `--scope=<area>`).
- `reconcile` → invoke the `merge-conflict-reconciler` skill. If a positional
  worktree path follows (`/engineer reconcile <path>`), pass it through.
- Anything else (including no args) → treat the entire `$ARGUMENTS` value as
  the problem statement and invoke the `engineering-orchestrator` skill in
  full lifecycle mode (brainstorm → plan → execute → review).

## Worktree precondition

Before invoking the `engineering-orchestrator` skill (full lifecycle or
plan-only), verify a git worktree is set up for this session. The orchestrator
expects each `/engineer` session to run in its own worktree at
`<repo-root>/.worktrees/engineer-<slug>/`.

If you are not already in such a worktree, invoke the vendored
`using-git-worktrees` skill first to create one for the current problem
statement, then dispatch the orchestrator from inside it.

This precondition does **not** apply to `review`, `roles`, `visionary`, or
`reconcile` — those run in whatever directory the user is currently in.

## Usage

```
/engineer "<problem statement>"        # full lifecycle
/engineer plan "<problem statement>"   # produce plan only, defer execution
/engineer review                       # ensemble-review current branch's recent work
/engineer roles                        # list configured role agents
/engineer visionary                    # invoke visionary-pass
/engineer reconcile [worktree-path]    # delegate to merge-conflict-reconciler
/engineer --help                       # show usage
```

## Examples

- `/engineer "build a REST API for managing todo items with auth"` — runs the
  full lifecycle: ensemble brainstorm, role-aware plan, executed in a worktree,
  ensemble review on each task.
- `/engineer plan "migrate auth from session cookies to JWT"` — produces the
  plan but stops before execution; useful when you want to inspect or revise.
- `/engineer review` — runs ensemble review against the current branch's recent
  diff. Useful right before opening a PR.
- `/engineer roles` — prints the configured role agents and their descriptions
  so you know which specialists are available.
- `/engineer visionary --scope=performance` — proposes new directions focused
  on performance for the current project.
