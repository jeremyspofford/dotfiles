---
name: ensemble-review
description: Use after each task's vendored spec/quality reviews approve. Fires role-flavored reviewers for whichever roles owned the task, plus regression review when diff warrants.
---

# Ensemble Review

## Overview

Ensemble review runs after a task has cleared the vendored
`subagent-driven-development` reviews (spec-compliance and code-quality). At
that point the task is "well-formed" but has not yet been examined through
role-specific lenses. This skill fires role-flavored reviewers for whichever
roles owned the task — frontend reviews accessibility, backend reviews
input validation and idempotency, security reviews auth and dependency
posture, and so on — and coordinates the regression review pass when the
diff warrants it.

It is the gate that turns "code that compiles and matches the spec" into
"code that's responsibly shipped given who owns what part of the system."

## When invoked

By `engineering-orchestrator` after `subagent-driven-development`'s
spec-compliance and code-quality reviewers have approved a task. Never
invoked standalone, never invoked before the vendored reviews.

## Inputs

- **Task text** — the full task description from the plan.
- **Role tags** — `task_role_tags[task_id]` from `ensemble-planning`,
  identifying which role(s) own this task and therefore which reviewers
  should be dispatched.
- **Diff SHAs for the task** — the commits produced during this task's
  implementation. Used to compute the actual diff for review.
- **Prior review outputs** — the vendored spec-compliance and code-quality
  reviewer findings. Role reviewers consume these so they don't duplicate
  what's already been said.

## Outputs

- **Per-role findings** — for each role that reviewed, a list of
  `{severity, file, line, issue, fix}` entries.
- **Aggregate `status`** — one of:
  - `APPROVED` — all role reviewers returned APPROVED.
  - `NEEDS_CHANGES` — at least one role returned NEEDS_CHANGES; implementer
    fixes; reviewer re-checks.
  - `BLOCKED` — at least one role returned BLOCKED, or two reviewers are in
    direct domain conflict; escalate to user.
- **Regression review findings** — if the regression review ran, its output
  is folded into the aggregate.

## Regression review trigger

The regression review (performance + qa + sre dimensions) runs **after**
role reviews when the diff touches:

- Executable code (functions, methods, modules — anything that runs).
- Queries (SQL, ORM calls, search/index access).
- Infrastructure (Terraform, k8s manifests, cloud config).
- Dependencies (package manifest changes, lockfile churn).
- Build configs (bundler/compiler/CI build configs that affect output).

It is **skipped** on:

- Docs-only changes (`*.md`, comments).
- Comment-only changes (no executable lines moved).
- Config-only changes that don't affect runtime behavior (e.g., editor
  configs, lint rule tweaks).

Inspect the diff via `git diff <task-base>..<task-head>` to make this
determination. When in doubt, run regression review — false positives cost
a few extra reviewer invocations; false negatives let regressions ship.

## Failure modes

- **Role reviewer returns NEEDS_CHANGES** — implementer fixes the issue;
  reviewer re-checks. Loop is bounded: **max 3 iterations** before
  escalating to the user. Past three rounds, either the issue is genuinely
  ambiguous or the implementer/reviewer pair are talking past each other —
  human input resolves it faster than another loop.
- **Two role reviewers in direct domain conflict** (e.g., security wants X
  for posture, cloud says X is cost-prohibitive at expected scale) —
  **ESCALATE** to user. Surface both findings with the conflict made
  explicit. Do **not** auto-resolve domain trade-offs — those are
  judgment calls the user owns. Status returns `BLOCKED` with both
  findings attached.
- **Reviewer returns confidence < 0.6** — surface as "low confidence" in
  the aggregate output. The user reviews and decides whether to accept,
  re-run, or override. Confidence under 0.6 usually means the reviewer
  doesn't have enough context to be sure either way.

## Key invariant

**Never auto-resolve a security-vs-X tradeoff.** If security and cloud,
security and performance, security and frontend, etc. produce findings
that are mutually exclusive, the call belongs to a human. Surface both
findings, summarize the trade-off in plain language, and stop. Auto-picking
a side here is exactly how stacks ship insecure-by-accident or
cost-blowout-by-accident code.
