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
  deployed to AWS" plausibly touches frontend, backend, ux, cloud, security,
  cicd, qa — 7 roles, which exceeds the default 5-role cap; `ensemble-planning`
  would surface this and confirm with the user before proceeding).
- Not appropriate for one-shot single-file edits, simple bug fixes, or
  questions that don't need planning. Defer to the user's normal workflow
  in those cases.

## The Process

The full lifecycle (reproduced from the architecture spec) is nine steps:

1. **`/engineer "<problem statement>"`** — user invokes the slash command,
   which loads this orchestrator and passes the problem statement as input.
2. **`ensemble-planning` runs role-selection** — scans the problem and picks
   2-5 relevant role agents from the 10 auto-selectable ones (`visionary` and
   `conflict-reconciler` are never auto-selected). If the rules of thumb
   would select more than 5, ensemble-planning pauses to confirm with the
   user (e.g., a cloud-deployed calculator could plausibly want frontend,
   backend, ux-designer, cloud, security, cicd, qa — 7 roles, would prompt).
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
     the generic implementer. **Mechanism:** when invoking
     `subagent-driven-development`'s implementer step, the orchestrator
     resolves the agent file path (e.g., `agents/frontend.md`) from the
     task's role tag and passes that as the role/persona context the
     vendored skill dispatches to a fresh subagent. The vendored skill
     itself is not edited; substitution happens at dispatch time.
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

- **`ensemble-planning`** — at step 2: input = problem statement; output =
  `selected_roles[]`, `role_concerns[]`. At step 5: input = approved spec;
  output = `task_role_tags`, `extra_tasks`. See `ensemble-planning/SKILL.md`
  for the full contract.
- **vendored `brainstorming`** — at step 3: input = problem statement +
  ensemble-planning's `role_concerns[]` (woven in as role-specific
  acceptance criteria); output = spec document.
- **vendored `writing-plans`** — at step 5: input = approved spec + the role
  tags from ensemble-planning; output = plan document with TDD tasks.
- **vendored `subagent-driven-development`** — at step 7: input = plan +
  resolved agent file path (per task) for the implementer substitution;
  output = task commits + spec/quality review approvals.
- **`ensemble-review`** — at step 7d/7e (per task): input = task text +
  role tags + diff SHAs + prior review outputs; output = aggregate status +
  per-role findings + regression review findings (when triggered).
- **`visionary-pass`** — at step 9 (only on user request): input = project
  state (recent git log, current spec, optional pain points); output = 3-7
  starter-spec proposals.

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
