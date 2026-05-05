---
name: merge-conflict-reconciler
description: Use when merge-back from a worktree surfaces conflicts. Diagnoses, identifies originating tasks in each branch, and either auto-resolves (cosmetic/same-intent) or dispatches conflict-reconciler agent for semantic merge.
---

# Merge Conflict Reconciler

## Overview

When two worktrees produce conflicting changes at merge-back time, this
skill diagnoses the conflict, identifies the originating tasks in each
branch, and either auto-resolves (cosmetic / same-intent cases) or
dispatches the `conflict-reconciler` agent for a semantic merge. When the
conflict is too large or genuinely architectural, it escalates back to the
user with a concrete suggestion (typically: re-brainstorm the overlapping
scope).

The skill is intent-aware, not just text-aware. Because both branches in an
engineering-stack workflow have their own spec and plan files in the
worktree, the reconciler reads those alongside the conflicting hunks — so
its diagnosis knows what each branch was trying to do, not just what each
branch's text now says.

## When invoked

- **Automatically by `engineering-orchestrator`** at the merge step (step 8
  of the lifecycle) when `git merge` reports conflicts.
- **Manually** via `/reconcile <worktree-path>` — user-invoked when they
  hit a conflict outside an active orchestrator session, or when they want
  to dry-run reconciliation against a worktree before merging.

## Inputs

- **Two branch refs** (or worktree paths) — the branch being merged into
  and the branch being merged in.
- **Conflict markers from `git merge`** — the actual `<<<<<<<` / `=======`
  / `>>>>>>>` blocks the merge produced.
- **Plan files from both branches** — read the plan from each side so the
  reconciler can map conflicting hunks back to the originating tasks.
- **Recent task completion records** — which tasks in each plan touched the
  conflicting files; this is what makes "what was each branch trying to do"
  concrete.

## Reconciliation strategy (in order)

The reconciler tries each tier in order. If a tier resolves the conflict,
stop there. Only escalate to the next tier when the current one cannot.

1. **Cosmetic conflicts** — the textual diff is the only change; *no
   semantics added or removed* on either side. Examples: whitespace
   differences, line reordering of equivalent statements, formatting-only
   diffs (each side reformats existing code), trailing-newline
   inconsistency. Resolve via `git checkout --theirs` / `--ours`
   heuristics. Pick the side whose formatting matches the project's
   prevailing style; document the choice in the merge commit message.

2. **Same-intent conflicts** — *both branches added equivalent semantics
   independently*. The two sides aren't reformattings; they each added
   real content, but it's the same content duplicated. Examples: both
   branches added the same new import line, the same `const X = 5`, the
   same dependency to `package.json` (same name + same version).
   Distinguished from tier-1 by: real semantic content was added (it's
   not just formatting). Pick one side, document why.

3. **Semantic conflicts** (both branches modified the same logic with
   different intent — e.g., one branch added validation and the other
   refactored the function signature) — dispatch the `conflict-reconciler`
   agent with both branches' tasks + diffs as context. The agent proposes a
   unified resolution that honors both intents, **OR** returns `BLOCKED` if
   the intents cannot be reconciled mechanically. On agent proposal, write
   a merge commit that applies the resolution. On `BLOCKED`, escalate to
   the user with the agent's diagnosis attached.

4. **Architectural conflicts** (the specs themselves are mutually
   incompatible — e.g., one branch assumes synchronous processing and the
   other assumes async) — escalate. Suggest a re-brainstorm of the
   overlapping scope; do not attempt a merge. A textual resolution here
   would just paper over the design conflict and ship the worse of the two
   architectures.

## Hard limits

- **5 conflicting hunks max for auto-resolution.** If the merge produces
  more than 5 hunks across all files, the reconciler will not auto-resolve
  any of them — escalate. A conflict surface that big almost always
  signals a planning failure (overlapping scope, missing coordination,
  drifted assumptions) that no merge tactic can fix.
- **Architectural conflicts are never auto-resolved**, regardless of hunk
  count. Always escalate with a suggestion to re-brainstorm.

## Outputs

- On success: resolution applied as a merge commit, and `status:
  RESOLVED`. The commit message states which tier handled the conflict
  (cosmetic / same-intent / semantic), names the originating tasks from
  each branch, and summarizes the resolution.
- On failure: `status: BLOCKED` with a diagnosis pointing to which tasks
  on each side need re-planning, plus a concrete next step (typically
  "run `/engineer plan \"<overlapping scope>\"` to re-brainstorm before
  merging").

## Why intent-aware

Because the engineering-stack worktree carries its spec and plan alongside
the code, the reconciler reads those when deciding how to merge. This is
the whole reason it can distinguish tier-2 (same-intent) from tier-3
(semantic) — without the plans, both look like "two branches changed the
same lines." With the plans, the reconciler knows **what each branch was
trying to accomplish** and can resolve based on intent rather than text
alone.

This is also what makes tier-4 (architectural) detectable at all. When two
specs are mutually incompatible, the conflict will not surface as a single
hunk — it surfaces as a pattern of conflicts spread across the diff. The
reconciler reads both specs, notices the incompatibility, and escalates
before producing a merge commit that would hide the design conflict.
