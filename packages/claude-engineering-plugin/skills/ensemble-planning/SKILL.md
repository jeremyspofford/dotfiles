---
name: ensemble-planning
description: Use during brainstorm and writing-plans phases. Selects 2-5 relevant role agents per problem; invokes each in advisor mode to contribute concerns and acceptance criteria.
---

# Ensemble Planning

## Overview

Ensemble planning has two jobs:

1. **Role selection.** Scan the problem statement and pick 2-5 relevant role
   agents from the 12 available. The selection is per-problem, not global —
   a trivial CLI tool gets 1-2 roles; a cloud-deployed app gets 5-7. Rarely
   all 12.
2. **Role-flavored contributions.** Invoke each selected role in advisor mode
   during the brainstorm and writing-plans phases so the spec and plan are
   shaped by the right concerns from the start, not retro-fitted later.

## When invoked

- By `engineering-orchestrator` at **brainstorm-start** (to select roles and
  collect their concerns + acceptance criteria for the spec).
- By `engineering-orchestrator` at **plan-start** (to tag each task with its
  owning role(s) and let advisors contribute extra tasks).

This skill never runs standalone.

## Inputs / Outputs

**Brainstorm phase:**

- **Input:** problem statement; list of available role agents (under
  `agents/`).
- **Outputs:**
  - `selected_roles[]` — the 2-5 roles chosen for this problem.
  - `role_concerns: [{role, concerns[], must_have_acceptance_criteria[]}]` —
    each role's contributions, woven into the brainstorm output.

**Plan phase:**

- **Input:** the approved spec.
- **Outputs:**
  - `task_role_tags: {task_id: [owning_roles]}` — annotates each task with
    the role(s) responsible for it. `subagent-driven-development` uses this
    to dispatch role-flavored implementers in place of the generic one.
  - `extra_tasks: []` — additional tasks contributed by role advisors
    (e.g., security might add an `npm audit` step; sre might add a runbook
    task).

## Role selection rules of thumb

The 12 roles and when each is selected:

- **backend** — always selected if any code is involved.
- **frontend** — UI / CLI / UX surface.
- **cloud** — deployment target named.
- **security** — auth, data, secrets, dependencies, IaC, regulated content.
- **cicd** — deployment in scope, OR security/cloud/sre selected (CI/CD
  coordination is almost always needed when those are in play).
- **sre** — production-running service.
- **network** — topology / firewall / ACL / VPC mentioned.
- **ux-designer** — user-facing UI.
- **qa** — non-trivial multi-component work.
- **performance** — diff touches executable code / queries / infra / deps /
  build configs (selected at task level, not project level — checked per
  task during the plan phase).
- **visionary** — never auto-selected; explicit user invocation only.
- **conflict-reconciler** — never auto-selected at planning time; activated
  by merge-conflict events only.

## Role budget cap

Default cap: **5 roles** per problem. If the rules of thumb above would
select more than 5, pause and ask the user to confirm before proceeding.
Surface the candidate list with a one-line justification per role and let
the user trim or accept.

The cap exists because:

- More roles means more advisor passes during brainstorm and more reviewer
  passes per task — costs grow superlinearly with role count.
- Most problems genuinely need 2-4 roles. Six or more usually signals an
  over-broad problem statement that should be split.
- The user can always override; this is a conversational checkpoint, not a
  hard block.

## How role contributions are integrated

**At brainstorm:** each selected role is invoked in advisor mode and asked
for its concerns and `must_have_acceptance_criteria[]`. These get woven into
the spec the vendored `brainstorming` skill produces — typically as a
"Role-specific acceptance criteria" section keyed by role. Downstream
reviewers later check the diff against these criteria, so anything declared
must-have here becomes a gate.

**At plan:** the approved spec is fed to each selected role again, this time
to produce `task_role_tags` (who owns which task) and `extra_tasks` (what
additional tasks each role wants to add). The orchestrator uses
`task_role_tags` to dispatch the right role-flavored implementer per task in
`subagent-driven-development`. `extra_tasks` are merged into the plan
before `plan-document-reviewer` gates it.

## Key invariants

- **Per-problem selection, not global.** Don't carry role selection across
  sessions; re-run it per `/engineer` invocation.
- **5-role default cap.** Always confirm with the user before exceeding it.
- **Advisor mode only at planning.** This skill never invokes roles in
  implementer or reviewer mode — those happen later, in
  `subagent-driven-development` and `ensemble-review`.
- **No auto-selection of `visionary` or `conflict-reconciler`.** Both are
  user-triggered or event-triggered, never selected by this skill.
