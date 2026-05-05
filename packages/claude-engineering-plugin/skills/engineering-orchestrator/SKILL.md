---
name: engineering-orchestrator
description: Use when /engineer slash command is invoked or user describes role-aware engineering work. Sequences brainstorm → plan → execute → review with role specialization, calling vendored superpowers skills + new ensemble skills.
---

# Engineering Orchestrator

## Overview

The orchestrator is the spine of the engineering stack. It defines the full
lifecycle of a problem — from a one-line `/engineer "<problem>"` invocation to a
finished branch — by sequencing and parameterizing the vendored superpowers
skills and the four other new skills (`ensemble-planning`, `ensemble-review`,
`visionary-pass`, `merge-conflict-reconciler`).

It is intentionally thin. It does **not** reimplement brainstorm, plan, or
execute logic. The vendored skills already handle that. The orchestrator's job
is to call them in the right order, inject role-specialized contributions at
the right moments, and substitute role-flavored implementers/reviewers in
place of the generic ones.

## When to Use

- Invoked automatically by the `/engineer` slash command.
- Invoked when a user describes role-aware engineering work that obviously
  needs more than a single role can handle (e.g., "build a calculator app
  deployed to AWS" — touches frontend, backend, ux, cloud, security, cicd, qa).
- Not appropriate for one-shot single-file edits, simple bug fixes, or
  questions that don't need planning. Defer to the user's normal workflow
  in those cases.

## The Process

The full lifecycle (reproduced from the architecture spec) is nine steps:

1. **`/engineer "<problem statement>"`** — user invokes the slash command,
   which loads this orchestrator and passes the problem statement as input.
2. **`ensemble-planning` runs role-selection** — scans the problem and picks
   2-5 relevant role agents from the 12 available (e.g., for a cloud-deployed
   calculator: frontend, backend, ux-designer, cloud, security, cicd, qa).
3. **`brainstorming` (vendored) runs** — produces a spec. During brainstorm,
   `ensemble-planning` re-enters to have each selected role contribute
   concerns and `must_have_acceptance_criteria` so the spec is role-aware
   from the start.
4. **`spec-document-reviewer` (vendored) approves the spec** — gate before
   planning begins. If reviewer returns NEEDS_CHANGES, loop back to
   brainstorm.
5. **`writing-plans` (vendored) runs** — produces bite-sized TDD tasks.
   `ensemble-planning` re-enters to tag each task with its owning role(s)
   via `task_role_tags`, and may add extra tasks contributed by role
   advisors (e.g., security may add an `npm audit` step).
6. **`plan-document-reviewer` (vendored) approves the plan** — gate before
   execution begins. Loop back to writing-plans on NEEDS_CHANGES.
7. **`subagent-driven-development` (vendored) runs per task**, with these
   substitutions and additions:
   - **a.** Dispatch role-flavored implementer (`agents/frontend.md`,
     `agents/backend.md`, etc.) selected by `task_role_tags`, instead of
     the generic implementer.
   - **b.** Vendored spec-compliance reviewer runs.
   - **c.** Vendored code-quality reviewer runs.
   - **d.** `ensemble-review` fires role-specific reviewers for whichever
     roles owned the task.
   - **e.** Regression review (performance + qa + sre) runs when the diff
     warrants it — i.e., diff touches executable code, queries, infra, deps,
     or build configs. Skipped on docs-only / comment-only / config-only
     changes.
8. **`finishing-a-development-branch` (vendored) runs** — present merge / PR /
   cleanup options. If a merge surfaces conflicts, hand off to
   `merge-conflict-reconciler`.
9. **`visionary-pass` (optional, on demand only)** — proposes new directions
   for v-next. Never auto-runs; user must explicitly request it via
   `/engineer visionary` or `/visionary`.

Cross-cutting:

- Every `/engineer` session runs in its own worktree (vendored
  `using-git-worktrees`). Worktree isolation is automatic, not opt-in.
- `merge-conflict-reconciler` activates at merge-back when two worktrees
  overlap.

## Composes with

- **`ensemble-planning`** — for role selection at step 2 and role-flavored
  contributions at brainstorm (step 3) and plan (step 5).
- **vendored `brainstorming`** — runs at step 3 with ensemble-planning's
  contributions injected as role-specific concerns and acceptance criteria.
- **vendored `writing-plans`** — runs at step 5; tasks are tagged with owning
  roles via `task_role_tags`.
- **vendored `subagent-driven-development`** — runs at step 7, with the
  generic implementer substituted by the role-flavored implementer for each
  task based on its role tags.
- **`ensemble-review`** — runs after each task's vendored reviews complete
  (step 7d/7e), adds role-flavored review passes plus regression review.
- **`visionary-pass`** — invoked only on user request at step 9.

Worktree management is delegated to the vendored `using-git-worktrees`
skill; merge-back conflicts are delegated to `merge-conflict-reconciler`.

## Inputs / Outputs

**Inputs:**

- Problem statement (free-form text from `/engineer`).
- Optional flags: `plan` (stop after step 6), `review` (run only step 7d/7e
  on the current branch), `roles` (list configured roles and exit),
  `visionary` (jump directly to step 9).

**Outputs:**

- A worktree with: spec document, approved plan, executed tasks (each with
  task-scoped commits), and a branch ready for merge/PR.
- Or, on `plan`-only mode: spec + plan, no execution.

## Key invariants

- **Thin.** The orchestrator does not reimplement brainstorm/plan/execute
  logic; it sequences the vendored skills. New behavior lives in the
  ensemble skills, not here.
- **Worktree-isolated.** Each `/engineer` session runs in its own worktree
  via vendored `using-git-worktrees`. Multi-session safety is automatic.
- **Vendored skills stay pristine.** The orchestrator never modifies
  `skills/superpowers-vendored/` — it parameterizes them via inputs and
  substitutes implementers/reviewers via dispatch, not editing.
- **Role-flavored implementer dispatch is per-task.** `task_role_tags` from
  `ensemble-planning` decide which role agent(s) get dispatched for each
  task; if multiple roles own a task, the orchestrator coordinates them.
- **Composition over modification.** New behavior is added as new skills or
  agents that run alongside vendored ones, never by editing them.
