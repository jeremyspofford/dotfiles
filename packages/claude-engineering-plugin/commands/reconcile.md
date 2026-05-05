---
description: Resolve merge conflicts between worktrees using merge-conflict-reconciler skill.
---

# /reconcile

Args: $ARGUMENTS

This command is top-level rather than a `/engineer` subcommand because it is
typically invoked in a *different* context than `/engineer` — often reactively,
right after a failed merge, possibly when no `/engineer` session is active at
all. Surfacing it at the top level makes it reachable from anywhere.

Routes to the `merge-conflict-reconciler` skill, which handles diagnosis,
identifying originating tasks in each branch, and either auto-resolving
cosmetic/same-intent conflicts or dispatching the `conflict-reconciler`
agent for semantic merges.

## Routing

Parse `$ARGUMENTS`:

- `--help` → print the **Usage** block below and stop. Do nothing else.
- `--dry-run` → invoke the `merge-conflict-reconciler` skill in
  diagnose-only mode. The skill should classify conflicts and explain its
  proposed resolution path, but must not write to files or commit.
- A positional `<worktree-path>` (no leading `--`) → invoke the
  `merge-conflict-reconciler` skill with that worktree path as the conflict
  source.
- No args → invoke the `merge-conflict-reconciler` skill with no path. The
  skill will infer the conflict source from the current git state (typically
  the worktree the user is currently inside, or the most recently failed
  merge in the repository).

If both `--dry-run` and a positional path are given, pass both through —
diagnose the named worktree without writing.

## Usage

```
/reconcile                            # infer worktree from current state
/reconcile <worktree-path>            # explicit worktree to reconcile
/reconcile --dry-run                  # diagnose only, don't write
/reconcile --help
```

## Examples

`/reconcile .worktrees/engineer-add-billing`
