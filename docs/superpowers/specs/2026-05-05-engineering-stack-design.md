# Engineering-Stack Design

> **Spec date:** 2026-05-05
> **Author:** Jeremy Spofford
> **Status:** Draft (pending spec-document-reviewer pass)
> **Working name:** `engineering-stack` (final name TBD)
> **Type:** Claude Code plugin, distributable to other Claude Code users; planned MCP server for Cursor and other MCP-supporting tools.

---

## Problem statement

A working engineer (network, software, devops, security, platform, SRE, cloud, or other technical role) needs to state a problem and have an AI orchestrator break it down into tasks, plan each in detail, and dispatch role-specialized subagents to execute and review the work — with multi-session worktree safety and merge-conflict reconciliation. Existing tooling (notably Anthropic's superpowers plugin) covers the brainstorm → plan → execute → review spine, but lacks role-specialized advisors/implementers/reviewers, an explicit ideation pass ("visionary"), and cross-session merge-conflict reconciliation.

This project closes those gaps by building a Claude Code plugin that vendors superpowers as its foundation and layers role-aware skills, role agents, slash commands, and a merge-conflict reconciler on top.

---

## Goals

The two primary goals (locked in during brainstorming):

- **A. Independence from upstream maintenance.** The plugin must continue to work even if any external dependency (notably superpowers) is deprecated or stops receiving contributions. Solved by vendoring superpowers' skill content into this repo under `skills/superpowers-vendored/` and pinning it.
- **B. Distribution.** Other engineers should be able to install this plugin in one step (`/plugin install <git-url>`), get a self-contained workflow, and not need to install or know about any other plugin to use it.

Secondary goals (carried implicitly through the design):

- Role specialization without role bloat — the orchestrator selects 2-5 relevant roles per problem; rarely all 12.
- Failure-mode visibility — failure modes are categorized and surfaced loudly rather than absorbed quietly.
- Future portability — Tier 2 (MCP for Cursor, Cline, Continue, etc.) and Tier 3 (AGENTS.md) are planned; v1 ships full-fidelity Tier 1 (Claude Code plugin) only.

---

## Non-goals (explicit)

- **Not** a from-scratch reimplementation of superpowers' brainstorm/plan/execute spine. We vendor and extend; we don't rebuild orchestration logic that already works.
- **Not** a CI/CD validation pipeline for this plugin's own repo in v1. Solo use needs only a manual `bin/lint-plugin` script; CI configs get added when the first external contributor arrives or when the first public release is tagged.
- **Not** a runtime monitoring system for deployed services. The plugin sets up the integration points (sre + cicd roles handle this); the deployed observability platform does the watching.
- **Not** automatic conflict resolution beyond a 5-hunk cap. Beyond that we escalate to humans.
- **Not** locks or mutual exclusion on files across parallel sessions. That's deadlock-prone and not worth its cost.

---

## Architecture

### Layered structure

```
┌─────────────────────────────────────────────────────────────┐
│  User-facing entry points (commands/)                       │
│    /engineer "<problem>"     /reconcile [worktree]          │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  Engineering-stack skills (yours, in skills/)               │
│    engineering-orchestrator                                  │
│    ensemble-planning   ensemble-review                       │
│    visionary-pass      merge-conflict-reconciler             │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  Vendored superpowers skills (replaceable, in               │
│  skills/superpowers-vendored/)                              │
│    brainstorming → writing-plans →                           │
│    subagent-driven-development → finishing-a-development-    │
│    branch (+ tdd, worktrees, debugging, verification, etc.) │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  Role agents (agents/) — dispatched as subagents             │
│    frontend  backend  ux-designer  security  cloud  cicd     │
│    sre  network  qa  performance  visionary                  │
│    conflict-reconciler                                       │
└─────────────────────────────────────────────────────────────┘
```

### Lifecycle of a problem

```
1. /engineer "build a calculator app deployed to AWS"
        │
        ▼
2. ensemble-planning runs role-selection
        │      ↳ picks: frontend, backend, ux, cloud, security, cicd, qa
        ▼
3. brainstorming (vendored) — produces spec
        │      ↳ ensemble-planning has each selected role contribute
        │        concerns + acceptance criteria during brainstorm
        ▼
4. spec-document-reviewer (vendored) approves spec
        │
        ▼
5. writing-plans (vendored) — bite-sized TDD tasks
        │      ↳ ensemble-planning tags each task with owning role(s)
        ▼
6. plan-document-reviewer (vendored) approves plan
        │
        ▼
7. subagent-driven-development (vendored) — per task:
        │     a. Dispatch role-flavored implementer (frontend.md, etc.)
        │     b. Spec compliance reviewer (vendored)
        │     c. Code quality reviewer (vendored)
        │     d. ensemble-review fires role-specific reviewers
        │     e. Regression review (performance + qa + sre) when diff
        │        warrants it (skip docs-only / config-only changes)
        ▼
8. finishing-a-development-branch (vendored)
        │
        ▼ (optional, on demand)
9. visionary-pass — proposes new directions for v-next

──── Cross-cutting ────
- Every /engineer session runs in its own worktree
  (using-git-worktrees, vendored)
- merge-conflict-reconciler activates at merge-back when two
  worktrees overlap
```

### Plugin manifest

```json
{
  "name": "engineering-stack",
  "version": "0.1.0",
  "description": "Role-aware engineering orchestrator for Claude Code",
  "author": "Jeremy Spofford",
  "credits": "Built on superpowers (Anthropic claude-plugins-official) — vendored and extended"
}
```

### Key invariants

- **Worktree isolation by default.** Multi-session safety is automatic, not opt-in.
- **Role selection is per-problem, not global.** A trivial CLI tool gets 1-2 roles; a cloud-deployed app gets 5-7. Rarely all 12.
- **Vendored skills are pristine.** Modifications go in your skills, not theirs — preserves diff-against-upstream.
- **Composition over modification.** New behavior is added as new skills/agents that run alongside, not by editing vendored content.
- **Regression detection is selective.** It runs only when the diff touches executable code, queries, infra, deps, or build configs. Docs/config-only changes skip it.

---

## Role agents (12)

### Common template

Every agent file (`agents/<role>.md`) follows this shape:

```yaml
---
name: <role>
description: When this agent should be dispatched
tools: [Read, Grep, Bash, ...]   # explicit allowlist, minimal
model: sonnet | opus | haiku
---

# <Role> Agent

## Purpose
<1-2 sentences>

## Modes
<advisor | implementer | reviewer — sometimes multiple>

## Scope (in / out)
- IN: <what this role cares about>
- OUT: <what this role explicitly does NOT touch>

## Input contract
- mode: <which mode this invocation is>
- context: <task text + relevant file paths + prior context>
- constraints: <any constraints from prior role passes>

## Output contract
- concerns / changes_made / findings (depending on mode)
- status: APPROVED | NEEDS_CHANGES | BLOCKED
- confidence: 0.0-1.0

## Quality checklist
<role-specific items that must be true before status=APPROVED>

## Escalation triggers
<when to return BLOCKED>
```

### The 12 roles

| Agent | Modes | Trigger | Distinguishing concerns | Model |
|---|---|---|---|---|
| **frontend** | implementer, reviewer | UI/components/styling | A11y, responsive layout, component boundaries, frontend tests | sonnet |
| **backend** | implementer, reviewer | API/server/data layer | Idempotency, input validation, transactional boundaries, backend tests | sonnet |
| **ux-designer** | advisor | Brainstorm when UI is in scope | IA, user flows, friction points, naming clarity | opus |
| **security** | advisor, reviewer | Brainstorm + auth/input/deps/secrets/IaC | OWASP top 10, dependency CVEs, auth flow, secret handling, IaC sec posture | opus |
| **cloud** | implementer, reviewer | IaC / deployment / cloud resources | Terraform structure, cost, blast radius, IAM least-privilege, region/AZ strategy | sonnet |
| **cicd** | implementer, advisor, reviewer | Pipeline configs / deploy automation / release tooling | Platform-agnostic pipeline design (GitHub Actions, GitLab CI, Jenkins, CircleCI, Bitbucket, Drone, Forgejo Actions, Buildkite, Tekton, etc.), caching, matrix builds, secret management, deployment strategy, rollback, env promotion, **pipeline performance** | sonnet |
| **sre** | implementer, advisor | Brainstorm + production-running tasks | Monitoring, alerting, SLOs, runbooks, capacity, incident readiness, post-deploy verification | sonnet |
| **network** | advisor, reviewer | Routing/firewall/ACLs/VPC/DNS | Topology, segmentation, latency paths, ACL correctness | opus |
| **qa** | implementer, reviewer | After major scope completion | Integration test design, edge cases, E2E flows, regression risk, **quality regression checks** | sonnet |
| **performance** | advisor, reviewer | Brainstorm (set targets) + diff touches executable code/infra/deps | Latency, throughput, memory, bundle size, Web Vitals, cold start, query plan changes, regression vs baseline | opus |
| **visionary** | advisor | On-demand only | Outside-the-box features, user pain points, competitive gaps | opus |
| **conflict-reconciler** | implementer | Triggered by merge conflict | Conflict diagnosis, semantic merge, re-dispatch decisions | opus |

### Detailed example: `cicd.md`

(One full-shape example to illustrate; other 11 follow the common template with role-appropriate content.)

```yaml
---
name: cicd
description: Use during brainstorm when deployment/release automation is in scope; use as implementer for tasks authoring pipeline configs; use as reviewer for any proposed pipeline change.
tools: [Read, Edit, Write, Grep, Glob, Bash]
model: sonnet
---

# CI/CD Agent

## Purpose
Author and review CI/CD pipeline configurations. Platform-agnostic — detects target from repo state and adapts to GitHub Actions, GitLab CI, Jenkins, CircleCI, Bitbucket Pipelines, Drone, Forgejo Actions, Buildkite, Tekton, or others.

## Modes
- advisor: at brainstorm, surface pipeline implications
- implementer: author the pipeline config files
- reviewer: catch anti-patterns; identify perf improvements

## Scope
- IN: pipeline configs, build/test/deploy automation, secret-handling in CI, cache strategies, matrix/parallelism, deployment strategies, rollback, env promotion, artifact storage, pipeline performance
- OUT: deployed application logic (backend), IaC (cloud), service monitoring (sre), test design (qa)

## Platform detection (implementer mode)
1. .github/workflows/         → GitHub Actions
2. .gitlab-ci.yml             → GitLab CI
3. Jenkinsfile                → Jenkins
4. bitbucket-pipelines.yml    → Bitbucket Pipelines
5. .circleci/config.yml       → CircleCI
6. .drone.yml                 → Drone
7. .woodpecker.yml            → Woodpecker
8. .forgejo/workflows/        → Forgejo Actions
9. Multiple → ask orchestrator which is canonical
10. None → ask orchestrator which platform to target

## Coordination inputs
- security: required scans (SAST, dep audit, secret scan), gates
- cloud: deploy target, credentials approach (OIDC preferred), IAM
- sre: deployment hooks for alerting; verification window
- qa: test suites to run, parallelism budget

## Quality checklist
- [ ] Caching configured (build artifacts, dependencies)
- [ ] Secrets via platform secrets vault, never inline
- [ ] OIDC over long-lived credentials where supported
- [ ] Deploy job has documented rollback path
- [ ] Tests run before deploy; deploy gated on green
- [ ] Failure notifications wired to sre's spec
- [ ] Pinned action/image versions (no floating tags)
- [ ] Local-invocation documented in repo README if applicable

## Performance checklist
- [ ] Cache hit rate observed and acceptable (cache keys stable
      when inputs stable)
- [ ] Independent jobs run in parallel — no unnecessary `needs:` chains
- [ ] Test suites sharded across runners when wall-time > ~3min
- [ ] Step ordering optimized — fail-fast: lint → typecheck → unit
      → integration → deploy
- [ ] Path filters / changeset-aware execution skip unchanged jobs
- [ ] Lightweight base images (alpine, slim, distroless)
- [ ] Frozen-lockfile dependency installs (npm ci, pnpm install
      --frozen-lockfile, etc.)
- [ ] Incremental build tools where applicable (Bazel, Turborepo, Nx,
      Gradle build cache, Vite, Moon)
- [ ] Artifact reuse across jobs — build once, deploy/publish/test many
- [ ] Runner architecture matches workload (ARM where cheaper)
- [ ] Concurrency control configured (cancel-in-progress on superseded
      branch pushes)

## Regression gates
- [ ] Performance benchmark step in pipeline (when performance role
      participated in plan)
- [ ] Test pass-rate gate (no flake-tolerance creep)
- [ ] Bundle size delta check (frontend projects)
- [ ] Lighthouse / a11y check (frontend projects)
- [ ] Deployment gated on benchmark pass — no deploy on regression
      unless explicitly approved

## Performance review behavior (reviewer mode)
When reviewing existing pipelines:
1. Pull recent run duration data via platform CLI/API (`gh run`,
   `glab ci`, `circleci api`, etc.) for the last ~20 runs
2. Identify top 3 time sinks: slowest steps, jobs with high queue+exec
   time, jobs with high duration variance (>30%)
3. Propose specific changes with estimated savings, ranked by
   `time_saved / implementation_effort`
4. Flag jobs with cache hit rates <60% (unstable cache key)
5. Surface as a prioritized list, not a wall of suggestions

## Escalation
- BLOCKED if: deployment target unclear, secrets management approach
  not approved by security, multiple CI platforms detected without
  canonical choice
```

### Tool allowlists

| Category | Roles | Tools allowed |
|---|---|---|
| Implementers | frontend, backend, cloud, cicd, sre, qa | `Read, Edit, Write, Grep, Glob, Bash, TaskCreate, TaskUpdate` |
| Advisors / reviewers | ux-designer, security, network, performance, visionary | `Read, Grep, Glob, Bash` (no Write/Edit) |
| Conflict-reconciler | conflict-reconciler | `Read, Edit, Write, Grep, Glob, Bash, Agent` (can dispatch other agents) |

Advisor agents literally cannot edit code — defense in depth.

---

## New skills (5)

### 5.1 `engineering-orchestrator` (the spine)

**Purpose:** Defines the full lifecycle. Sequences and parameterizes the vendored skills; calls the other four new skills at the right points.

**When invoked:** By the `/engineer` slash command, or directly when a user asks "let's plan and build X" with role-aware engineering implied.

**Composes with:**
- Calls `ensemble-planning` for role selection + role-flavored brainstorm/plan
- Calls vendored `brainstorming` (with ensemble-planning's contributions injected)
- Calls vendored `writing-plans` (tasks tagged with owning roles)
- Calls vendored `subagent-driven-development` BUT substitutes role-flavored implementers for the generic implementer
- Calls `ensemble-review` after each task's vendored reviews complete
- Calls `visionary-pass` at user request after major milestones

**Key invariant:** Thin. Doesn't reimplement brainstorm/plan/execute logic — it just sequences and parameterizes the vendored skills.

### 5.2 `ensemble-planning`

**Purpose:** Two jobs — (1) role selection: scan the problem statement and pick 2-5 relevant roles; (2) role-flavored contributions: invoke each selected role in advisor mode during brainstorm and writing-plans.

**When invoked:** By `engineering-orchestrator` at brainstorm-start and again at plan-start.

**Inputs:** Problem statement (brainstorm phase) or spec (plan phase); list of available role agents.

**Outputs:**
- Brainstorm phase: `selected_roles`, `role_concerns: [{ role, concerns, must_have_acceptance_criteria }]`
- Plan phase: `task_role_tags: { task_id: [owning_roles] }`, `extra_tasks` (from role advisors)

**Role selection rules of thumb:**

- **backend** — always selected if any code is involved
- **frontend** — UI / CLI / UX surface
- **cloud** — deployment target named
- **security** — auth, data, secrets, dependencies, IaC, regulated content
- **cicd** — deployment in scope, OR security/cloud/sre selected (CI/CD coordination is almost always needed)
- **sre** — production-running service
- **network** — topology / firewall / ACL / VPC mentioned
- **ux-designer** — user-facing UI
- **qa** — non-trivial multi-component work
- **performance** — diff touches executable code / queries / infra / deps / build configs (selected at task level, not project level — checked per task)
- **visionary** — never auto-selected; explicit user invocation only
- **conflict-reconciler** — never auto-selected at planning time; activated by merge-conflict events only

### 5.3 `ensemble-review`

**Purpose:** After each task's vendored spec-compliance and code-quality reviews pass, fire role-flavored reviewers for whichever roles owned the task. Also coordinates the regression review pass when the diff warrants it.

**When invoked:** By `engineering-orchestrator` after `subagent-driven-development`'s reviews approve a task.

**Inputs:**
- Task text + role tags (from `ensemble-planning`)
- Diff SHAs for the task
- Prior review outputs (so role reviewers don't duplicate)

**Outputs:**
- Per-role findings (severity, file, line, issue, fix)
- Aggregate `status: APPROVED | NEEDS_CHANGES | BLOCKED`
- Regression review findings (if regression review ran)

**Regression review trigger:** runs after role reviews when the diff touches executable code, queries, infra, deps, or build configs. Skipped on docs-only / comment-only / config-only changes.

**Failure modes:**
- Role reviewer returns NEEDS_CHANGES → implementer fixes; reviewer re-checks
- Two role reviewers conflict (e.g., security wants X, cloud says X is cost-prohibitive) → escalate to human; surface both findings; do not auto-resolve domain trade-offs

### 5.4 `visionary-pass`

**Purpose:** Run the visionary agent against current project state. Returns proposals for new directions/features.

**When invoked:** *Never automatically.* Only on explicit user request via `/engineer visionary` or `/visionary`.

**Inputs:** Project root path; recent git log / commit summaries; current spec(s) / open plans; (optional) user-known pain points.

**Outputs:** 3-7 proposals, each with rationale, user value, fit with existing architecture, rough scope estimate, risk. Each proposal is a "starter spec" — short enough to feed back into `/engineer` to pursue.

### 5.5 `merge-conflict-reconciler`

**Purpose:** When two worktrees produce conflicting changes at merge-back time, diagnose the conflict, identify the originating tasks in each branch, and either auto-resolve or re-dispatch the relevant implementers with cross-context awareness.

**When invoked:**
- Automatically by `engineering-orchestrator` at the merge step if conflicts are detected
- Manually by `/reconcile <worktree-path>`

**Inputs:** Two branch refs (or worktree paths); conflict markers; plan files from both branches; recent task completion records.

**Reconciliation strategy (in order):**

1. **Cosmetic conflicts** (whitespace, import ordering): auto-resolve via `git checkout --theirs`/`--ours` heuristics, with explanation in commit.
2. **Same-intent conflicts** (both branches added the same dependency, same constant): pick one, document.
3. **Semantic conflicts** (both branches modified the same logic with different intent): dispatch `conflict-reconciler` agent with both branches' tasks + diffs as context. Agent proposes a unified resolution OR returns `BLOCKED`.
4. **Architectural conflicts** (specs are mutually incompatible): escalate; suggest a re-brainstorm of the overlapping scope.

**Hard limit:** Reconciler will not auto-resolve more than 5 conflicting hunks. Beyond that, escalates — large conflict surface usually signals planning failure.

---

## Slash commands (3)

### 6.1 `/engineer` (primary)

**File:** `commands/engineer.md`

```
/engineer "<problem statement>"        # full lifecycle
/engineer plan "<problem statement>"   # produce plan only, defer execution
/engineer review                       # ensemble-review current branch's recent work
/engineer roles                        # list configured role agents
/engineer visionary                    # invoke visionary-pass
/engineer reconcile [worktree-path]    # delegate to merge-conflict-reconciler
/engineer --help                       # show usage
```

**Routing logic:**
1. Parse `$ARGUMENTS` first token; if subcommand keyword → dispatch; else treat all of `$ARGUMENTS` as the problem statement
2. For full lifecycle: verify worktree set up; invoke `engineering-orchestrator` skill
3. For "plan": invoke `engineering-orchestrator` with `mode=plan-only`
4. For "review": invoke `ensemble-review` against current branch's recent diff
5. For "roles": list `agents/` directory contents
6. For "visionary": invoke `visionary-pass`
7. For "reconcile": invoke `merge-conflict-reconciler`

### 6.2 `/visionary` (shortcut)

```
/visionary
/visionary --scope=<area>
/visionary --help
```

Top-level for discoverability; delegates to the same `visionary-pass` skill as `/engineer visionary`.

### 6.3 `/reconcile` (merge-conflict-only)

```
/reconcile
/reconcile <worktree-path>
/reconcile --dry-run
/reconcile --help
```

Top-level because it's invoked in a different context than `/engineer` — often reactively after a failed merge, possibly when no `/engineer` session is active.

### Argument conventions

| Convention | Meaning |
|---|---|
| `--help` | Print usage; do nothing else |
| `--dry-run` | Diagnose only; don't write or commit |
| `--no-<feature>` | Disable a default behavior |
| `--worktree=<path>` | Explicit worktree path (otherwise inferred) |
| `--scope=<area>` | Narrow to a subarea |
| `<positional>` | Problem statement, worktree path, etc. |

### Help discovery

Each command file ends with a `--help` block (via the existing `add-help` skill in this dotfiles install) covering: one-line purpose, usage shapes, options, 2-3 example invocations, pointers to relevant skills.

### Deliberate omissions (YAGNI)

- `/engineer status` — TaskList already shows session state
- `/engineer abort` — Esc already interrupts
- `/engineer-stack-config` — config goes in plugin.json, not a command
- Per-role commands (`/security-review`, etc.) — surface bloat; roles are dispatched by orchestrator

---

## Worktree integration & multi-session safety

### Lifecycle

```
1. /engineer "<problem>"
        │
        ▼
2. Orchestrator checks: are we already in a worktree?
   - yes: proceed in current worktree
   - no: invoke vendored using-git-worktrees to create one
        │
        ▼
3. Worktree at:   <repo-root>/.worktrees/engineer-<slug>/
   Branch:        engineer/<slug>
        │
        ▼
4. Lifecycle in worktree (spec + plan + tasks + commits)
        │
        ▼
5. Completion via finishing-a-development-branch:
   - Merge to main: detect conflicts; if any, invoke
     merge-conflict-reconciler before completing
   - On success: offer to prune worktree
        │
        ▼
6. Cleanup (user choice): prune or keep
```

### Naming convention

| Element | Pattern | Example |
|---|---|---|
| Worktree dir | `<repo-root>/.worktrees/engineer-<slug>/` | `~/proj/.worktrees/engineer-add-login/` |
| Branch | `engineer/<slug>` | `engineer/add-login` |
| Spec file | `docs/superpowers/specs/YYYY-MM-DD-<slug>-design.md` | `2026-05-05-add-login-design.md` |
| Plan file | `docs/superpowers/plans/YYYY-MM-DD-<slug>.md` | `2026-05-05-add-login.md` |

**Slug derivation:** orchestrator generates from problem statement (lowercase, hyphenated, ≤30 chars). On collision, append `-<8-char-timestamp>`.

**`.gitignore` addition:** `.worktrees/` added on first `/engineer` use (with consent).

### State coordination between sessions

Each worktree carries its own:
- Spec (`docs/superpowers/specs/<slug>-design.md`)
- Plan (`docs/superpowers/plans/<slug>.md`)
- TaskList (in-memory, surfaced via `TaskList` tool)

When `merge-conflict-reconciler` runs, it reads specs/plans from each conflicting branch, giving it intent-aware reconciliation — it knows what each branch was trying to do, not just what bytes overlapped.

### Edge cases

| Situation | Behavior |
|---|---|
| Uncommitted changes when `/engineer` invoked | Stash, notify, restore on session end |
| Slug collision | Append `-<8-char-timestamp>` |
| Worktree dir manually deleted | `git worktree prune` on next invocation |
| Worktree corrupted | `git worktree repair` documented in error handling |
| Two sessions, non-overlapping changes | Git handles natively |
| Two sessions, overlapping changes | Reconciler activates at merge |

### v2 priorities (deferred but planned)

User has expressed interest in these for v2:

- **Pre-merge conflict detection** — alert when two active sessions are heading for collision. Requires session-manifest file each session updates with file-touch hints. Useful but real complexity.
- **Cross-session communication** — let one session ask another about its progress. Use cases thin; users can `git log` other branches in v1.

Not in v1; tracked for v2 design.

### Permanently out of scope

- File-level locks/mutual exclusion (deadlock-prone)
- Auto-rebase across sessions (too many failure modes)

---

## Failure modes & error handling

### Categorized failure modes

#### A. Role selection failures (`ensemble-planning`)

| Failure | Handling |
|---|---|
| Wrong roles selected | User overrides: `--roles=frontend,backend,security` |
| Too many roles (>5 default cap) | Skill asks user to confirm before proceeding |
| Role advisor returns BLOCKED at brainstorm | Surface concern; pause for user decision |
| Role agent file missing/corrupted | Skip with warning; continue with remaining roles |

#### B. Role review failures (`ensemble-review`)

| Failure | Handling |
|---|---|
| 3 review iterations on same task with no progress | Escalate to user |
| Two role reviewers in direct conflict | Escalate; surface both; do not auto-resolve |
| Reviewer returns confidence < 0.6 | Surface as "low confidence"; user decides |
| Reviewer returns BLOCKED | Stop the task; escalate immediately |

#### C. Reconciler failures (`merge-conflict-reconciler`)

| Failure | Handling |
|---|---|
| > 5 conflicting hunks | Hard cap; escalate as planning failure |
| Architectural conflict (specs incompatible) | Escalate; suggest re-brainstorm |
| Auto-resolution applied but tests fail | `git reset` resolution; escalate; preserve diagnostic in commit |
| Reconciler agent confidence < 0.7 | Don't auto-apply; surface for user review |

#### D. Implementer failures (vendored, inherited)

Inherited from `subagent-driven-development`'s 4 status codes:

| Status | Handling |
|---|---|
| DONE | Proceed to spec compliance review |
| DONE_WITH_CONCERNS | Read concerns; address if correctness/scope; otherwise proceed |
| NEEDS_CONTEXT | Provide missing context; re-dispatch |
| BLOCKED | Diagnose: more context, more capable model, decompose, or escalate plan |

#### E. Context overflow

Mitigated by fresh-subagent-per-task pattern (vendored). Orchestrator uses TaskList checkpoints and runtime auto-compression. Plan/spec docs read in chunks per dispatch.

#### F. API / infrastructure failures

| Failure | Handling |
|---|---|
| Rate limit (429) | Exponential backoff; surface to user after 3+ retries |
| Network failure | Retry; save state and surface if persistent |
| User refuses tool call | Honor refusal; ask alternative path |
| Unexpected tool error | Surface immediately with context; never silently retry destructive operations |

#### G. User-initiated interruption

| Action | Handling |
|---|---|
| Ctrl-C mid-execution | TaskList captures last-known state; resume via `/engineer` (no args) in worktree |
| "stop" / "pause" | Graceful pause; commit at logical point if reached; surface state |
| "abandon this session" | Confirm before destructive action; offer to keep worktree |

### Hard escalation triggers (always surface to human)

1. Two role reviewers in direct conflict on correctness or safety
2. Reconciler hits 5-hunk cap or detects architectural incompatibility
3. Same task fails review 3+ times with no progress
4. Any agent reports BLOCKED on a question requiring human judgment (compliance, regulated data, novel cryptography)
5. Tests pass but a security-tagged check (e.g., `npm audit`) returns critical findings the agent can't auto-resolve
6. Plan determined to be wrong (multiple BLOCKED tasks pointing at planning issues)

### Confidence aggregation

Per task: track each role reviewer's confidence; aggregate (lowest dominates); trend across recent tasks.

If trend declines over 3+ consecutive tasks:

> "Confidence has been trending lower across recent tasks. Consider running `/visionary` for a fresh perspective, or pause for human review of the plan."

Soft signal, not hard stop.

### Resume / checkpoint semantics

- All persistent state lives in: spec file, plan file, git history, TaskList
- Resume: cd into worktree, invoke `/engineer` (no args)
- Orchestrator detects existing spec + plan + partial task progress, offers continuation

### Permanently out of scope

- Self-healing across sessions (per-session error handling only)
- Predictive failure detection (we react, not predict)
- Automatic rollback on review failure (fix-forward only; revert is user-explicit)

---

## Regression detection (cross-cutting)

### How baselines work

Baselines for performance and quality metrics live at `.engineering-stack/baselines.json` (per-repo, versioned).

**Baseline sources (in priority order):**
1. Stored baseline file (versioned, explicit)
2. Observability platform (Grafana / Datadog / CloudWatch / Honeycomb) — current production
3. On-the-fly: `git checkout previous-good-sha`, measure, restore

**Baseline updates:** never silent. Always require explicit user action:
- User approves regression with reason ("intentionally slower; documented")
- User runs `/engineer baseline refresh` after confirmed improvement
- New metric added (initial baseline = first measurement)

### Regression review flow

```
After per-task spec + quality + role reviews pass:
        │
        ▼
Orchestrator inspects diff:
   - Docs-only / comment-only / config-only? → SKIP
   - Touches executable code, queries, infra, deps, build configs? → RUN
        │
        ▼ (if RUN)
Dispatch regression reviewers in parallel:
   - performance.reviewer (always when RUN)
   - qa.reviewer (regression dimension)
   - sre.reviewer (only if change is deploy-touching)
        │
        ▼
Aggregate findings:
   - REGRESSION: above thresholds → surface as findings
   - WARNING: bad direction but within budget → surface as note
   - OK: proceed
        │
        ▼
User decision (advisory, not blocking):
   - Accept with reason → record in commit, update baseline
   - Fix forward → re-dispatch implementer with regression context
   - Revert → discard task, re-plan
```

**Why advisory not blocking:** sometimes a regression is acceptable (latency traded for correctness). Hard-blocking trains people to disable the check.

### Post-deploy verification (sre dimension)

For tasks resulting in a deploy:
- `sre` defines verification window (e.g., "watch SLOs for 30 min after deploy")
- `cicd` wires critical alarms to abort/rollback automation
- Error-budget burn-rate monitored; spike during window → page
- Synthetic checks run post-deploy
- Rollback verified manually-runnable; runbook in repo

The plugin sets up integration; the deployed observability stack does the watching at runtime.

---

## Testing & validation

### Three-layer model

```
┌─────────────────────────────────────────────────────────┐
│ Layer 3: Dogfooding (high signal, high cost)            │
│   Use plugin on real personal/work projects             │
│   Every failure → fix or documented limit               │
└─────────────────────────────────────────────────────────┘
                          ▲
┌─────────────────────────────────────────────────────────┐
│ Layer 2: Scenario evals (release-gating)                │
│   3-5 canonical projects across problem types           │
│   Run /engineer; capture output; compare to checklist   │
└─────────────────────────────────────────────────────────┘
                          ▲
┌─────────────────────────────────────────────────────────┐
│ Layer 1: Lint (cheap, mechanical, pre-commit)           │
│   Frontmatter, refs resolve, schema OK                  │
└─────────────────────────────────────────────────────────┘
```

### Layer 1 — Lint (`bin/lint-plugin`)

Verifies:
- Frontmatter parse on every `.md` in `skills/` and `agents/`
- Cross-references between skills resolve
- Tool allowlist names are valid
- Slash command schema correctness
- No dangling links after a skill swap-out

Run before commits. <1s execution. No CI configs in v1.

### Layer 2 — Scenario evals

| Scenario | Tests |
|---|---|
| Tiny CLI tool | Minimal role selection (backend, qa); orchestrator basic correctness |
| Web app with deployment | Full ensemble (frontend, backend, ux, cloud, security, cicd, qa); multi-domain plan |
| IaC-only change | No code, just IaC; cloud + security + network coordination; non-code-domain handling |
| Bug fix on known-buggy sample | Small surface; orchestrator doesn't over-engineer trivial work |
| Two parallel sessions w/ deliberate overlap | merge-conflict-reconciler correctness |

Each: pre-defined input prompt + expectation checklist. Run before tagged releases. Use `skill-creator`'s eval infrastructure where applicable. Combine automated assertion of key claims with manual review of outputs.

### Layer 3 — Dogfooding

Use the plugin for real `/engineer` invocations on personal projects. Capture failures as `tests/scenarios/regressions/`. Fix underlying skill/agent. Re-run scenario eval to confirm.

### CI configs

Not in v1. When the first external contributor arrives or first public release is tagged, add thin GitHub Actions / GitLab CI configs that just call `bin/lint-plugin`. The script is portable; the YAML wrappers are forge-specific.

### Explicit non-goals

- 100% deterministic regression tests (LLM outputs vary; structure + key claims only)
- Coverage metrics (skill files aren't code)
- Load testing (per-session orchestration; concurrency is git-handled)

---

## Portability

### Three tiers

```
┌────────────────────────────────────────────────────────────────┐
│ Tier 1: Claude Code (full fidelity) — reference implementation │
└────────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────────┐
│ Tier 2: MCP-mediated (Cursor, Cline, Continue, Goose, others)  │
│   MCP server exposes role agents + key skills                  │
│   Host AI orchestrates; loses subagent isolation               │
└────────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────────┐
│ Tier 3: AGENTS.md (any markdown-aware AI tool)                 │
│   Workflow as documented instructions; manual following        │
└────────────────────────────────────────────────────────────────┘
```

### Per-tool support

| Tool | Tier | Notes |
|---|---|---|
| Claude Code | 1 | Reference impl |
| Cursor IDE | 2 | MCP for roles; `.cursor/rules/` for discipline |
| Cline (VSCode) | 2 | Modes map to roles; MCP for skills |
| Roo Code (VSCode) | 2 | Same as Cline |
| Continue.dev | 2 | MCP + rules |
| Goose | 2 | Extensions + recipes |
| Codex | 3 | AGENTS.md only |
| Aider | 3 | System prompt; markdown only |
| Windsurf | 2 (limited) | MCP support evolving |
| Anything markdown-aware | 3 | If reads files, AGENTS.md works |

### v1 ships Tier 1 only

MCP server (Tier 2) and AGENTS.md generator (Tier 3) are deferred — they're additional runtime artifacts and codegen scripts respectively, not blocking for v1.

### Stopgap for v1 Cursor users

1. Clone engineering-stack repo somewhere accessible
2. In Cursor: `.cursor/rules/engineering-stack.mdc` pointing at `<path>/skills/engineering-orchestrator/SKILL.md` and `<path>/agents/<role>.md`
3. Cursor's AI follows manually; orchestration not automated

Documented in v1 README.

### Capability matrix

| Capability | Tier 1 | Tier 2 | Tier 3 |
|---|---|---|---|
| Brainstorm → spec | Native | MCP tool | Manual |
| Spec → plan | Native | MCP tool | Manual |
| Subagent isolation per task | ✅ | ❌ | ❌ |
| Two-stage spec/quality review | Auto | Manual via MCP | Manual |
| Role-flavored implementer dispatch | ✅ | ❌ | ❌ |
| Role review at task time | Auto | Manual via MCP | Manual |
| Worktree-per-session | ✅ | User sets up | User sets up |
| Merge-conflict-reconciler | ✅ | MCP tool | Manual |
| Visionary on demand | ✅ | MCP tool | Manual |

### v2 plan

**Tier 2 — `engineering-stack-mcp`:**

```
Tools:
  engineering_stack__brainstorm(problem)            → spec draft
  engineering_stack__plan(spec)                     → plan draft
  engineering_stack__role_advise(role, problem)     → role concerns
  engineering_stack__role_review(role, diff, ctx)   → role findings
  engineering_stack__visionary(project_path)        → proposals
  engineering_stack__reconcile(branch_a, branch_b)  → resolution
Resources:
  engineering-stack://roles
  engineering-stack://skills
Prompts:
  engineering-stack/engineer
```

**Tier 3 — `bin/export-agents-md`:**
- Emits `AGENTS.md` at repo root: workflow discipline
- Emits `AGENTS-roles.md`: role agent personas as instructional guidance
- Idempotent; re-run after plugin updates

### Versioning

`version:` field in plugin manifest and at top of generated AGENTS.md. Helps users see what they're running.

| Version | Tier 1 | Tier 2 | Tier 3 |
|---|---|---|---|
| v0.1 | Full | — | Stopgap (manual rule pointing) |
| v0.2 | Full | MCP server | Stopgap |
| v0.3 | Full | MCP server | AGENTS.md export script |
| v1.0 | Full | MCP (mature) | AGENTS.md (mature); v2 priorities (pre-merge detection, cross-session comm) start design |

---

## Roadmap

| Version | Scope |
|---|---|
| **v0.1** | Tier 1 plugin shipped: vendored superpowers, all 12 role agents, 5 new skills, 3 commands, `bin/lint-plugin`. README + stopgap instructions for Cursor users. |
| **v0.2** | MCP server (`engineering-stack-mcp`) for Cursor / Cline / Continue / Goose / others. Add scenario evals (Layer 2 testing). |
| **v0.3** | AGENTS.md export script (Tier 3). Add `.github/workflows/ci.yml` and `.gitlab-ci.yml` thin wrappers around `bin/lint-plugin` if external contributors / public release. |
| **v1.0** | Tier 2 + Tier 3 mature. Begin design of v2 priorities: pre-merge conflict detection, cross-session communication. |

---

## Appendix A: file structure

```
engineering-stack/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── engineering-orchestrator/
│   │   └── SKILL.md
│   ├── ensemble-planning/
│   │   └── SKILL.md
│   ├── ensemble-review/
│   │   └── SKILL.md
│   ├── visionary-pass/
│   │   └── SKILL.md
│   ├── merge-conflict-reconciler/
│   │   └── SKILL.md
│   └── superpowers-vendored/
│       ├── brainstorming/
│       ├── writing-plans/
│       ├── subagent-driven-development/
│       ├── executing-plans/
│       ├── dispatching-parallel-agents/
│       ├── test-driven-development/
│       ├── using-git-worktrees/
│       ├── verification-before-completion/
│       ├── requesting-code-review/
│       ├── receiving-code-review/
│       ├── finishing-a-development-branch/
│       ├── systematic-debugging/
│       ├── writing-skills/
│       └── using-superpowers/
├── agents/
│   ├── frontend.md
│   ├── backend.md
│   ├── ux-designer.md
│   ├── security.md
│   ├── cloud.md
│   ├── cicd.md
│   ├── sre.md
│   ├── network.md
│   ├── qa.md
│   ├── performance.md
│   ├── visionary.md
│   └── conflict-reconciler.md
├── commands/
│   ├── engineer.md
│   ├── visionary.md
│   └── reconcile.md
├── bin/
│   └── lint-plugin
├── README.md
└── LICENSE
```

---

## Appendix B: vendored skills swap-out path

Over time, individual vendored skills can be replaced by engineering-stack-authored versions. The procedure:

1. Author replacement at `skills/<skill-name>/SKILL.md` (outside `superpowers-vendored/`)
2. Delete the vendored copy at `skills/superpowers-vendored/<skill-name>/`
3. `grep -r "superpowers-vendored/<skill-name>"` to find dangling references; update them
4. Run `bin/lint-plugin` to confirm no broken refs
5. Commit

After enough swaps, `superpowers-vendored/` may shrink to a small residue, or be empty. At that point, optionally rename the directory or remove it entirely.

The naming convention `superpowers-vendored/` is intentional: it's a visible signal of "third-party content I can replace at will."

---

## Appendix C: open questions

These are not blockers for v1, but should be revisited as design encounters reality:

1. **Plugin name** — `engineering-stack` is a working title. Final name TBD before v0.1 tag. Considerations: short, memorable, doesn't conflict with existing Claude Code plugins.
2. **Role-selection cap default** — proposed 5; may need adjustment based on real-project experience (some projects might warrant 6-7).
3. **Performance baseline format** — `.engineering-stack/baselines.json` is straw-man; consider whether a more structured schema (YAML with metric type per entry) is needed.
4. **Visionary trigger frequency** — currently "on demand only." Monitor whether users actually invoke it; if not, consider a "post-milestone" prompt.
5. **MCP server runtime** — Node.js (mature MCP SDK) vs Python (more familiar). Choose at v0.2 design time.
6. **AGENTS.md format** — the convention is evolving (https://agents.md). Track upstream; align at v0.3.
7. **Post-deploy verification window default** — 30 min is straw-man; should it depend on traffic volume? Risk class? Defer until first deploy-heavy dogfooding.

---

## Appendix D: terminology

| Term | Definition |
|---|---|
| **Role agent** | A subagent file in `agents/<role>.md` representing a specialist (frontend, security, etc.) |
| **Mode** | A role agent's invocation context: advisor (consult), implementer (write code), reviewer (audit) |
| **Vendored skill** | A skill file copied from superpowers into `skills/superpowers-vendored/`; replaceable over time |
| **Ensemble** | The 2-5 selected role agents that participate in a given problem's lifecycle |
| **Spine** | The orchestration logic in `engineering-orchestrator` skill that sequences vendored + new skills |
| **Regression review** | The post-task pass run by performance + qa + sre to verify no degradation |
| **Reconciler** | The merge-conflict-reconciler skill + conflict-reconciler agent pair |
