# engineering-stack v0.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship v0.1 of the engineering-stack Claude Code plugin: vendor superpowers, add 12 role agents + 5 new skills + 3 slash commands + a lint script + README, produce a one-step `/plugin install`-able artifact.

**Architecture:** Plugin lives at `packages/claude-engineering-plugin/` in the dotfiles repo. Pure markdown + Bash; no runtime dependencies beyond Claude Code itself. TDD discipline is enforced via a Bash lint script (`bin/lint-plugin`) that serves as the test framework — tests are structural assertions about file presence, YAML frontmatter validity, and cross-reference integrity. Each task follows the pattern: extend lint → run (fails) → write artifact → run (passes) → commit.

**Tech Stack:** Bash (lint script), Markdown w/ YAML frontmatter (skills + agents + commands + manifest), JSON (plugin manifest), Git.

**Spec:** `/home/jeremy/workspace/dotfiles/docs/superpowers/specs/2026-05-05-engineering-stack-design.md`

---

## File Structure (target end state)

```
packages/claude-engineering-plugin/
├── .claude-plugin/
│   └── plugin.json                       # Manifest (Task 1)
├── bin/
│   └── lint-plugin                       # Bash test framework (Task 3)
├── skills/
│   ├── superpowers-vendored/             # Vendored 14 skills (Task 2)
│   │   ├── brainstorming/
│   │   ├── writing-plans/
│   │   ├── subagent-driven-development/
│   │   ├── executing-plans/
│   │   ├── dispatching-parallel-agents/
│   │   ├── test-driven-development/
│   │   ├── using-git-worktrees/
│   │   ├── verification-before-completion/
│   │   ├── requesting-code-review/
│   │   ├── receiving-code-review/
│   │   ├── finishing-a-development-branch/
│   │   ├── systematic-debugging/
│   │   ├── writing-skills/
│   │   └── using-superpowers/
│   ├── engineering-orchestrator/         # Task 16
│   │   └── SKILL.md
│   ├── ensemble-planning/                # Task 17
│   │   └── SKILL.md
│   ├── ensemble-review/                  # Task 18
│   │   └── SKILL.md
│   ├── visionary-pass/                   # Task 19
│   │   └── SKILL.md
│   └── merge-conflict-reconciler/        # Task 20
│       └── SKILL.md
├── agents/
│   ├── frontend.md                       # Task 4
│   ├── backend.md                        # Task 5
│   ├── ux-designer.md                    # Task 6
│   ├── security.md                       # Task 7
│   ├── cloud.md                          # Task 8
│   ├── cicd.md                           # Task 9
│   ├── sre.md                            # Task 10
│   ├── network.md                        # Task 11
│   ├── qa.md                             # Task 12
│   ├── performance.md                    # Task 13
│   ├── visionary.md                      # Task 14
│   └── conflict-reconciler.md            # Task 15
├── commands/
│   ├── engineer.md                       # Task 21
│   ├── visionary.md                      # Task 22
│   └── reconcile.md                      # Task 23
├── README.md                             # Task 24
└── LICENSE                               # Task 24
```

**Reference:** spec Appendix A for the canonical structure.

---

## Phase 0: Worktree setup

### Task 0: Create implementation worktree

Per the spec's worktree convention. The implementation work happens in an isolated branch.

**Files:** none yet — workspace setup only.

- [ ] **Step 1: Verify clean working tree**

  Run: `git -C /home/jeremy/workspace/dotfiles status`
  Expected: `nothing to commit, working tree clean` (or only the in-progress plan file)

- [ ] **Step 2: Create worktree**

  Run:
  ```bash
  cd /home/jeremy/workspace/dotfiles
  mkdir -p .worktrees
  git worktree add .worktrees/engineer-stack-v01 -b engineer/stack-v01 main
  ```
  Expected: `Preparing worktree (new branch 'engineer/stack-v01')`

- [ ] **Step 3: Add `.worktrees/` to repo `.gitignore`**

  Edit `/home/jeremy/workspace/dotfiles/.gitignore`. Append:
  ```
  # Worktrees (engineering-stack and similar)
  .worktrees/
  ```
  Run: `git -C /home/jeremy/workspace/dotfiles add .gitignore && git -C /home/jeremy/workspace/dotfiles commit -m "chore: ignore .worktrees/ directory"`

- [ ] **Step 4: Switch into the worktree for the rest of the plan**

  All subsequent steps assume CWD = `/home/jeremy/workspace/dotfiles/.worktrees/engineer-stack-v01`.

- [ ] **Step 5: Verify**

  Run: `git -C /home/jeremy/workspace/dotfiles/.worktrees/engineer-stack-v01 branch --show-current`
  Expected: `engineer/stack-v01`

---

## Phase 1: Foundation (Tasks 1-3)

### Task 1: Plugin scaffold + manifest

Create the plugin directory structure and the `plugin.json` manifest.

**Files:**
- Create: `packages/claude-engineering-plugin/.claude-plugin/plugin.json`
- Create: `packages/claude-engineering-plugin/skills/.gitkeep`
- Create: `packages/claude-engineering-plugin/agents/.gitkeep`
- Create: `packages/claude-engineering-plugin/commands/.gitkeep`
- Create: `packages/claude-engineering-plugin/bin/.gitkeep`

- [ ] **Step 1: Verify directory does not exist yet**

  Run: `ls packages/claude-engineering-plugin 2>/dev/null && echo EXISTS || echo MISSING`
  Expected: `MISSING`

- [ ] **Step 2: Create directory tree and manifest**

  ```bash
  mkdir -p packages/claude-engineering-plugin/{.claude-plugin,skills,agents,commands,bin}
  touch packages/claude-engineering-plugin/{skills,agents,commands,bin}/.gitkeep
  ```

  Then create `packages/claude-engineering-plugin/.claude-plugin/plugin.json`:

  ```json
  {
    "name": "engineering-stack",
    "version": "0.1.0",
    "description": "Role-aware engineering orchestrator for Claude Code",
    "author": "Jeremy Spofford",
    "credits": "Built on superpowers (Anthropic claude-plugins-official) — vendored and extended"
  }
  ```

- [ ] **Step 3: Verify manifest is valid JSON**

  Run: `python3 -c "import json; json.load(open('packages/claude-engineering-plugin/.claude-plugin/plugin.json'))"`
  Expected: no output (valid JSON)

- [ ] **Step 4: Verify directory structure**

  Run:
  ```bash
  find packages/claude-engineering-plugin -type d | sort
  ```
  Expected:
  ```
  packages/claude-engineering-plugin
  packages/claude-engineering-plugin/.claude-plugin
  packages/claude-engineering-plugin/agents
  packages/claude-engineering-plugin/bin
  packages/claude-engineering-plugin/commands
  packages/claude-engineering-plugin/skills
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add packages/claude-engineering-plugin
  git commit -m "feat(engineering-stack): scaffold plugin directory + manifest"
  ```

### Task 2: Vendor superpowers skills

Copy all 14 superpowers skills into `skills/superpowers-vendored/`. This is the foundation the new skills layer onto.

**Files:**
- Create: `packages/claude-engineering-plugin/skills/superpowers-vendored/` containing 14 skill subdirectories from the cached superpowers install

- [ ] **Step 1: Locate source**

  Run: `ls /home/jeremy/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.5/skills/`
  Expected: 14 directories (brainstorming, dispatching-parallel-agents, executing-plans, finishing-a-development-branch, receiving-code-review, requesting-code-review, subagent-driven-development, systematic-debugging, test-driven-development, using-git-worktrees, using-superpowers, verification-before-completion, writing-plans, writing-skills)

- [ ] **Step 2: Verify destination is empty**

  Run: `ls packages/claude-engineering-plugin/skills/superpowers-vendored 2>/dev/null && echo EXISTS || echo MISSING`
  Expected: `MISSING`

- [ ] **Step 3: Copy all skills**

  ```bash
  mkdir -p packages/claude-engineering-plugin/skills/superpowers-vendored
  command cp -r /home/jeremy/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.5/skills/* \
                packages/claude-engineering-plugin/skills/superpowers-vendored/
  ```

  Note: using `command cp` (bypasses the `cp -i` alias — see auto-memory `feedback_cp_alias.md`).

- [ ] **Step 4: Verify all 14 skills present + each has SKILL.md**

  ```bash
  count=$(ls packages/claude-engineering-plugin/skills/superpowers-vendored/ | wc -l)
  echo "Skills found: $count (expected 14)"
  for d in packages/claude-engineering-plugin/skills/superpowers-vendored/*/; do
    test -f "$d/SKILL.md" || echo "MISSING SKILL.md in $d"
  done
  ```
  Expected: `Skills found: 14`, no MISSING lines

- [ ] **Step 5: Commit**

  ```bash
  git add packages/claude-engineering-plugin/skills/superpowers-vendored
  git commit -m "feat(engineering-stack): vendor superpowers 5.0.5 skills

  Source: claude-plugins-official/superpowers/5.0.5
  Layered architecture: vendored skills are pristine; new behavior is added
  via skills/, agents/, commands/ on top. Vendored skills can be replaced
  individually over time per spec Appendix B."
  ```

### Task 3: Lint script (test framework)

Build the Bash lint script used as the TDD test framework for all subsequent tasks. The lint script itself is built TDD-first with shell-test cases.

**Files:**
- Create: `packages/claude-engineering-plugin/bin/lint-plugin`
- Create: `packages/claude-engineering-plugin/bin/test-lint` (test cases for the lint script itself)

- [ ] **Step 1: Write failing test cases for the lint script**

  Create `packages/claude-engineering-plugin/bin/test-lint`:

  ```bash
  #!/usr/bin/env bash
  # Self-test for bin/lint-plugin
  # Each test creates a fixture, runs lint-plugin against it, asserts result.
  set -euo pipefail

  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  LINT="$SCRIPT_DIR/lint-plugin"
  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT

  PASS=0
  FAIL=0

  assert_pass() {
    local desc="$1" dir="$2"
    if "$LINT" "$dir" >/dev/null 2>&1; then
      echo "  PASS: $desc"; PASS=$((PASS+1))
    else
      echo "  FAIL: $desc (expected pass, got fail)"; FAIL=$((FAIL+1))
    fi
  }

  assert_fail() {
    local desc="$1" dir="$2"
    if "$LINT" "$dir" >/dev/null 2>&1; then
      echo "  FAIL: $desc (expected fail, got pass)"; FAIL=$((FAIL+1))
    else
      echo "  PASS: $desc"; PASS=$((PASS+1))
    fi
  }

  # Fixture: minimal valid plugin (manifest only)
  mkdir -p "$TMPDIR/min/.claude-plugin"
  cat >"$TMPDIR/min/.claude-plugin/plugin.json" <<EOF
  {"name":"x","version":"0.1.0","description":"x","author":"x"}
  EOF
  assert_pass "minimal plugin (manifest only)" "$TMPDIR/min"

  # Fixture: missing manifest
  mkdir -p "$TMPDIR/no-manifest"
  assert_fail "plugin without manifest" "$TMPDIR/no-manifest"

  # Fixture: invalid JSON manifest
  mkdir -p "$TMPDIR/bad-json/.claude-plugin"
  echo "not json" >"$TMPDIR/bad-json/.claude-plugin/plugin.json"
  assert_fail "invalid JSON manifest" "$TMPDIR/bad-json"

  # Fixture: skill with valid frontmatter
  mkdir -p "$TMPDIR/with-skill/.claude-plugin" "$TMPDIR/with-skill/skills/foo"
  cat >"$TMPDIR/with-skill/.claude-plugin/plugin.json" <<EOF
  {"name":"x","version":"0.1.0","description":"x","author":"x"}
  EOF
  cat >"$TMPDIR/with-skill/skills/foo/SKILL.md" <<EOF
  ---
  name: foo
  description: foo skill
  ---
  # Foo
  EOF
  assert_pass "skill with valid frontmatter" "$TMPDIR/with-skill"

  # Fixture: skill missing frontmatter name
  mkdir -p "$TMPDIR/skill-no-name/.claude-plugin" "$TMPDIR/skill-no-name/skills/foo"
  cat >"$TMPDIR/skill-no-name/.claude-plugin/plugin.json" <<EOF
  {"name":"x","version":"0.1.0","description":"x","author":"x"}
  EOF
  cat >"$TMPDIR/skill-no-name/skills/foo/SKILL.md" <<EOF
  ---
  description: skill missing name
  ---
  EOF
  assert_fail "skill missing frontmatter name" "$TMPDIR/skill-no-name"

  # Fixture: agent with valid frontmatter
  mkdir -p "$TMPDIR/with-agent/.claude-plugin" "$TMPDIR/with-agent/agents"
  cat >"$TMPDIR/with-agent/.claude-plugin/plugin.json" <<EOF
  {"name":"x","version":"0.1.0","description":"x","author":"x"}
  EOF
  cat >"$TMPDIR/with-agent/agents/bar.md" <<EOF
  ---
  name: bar
  description: bar agent
  tools: [Read, Grep]
  model: sonnet
  ---
  # Bar Agent
  EOF
  assert_pass "agent with valid frontmatter" "$TMPDIR/with-agent"

  # Fixture: agent with invalid model value
  mkdir -p "$TMPDIR/agent-bad-model/.claude-plugin" "$TMPDIR/agent-bad-model/agents"
  cat >"$TMPDIR/agent-bad-model/.claude-plugin/plugin.json" <<EOF
  {"name":"x","version":"0.1.0","description":"x","author":"x"}
  EOF
  cat >"$TMPDIR/agent-bad-model/agents/bar.md" <<EOF
  ---
  name: bar
  description: bar agent
  tools: [Read]
  model: invalid-model
  ---
  EOF
  assert_fail "agent with invalid model value" "$TMPDIR/agent-bad-model"

  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  test "$FAIL" -eq 0
  ```

  Make executable: `chmod +x packages/claude-engineering-plugin/bin/test-lint`

- [ ] **Step 2: Run the test, expect FAIL (lint-plugin doesn't exist yet)**

  Run: `packages/claude-engineering-plugin/bin/test-lint`
  Expected: error like `No such file or directory` for lint-plugin (the test runner can't find it)

- [ ] **Step 3: Implement `bin/lint-plugin`**

  Create `packages/claude-engineering-plugin/bin/lint-plugin`:

  ```bash
  #!/usr/bin/env bash
  # bin/lint-plugin
  # Structural lint for engineering-stack plugin.
  # Usage: bin/lint-plugin [PLUGIN_ROOT]
  # If PLUGIN_ROOT omitted, defaults to script's parent directory.
  set -euo pipefail

  PLUGIN_ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
  ERRORS=0

  err() {
    echo "ERROR: $*" >&2
    ERRORS=$((ERRORS + 1))
  }

  # ---------- Manifest ----------
  check_manifest() {
    local manifest="$PLUGIN_ROOT/.claude-plugin/plugin.json"
    if [ ! -f "$manifest" ]; then
      err "Missing $manifest"
      return
    fi
    if ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$manifest" 2>/dev/null; then
      err "Invalid JSON in $manifest"
      return
    fi
    for field in name version description author; do
      if ! python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if '$field' in d else 1)" "$manifest" 2>/dev/null; then
        err "Manifest missing required field: $field"
      fi
    done
  }

  # ---------- Frontmatter helpers ----------
  # Extracts the YAML frontmatter block (between leading ---/---) into stdout.
  extract_fm() {
    awk '/^---$/{c++; next} c==1 {print} c==2 {exit}' "$1"
  }

  # Get value of a top-level key from frontmatter content (very small parser).
  # Handles "key: value" and "key: [a, b]". Not a full YAML parser.
  fm_get() {
    local content="$1" key="$2"
    echo "$content" | sed -n "s/^$key:[[:space:]]*//p" | head -1
  }

  has_fm_key() {
    local content="$1" key="$2"
    echo "$content" | grep -q "^$key:"
  }

  # ---------- Skills ----------
  check_skills() {
    [ -d "$PLUGIN_ROOT/skills" ] || return
    for skill_dir in "$PLUGIN_ROOT"/skills/*/; do
      [ -d "$skill_dir" ] || continue
      # Skip vendored — they're upstream and out of our lint scope
      case "$skill_dir" in
        */superpowers-vendored/) continue ;;
      esac
      # Recurse into vendored
      if [ "$(basename "$skill_dir")" = "superpowers-vendored" ]; then
        for vskill in "$skill_dir"*/; do
          check_one_skill "$vskill"
        done
      else
        check_one_skill "$skill_dir"
      fi
    done
  }

  check_one_skill() {
    local skill_dir="$1"
    local skill_md="$skill_dir/SKILL.md"
    if [ ! -f "$skill_md" ]; then
      err "Skill directory missing SKILL.md: $skill_dir"
      return
    fi
    local fm
    fm=$(extract_fm "$skill_md")
    if [ -z "$fm" ]; then
      err "Skill has no frontmatter: $skill_md"
      return
    fi
    has_fm_key "$fm" "name" || err "Skill missing frontmatter 'name': $skill_md"
    has_fm_key "$fm" "description" || err "Skill missing frontmatter 'description': $skill_md"
  }

  # ---------- Agents ----------
  ALLOWED_MODELS="sonnet|opus|haiku"
  ALLOWED_TOOLS="Read|Edit|Write|Grep|Glob|Bash|TaskCreate|TaskUpdate|TaskList|TaskGet|TaskOutput|TaskStop|Agent|WebFetch|WebSearch|NotebookEdit|NotebookRead"

  check_agents() {
    [ -d "$PLUGIN_ROOT/agents" ] || return
    for agent_md in "$PLUGIN_ROOT"/agents/*.md; do
      [ -f "$agent_md" ] || continue
      check_one_agent "$agent_md"
    done
  }

  check_one_agent() {
    local agent_md="$1"
    local fm
    fm=$(extract_fm "$agent_md")
    if [ -z "$fm" ]; then
      err "Agent has no frontmatter: $agent_md"
      return
    fi
    has_fm_key "$fm" "name" || err "Agent missing 'name': $agent_md"
    has_fm_key "$fm" "description" || err "Agent missing 'description': $agent_md"
    has_fm_key "$fm" "tools" || err "Agent missing 'tools': $agent_md"
    has_fm_key "$fm" "model" || err "Agent missing 'model': $agent_md"

    local model
    model=$(fm_get "$fm" "model")
    if [ -n "$model" ] && ! echo "$model" | grep -qE "^($ALLOWED_MODELS)$"; then
      err "Agent has invalid model '$model' (allowed: $ALLOWED_MODELS): $agent_md"
    fi

    # Validate tools list (must be of form [Tool1, Tool2, ...])
    local tools
    tools=$(fm_get "$fm" "tools")
    if [ -n "$tools" ]; then
      # Strip brackets and whitespace, split on comma
      local cleaned="${tools#[}"; cleaned="${cleaned%]}"
      IFS=',' read -ra arr <<< "$cleaned"
      for t in "${arr[@]}"; do
        t="${t// /}"
        [ -z "$t" ] && continue
        if ! echo "$t" | grep -qE "^($ALLOWED_TOOLS)$"; then
          err "Agent has unknown tool '$t': $agent_md"
        fi
      done
    fi
  }

  # ---------- Commands ----------
  check_commands() {
    [ -d "$PLUGIN_ROOT/commands" ] || return
    for cmd_md in "$PLUGIN_ROOT"/commands/*.md; do
      [ -f "$cmd_md" ] || continue
      local fm
      fm=$(extract_fm "$cmd_md")
      [ -z "$fm" ] && { err "Command has no frontmatter: $cmd_md"; continue; }
      has_fm_key "$fm" "description" || err "Command missing 'description': $cmd_md"
    done
  }

  # ---------- Run ----------
  check_manifest
  check_skills
  check_agents
  check_commands

  if [ "$ERRORS" -eq 0 ]; then
    echo "lint-plugin: all checks passed"
    exit 0
  else
    echo "lint-plugin: $ERRORS error(s) found" >&2
    exit 1
  fi
  ```

  Make executable: `chmod +x packages/claude-engineering-plugin/bin/lint-plugin`

- [ ] **Step 4: Run the test, expect PASS**

  Run: `packages/claude-engineering-plugin/bin/test-lint`
  Expected: `Results: 7 passed, 0 failed` (exit 0)

- [ ] **Step 5: Run lint against the actual plugin (sanity)**

  Run: `packages/claude-engineering-plugin/bin/lint-plugin packages/claude-engineering-plugin`
  Expected: `lint-plugin: all checks passed`

- [ ] **Step 6: Commit**

  ```bash
  git add packages/claude-engineering-plugin/bin
  git commit -m "feat(engineering-stack): add bin/lint-plugin and self-test"
  ```

---

## Phase 2: Role agents (Tasks 4-15)

### Common pattern for every agent task

For each role agent, the TDD pattern is:

1. **Step 1:** Run `bin/lint-plugin` — passes (no agent file yet, lint just checks present files)
2. **Step 2:** Add a presence assertion (the agent file should exist) — temporarily adds a test, fails because file is missing
3. **Step 3:** Write the agent file at `agents/<name>.md` per the spec (Section 2's table + role-specific content)
4. **Step 4:** Run `bin/lint-plugin` — passes
5. **Step 5:** Commit

In practice, since `bin/lint-plugin` validates *every* file in `agents/` automatically, the test-presence assertion is implicit — once the file exists, lint validates it. So the simpler pattern below is used.

**Reference for content:** spec Section "Role agents (12)" — the per-agent table specifies modes, triggers, distinguishing concerns, and model. Each agent file follows the **Common template** shown there.

### Task 4: `agents/frontend.md`

**Files:** Create `packages/claude-engineering-plugin/agents/frontend.md`

- [ ] **Step 1: Run lint baseline**

  Run: `packages/claude-engineering-plugin/bin/lint-plugin packages/claude-engineering-plugin`
  Expected: `all checks passed`

- [ ] **Step 2: Write the agent file**

  Frontmatter (required by lint):
  ```yaml
  ---
  name: frontend
  description: Use as implementer for tasks touching UI/components/styling; use as reviewer for any frontend code change.
  tools: [Read, Edit, Write, Grep, Glob, Bash, TaskCreate, TaskUpdate]
  model: sonnet
  ---
  ```

  Body sections per the common template (see spec Section "Role agents (12)" → "Common template"):
  - `# Frontend Agent`
  - `## Purpose` — implement and review frontend code (UI components, styling, frontend tests)
  - `## Modes` — `implementer`, `reviewer`
  - `## Scope` — IN: UI/components, styling, a11y, responsive layout, frontend tests; OUT: backend logic, infra, deployment
  - `## Input contract` — task text, file paths, role tags from ensemble-planning
  - `## Output contract` — `changes_made[]` (implementer mode) or `findings[]` (reviewer mode); `status`; `confidence`
  - `## Quality checklist` — A11y baseline (semantic HTML, ARIA where needed, keyboard nav), responsive layout, component boundaries (single responsibility), frontend tests written, CSS/styling follows project convention, no console errors
  - `## Escalation` — BLOCKED if: design system intent unclear, accessibility requirements regulated and ambiguous

- [ ] **Step 3: Run lint**

  Run: `packages/claude-engineering-plugin/bin/lint-plugin packages/claude-engineering-plugin`
  Expected: `all checks passed`

- [ ] **Step 4: Commit**

  ```bash
  git add packages/claude-engineering-plugin/agents/frontend.md
  git commit -m "feat(engineering-stack): add frontend role agent"
  ```

### Task 5: `agents/backend.md`

Same TDD pattern as Task 4. Frontmatter:

```yaml
---
name: backend
description: Use as implementer for tasks touching API/server/data layer; use as reviewer for any backend code change.
tools: [Read, Edit, Write, Grep, Glob, Bash, TaskCreate, TaskUpdate]
model: sonnet
---
```

Body sections covering: API/server/data layer scope; idempotency, input validation, transactional boundaries, backend tests in checklist; OUT: UI, infra; escalation BLOCKED on regulated-data flows or novel auth protocols.

Commit: `feat(engineering-stack): add backend role agent`

### Task 6: `agents/ux-designer.md`

Frontmatter:

```yaml
---
name: ux-designer
description: Use during brainstorm phase when UI is in scope. Advisor only — does not implement.
tools: [Read, Grep, Glob, Bash]
model: opus
---
```

Body covering: advisor mode only; concerns about IA, user flows, friction points, naming clarity; output is `concerns[]` and `must_have_acceptance_criteria[]`; escalation BLOCKED on regulated UX (accessibility-mandated, financial disclosures with legal constraints).

Commit: `feat(engineering-stack): add ux-designer role agent`

### Task 7: `agents/security.md`

Reference spec's detailed example in Section "Role agents (12)" → "Detailed example: `security.md`" — that's the canonical content for this file.

Frontmatter:

```yaml
---
name: security
description: Use during brainstorm to surface security requirements; use during review on any task touching auth, user input, dependencies, secrets, or IaC.
tools: [Read, Grep, Bash, WebFetch]
model: opus
---
```

Body sections: advisor + reviewer modes; OWASP top 10, dep CVEs, auth flow, secret handling, IaC posture in checklist; OUT: cryptographic protocol design, zero-day research; BLOCKED on novel cryptographic primitive proposals or regulated-data flows without compliance context.

Commit: `feat(engineering-stack): add security role agent`

### Task 8: `agents/cloud.md`

Frontmatter:

```yaml
---
name: cloud
description: Use as implementer for tasks involving IaC, cloud resources, or deployment configuration; use as reviewer for cloud changes.
tools: [Read, Edit, Write, Grep, Glob, Bash, TaskCreate, TaskUpdate]
model: sonnet
---
```

Body covering: implementer + reviewer modes; Terraform structure, cost, blast radius, IAM least-privilege, region/AZ strategy; coordination with security on IAM, with cicd on deploy steps; BLOCKED on multi-region failover designs without regulatory input.

Commit: `feat(engineering-stack): add cloud role agent`

### Task 9: `agents/cicd.md`

Reference spec's full detailed example in Section "Role agents (12)" → "Detailed example: `cicd.md`" — that's the canonical content for this file. Includes the platform detection logic, the standard quality checklist, the **performance checklist** (cache hit rate, parallelism, sharding, etc.), the **regression gates**, and the **performance review behavior** (reviewer mode pulls run history, identifies top 3 time sinks, ranks by ROI).

Frontmatter:

```yaml
---
name: cicd
description: Use during brainstorm when deployment/release automation is in scope; use as implementer for tasks authoring pipeline configs; use as reviewer for any proposed pipeline change.
tools: [Read, Edit, Write, Grep, Glob, Bash]
model: sonnet
---
```

Commit: `feat(engineering-stack): add cicd role agent with platform-agnostic + perf concerns`

### Task 10: `agents/sre.md`

Frontmatter:

```yaml
---
name: sre
description: Use during brainstorm when production-running code is in scope; use as implementer for monitoring/alerting/runbook tasks; use as advisor for incident readiness.
tools: [Read, Edit, Write, Grep, Glob, Bash, TaskCreate, TaskUpdate]
model: sonnet
---
```

Body covering: implementer + advisor modes; monitoring, alerting, SLOs, runbooks, capacity, incident readiness, post-deploy verification; the `## Post-deploy verification` checklist additions per spec Section "Regression detection (cross-cutting)" → "Post-deploy verification (sre dimension)"; BLOCKED on regulated-uptime SLAs (financial systems, etc.) without compliance input.

Commit: `feat(engineering-stack): add sre role agent`

### Task 11: `agents/network.md`

Frontmatter:

```yaml
---
name: network
description: Use as advisor or reviewer on tasks involving routing, firewall, ACLs, VPC, or DNS.
tools: [Read, Grep, Glob, Bash]
model: opus
---
```

Body: advisor + reviewer modes (no implementer — routes through cloud/cicd for actual config changes); topology, segmentation, latency paths, ACL correctness; coordination with cloud + security; BLOCKED on encrypted-tunnel design (defer to specialized review).

Commit: `feat(engineering-stack): add network role agent`

### Task 12: `agents/qa.md`

Frontmatter:

```yaml
---
name: qa
description: Use as implementer for integration/E2E test design; use as reviewer for quality regression checks (test pass rate, a11y, error rates).
tools: [Read, Edit, Write, Grep, Glob, Bash, TaskCreate, TaskUpdate]
model: sonnet
---
```

Body covering: implementer + reviewer modes; integration test design, edge cases, E2E flows, regression risk; the **quality regression checks** from spec Section "Regression detection (cross-cutting)" → "qa — quality regression dimension" (test pass rate, exec time, a11y score, coverage ratchet); BLOCKED on flakiness >5% in baseline tests (planning failure).

Commit: `feat(engineering-stack): add qa role agent with regression dimension`

### Task 13: `agents/performance.md`

Reference spec Section "Role agents (12)" → "performance.md shape" — that's the canonical content. Covers advisor + reviewer modes; baseline sources (file → observability → on-the-fly); regression detection logic (REGRESSION / WARNING / OK); and quality checklist for budget definition.

Frontmatter:

```yaml
---
name: performance
description: Use during brainstorm to set performance targets; use as reviewer on any task that touches executable code, queries, infra, dependencies, or build configs.
tools: [Read, Grep, Glob, Bash]
model: opus
---
```

Commit: `feat(engineering-stack): add performance role agent with regression detection`

### Task 14: `agents/visionary.md`

Frontmatter:

```yaml
---
name: visionary
description: Use only on explicit user request via /visionary or /engineer visionary. Proposes new feature directions based on project state.
tools: [Read, Grep, Glob, Bash]
model: opus
---
```

Body covering: advisor mode only; outside-the-box features, user pain points, competitive gaps; output is 3-7 proposals with rationale, user value, fit, scope estimate, risk; never auto-invoked; output format is "starter spec" — feedable into `/engineer`.

Commit: `feat(engineering-stack): add visionary role agent`

### Task 15: `agents/conflict-reconciler.md`

Frontmatter:

```yaml
---
name: conflict-reconciler
description: Triggered by merge-conflict-reconciler skill at merge-back when overlapping changes from parallel sessions need semantic merge.
tools: [Read, Edit, Write, Grep, Glob, Bash, Agent]
model: opus
---
```

Body covering: implementer mode; conflict diagnosis; semantic merge proposals; re-dispatch decisions (can dispatch other role agents to fix); 5-hunk hard cap (escalate beyond); inputs include both branches' specs/plans for intent-aware reconciliation; BLOCKED on architectural incompatibility.

Commit: `feat(engineering-stack): add conflict-reconciler role agent`

---

## Phase 3: New skills (Tasks 16-20)

### Common pattern for skill tasks

Each skill is a SKILL.md file in its own subdirectory. Frontmatter requires `name` and `description`. Body explains the workflow, when invoked, how it composes with vendored skills, inputs/outputs, and key invariants.

**Reference for content:** spec Section "New skills (5)" — each subsection is the canonical content.

### Task 16: `skills/engineering-orchestrator/SKILL.md`

**Files:** Create `packages/claude-engineering-plugin/skills/engineering-orchestrator/SKILL.md`

- [ ] **Step 1: Run lint baseline** → expect `all checks passed`

- [ ] **Step 2: Write SKILL.md**

  Frontmatter:
  ```yaml
  ---
  name: engineering-orchestrator
  description: Use when /engineer slash command is invoked or user describes role-aware engineering work. Sequences brainstorm → plan → execute → review with role specialization.
  ---
  ```

  Body sections per spec Section "New skills (5)" → "5.1 engineering-orchestrator (the spine)":
  - `# Engineering Orchestrator`
  - `## Overview` — the spine; sequences vendored + new skills; thin (does not reimplement orchestration)
  - `## When to Use` — invoked by `/engineer`; user describes role-aware engineering
  - `## The Process` — full lifecycle from spec Section "Architecture" → "Lifecycle of a problem"
  - `## Composes with` — calls `ensemble-planning`, vendored `brainstorming`, vendored `writing-plans`, vendored `subagent-driven-development` (substituting role-flavored implementers), `ensemble-review`, optionally `visionary-pass`
  - `## Key invariants` — thin spine; never modifies vendored skill content; worktree-per-session enforced

- [ ] **Step 3: Run lint** → expect `all checks passed`

- [ ] **Step 4: Commit**
  ```bash
  git add packages/claude-engineering-plugin/skills/engineering-orchestrator
  git commit -m "feat(engineering-stack): add engineering-orchestrator skill (spine)"
  ```

### Task 17: `skills/ensemble-planning/SKILL.md`

Frontmatter:
```yaml
---
name: ensemble-planning
description: Use during brainstorm and writing-plans phases. Selects 2-5 relevant role agents per problem; invokes each role in advisor mode to contribute concerns and acceptance criteria.
---
```

Body per spec Section "New skills (5)" → "5.2 ensemble-planning". Includes: role selection rules of thumb (backend default if code; frontend if UI/CLI; cloud if deployment named; security if auth/data/secrets/deps; cicd if deployment OR security/cloud/sre selected; sre if production; network if topology; ux-designer if user-facing UI; qa for non-trivial multi-component work; performance per task at task level; visionary never auto; conflict-reconciler never auto), the role-budget cap (5 default), and outputs (`selected_roles`, `role_concerns`, `task_role_tags`).

Commit: `feat(engineering-stack): add ensemble-planning skill`

### Task 18: `skills/ensemble-review/SKILL.md`

Frontmatter:
```yaml
---
name: ensemble-review
description: Use after each task's vendored spec/quality reviews approve. Fires role-flavored reviewers for whichever roles owned the task, plus regression review when diff warrants.
---
```

Body per spec Section "New skills (5)" → "5.3 ensemble-review". Includes: regression review trigger logic (skip docs/comment/config-only changes; run when diff touches executable code/queries/infra/deps/build configs); role-conflict escalation policy (do not auto-resolve domain trade-offs); confidence threshold for surfacing low-certainty findings.

Commit: `feat(engineering-stack): add ensemble-review skill`

### Task 19: `skills/visionary-pass/SKILL.md`

Frontmatter:
```yaml
---
name: visionary-pass
description: Use only on explicit user request (via /visionary or /engineer visionary). Runs visionary agent to propose new project directions.
---
```

Body per spec Section "New skills (5)" → "5.4 visionary-pass". Includes: never auto-invoked; inputs (project root, recent git log, current specs/plans, optional pain points); outputs (3-7 proposals, each as a starter spec).

Commit: `feat(engineering-stack): add visionary-pass skill`

### Task 20: `skills/merge-conflict-reconciler/SKILL.md`

Frontmatter:
```yaml
---
name: merge-conflict-reconciler
description: Use when merge-back from a worktree surfaces conflicts. Diagnoses, identifies originating tasks in each branch, and either auto-resolves (cosmetic/same-intent) or dispatches conflict-reconciler agent for semantic merge.
---
```

Body per spec Section "New skills (5)" → "5.5 merge-conflict-reconciler". Includes: 4-tier resolution strategy (cosmetic / same-intent / semantic / architectural); 5-hunk hard cap; inputs (two branch refs, conflict markers, both branches' plan files, recent task records); intent-aware reconciliation by reading specs from each branch.

Commit: `feat(engineering-stack): add merge-conflict-reconciler skill`

---

## Phase 4: Slash commands (Tasks 21-23)

### Task 21: `commands/engineer.md`

**Files:** Create `packages/claude-engineering-plugin/commands/engineer.md`

- [ ] **Step 1: Run lint baseline** → `all checks passed`

- [ ] **Step 2: Write command file**

  Frontmatter:
  ```yaml
  ---
  description: Role-aware engineering orchestrator. Brainstorms, plans, executes, and reviews multi-step engineering work with specialized role agents.
  ---
  ```

  Body — routing logic per spec Section "Slash commands (3)" → "6.1 /engineer":

  ```markdown
  # /engineer

  Args: $ARGUMENTS

  ## Routing

  Parse first token of $ARGUMENTS:

  - `plan ...` → invoke `engineering-orchestrator` skill with mode=plan-only
    and the rest of $ARGUMENTS as the problem statement
  - `review` → invoke `ensemble-review` skill against current branch's recent
    diff (no problem statement needed)
  - `roles` → list contents of `agents/` directory (each agent's name and
    description from frontmatter)
  - `visionary` → invoke `visionary-pass` skill
  - `reconcile [path]` → invoke `merge-conflict-reconciler` skill with
    optional worktree path
  - `--help` or `help` → print usage block (see below)
  - Anything else → treat all of $ARGUMENTS as the problem statement;
    invoke `engineering-orchestrator` skill in full lifecycle mode

  Before invoking the orchestrator: verify a worktree is set up for the
  session. If not, invoke vendored `using-git-worktrees` skill first.

  ## Usage (printed for --help)

  /engineer "<problem statement>"        # full lifecycle
  /engineer plan "<problem statement>"   # produce plan only, defer execution
  /engineer review                       # ensemble-review current branch's recent work
  /engineer roles                        # list configured role agents
  /engineer visionary                    # invoke visionary-pass
  /engineer reconcile [worktree-path]    # delegate to merge-conflict-reconciler
  /engineer --help                       # show usage

  ## Examples

  /engineer "build a calculator app deployed to AWS"
  /engineer plan "add SAML SSO to the auth service"
  /engineer review
  /engineer reconcile .worktrees/engineer-add-billing
  ```

- [ ] **Step 3: Run lint** → `all checks passed`

- [ ] **Step 4: Commit**
  ```bash
  git add packages/claude-engineering-plugin/commands/engineer.md
  git commit -m "feat(engineering-stack): add /engineer slash command"
  ```

### Task 22: `commands/visionary.md`

Frontmatter:
```yaml
---
description: Propose new feature directions for the current project (shortcut for /engineer visionary).
---
```

Body — thin shell that delegates to `visionary-pass` skill. Args: `--scope=<area>` and `--help`. Per spec Section "Slash commands (3)" → "6.2 /visionary".

Commit: `feat(engineering-stack): add /visionary slash command`

### Task 23: `commands/reconcile.md`

Frontmatter:
```yaml
---
description: Resolve merge conflicts between worktrees using merge-conflict-reconciler skill.
---
```

Body — thin shell that delegates to `merge-conflict-reconciler` skill. Args: optional worktree path, `--dry-run`, `--help`. Per spec Section "Slash commands (3)" → "6.3 /reconcile".

Commit: `feat(engineering-stack): add /reconcile slash command`

---

## Phase 5: Integration (Tasks 24-26)

### Task 24: README + LICENSE

**Files:**
- Create: `packages/claude-engineering-plugin/README.md`
- Create: `packages/claude-engineering-plugin/LICENSE`

- [ ] **Step 1: Write README.md**

  Sections:
  - **Title + tagline:** "engineering-stack — role-aware engineering orchestrator for Claude Code"
  - **What it does:** brief paragraph: 12 specialized role agents, brainstorm → plan → execute → review lifecycle, multi-session worktree safety
  - **Install:** `/plugin install <git-url>` (placeholder; user fills in actual URL when publishing)
  - **Usage:** the three commands with one example each, pulled from spec Section "Slash commands (3)"
  - **Architecture:** the 4-layer diagram from spec Section "Architecture" → "Layered structure"
  - **Cursor / other AI tools (stopgap):** point at spec Section "Portability" → "Stopgap for v1 Cursor users"
  - **Credits:** "Built on superpowers (Anthropic claude-plugins-official, vendored)"
  - **License:** MIT (see LICENSE)
  - **Contributing:** PRs welcome; run `bin/lint-plugin` before commits
  - **Roadmap:** v0.2 MCP server, v0.3 AGENTS.md export, v1.0 maturity

- [ ] **Step 2: Write LICENSE**

  Standard MIT license; copyright "2026 Jeremy Spofford".

- [ ] **Step 3: Run lint** → `all checks passed` (lint doesn't validate README/LICENSE)

- [ ] **Step 4: Commit**
  ```bash
  git add packages/claude-engineering-plugin/README.md packages/claude-engineering-plugin/LICENSE
  git commit -m "docs(engineering-stack): add README and LICENSE"
  ```

### Task 25: Smoke test (manual install verification)

Verify the plugin installs into a Claude Code config directory and is discoverable.

**Files:** none — verification only.

- [ ] **Step 1: Run final lint check on full plugin**

  Run: `packages/claude-engineering-plugin/bin/lint-plugin packages/claude-engineering-plugin`
  Expected: `lint-plugin: all checks passed` (manifest, 14 vendored skills, 5 new skills, 12 agents, 3 commands all valid)

- [ ] **Step 2: Run self-test for lint script**

  Run: `packages/claude-engineering-plugin/bin/test-lint`
  Expected: `Results: 7 passed, 0 failed`

- [ ] **Step 3: Verify count of artifacts matches spec**

  Run:
  ```bash
  P=packages/claude-engineering-plugin
  echo "Vendored skills: $(ls $P/skills/superpowers-vendored | wc -l) (expected 14)"
  echo "New skills: $(ls -d $P/skills/*/ | grep -v superpowers-vendored | wc -l) (expected 5)"
  echo "Agents: $(ls $P/agents/*.md | wc -l) (expected 12)"
  echo "Commands: $(ls $P/commands/*.md | wc -l) (expected 3)"
  ```
  Expected: all four counts match

- [ ] **Step 4: Optional manual install test**

  In a separate terminal or scratch directory, install via Claude Code:
  ```bash
  # Replace <local-path> with the absolute path to packages/claude-engineering-plugin
  # NOTE: at v0.1, plugin must still be installed by adding to user-config; document
  #       once we know the canonical install command in the user's environment.
  ```
  This step is optional and informational — actual `/plugin install` from a remote git URL is a v0.2 concern. For v0.1, the plugin sits in dotfiles and is loaded as a local development plugin.

- [ ] **Step 5: No commit needed** (verification only)

### Task 26: Tag v0.1.0

Tag the release on the engineer/stack-v01 branch and prepare for merge to main.

**Files:** none.

- [ ] **Step 1: Verify branch state clean**

  Run: `git status`
  Expected: `nothing to commit, working tree clean`

- [ ] **Step 2: Create annotated tag**

  ```bash
  git tag -a v0.1.0 -m "engineering-stack v0.1.0

  Initial release. Tier 1 (Claude Code plugin) only.
  - 12 role agents: frontend, backend, ux-designer, security, cloud, cicd,
    sre, network, qa, performance, visionary, conflict-reconciler
  - 5 new skills: engineering-orchestrator, ensemble-planning, ensemble-review,
    visionary-pass, merge-conflict-reconciler
  - 3 slash commands: /engineer, /visionary, /reconcile
  - Vendored superpowers 5.0.5 skills as foundation (skills/superpowers-vendored/)
  - bin/lint-plugin structural lint with self-test

  Tier 2 (MCP server) and Tier 3 (AGENTS.md export) deferred to v0.2 / v0.3."
  ```

- [ ] **Step 3: Verify tag**

  Run: `git tag -l v0.1.0 && git show v0.1.0 --stat | head -20`
  Expected: tag exists; show output includes the tag message

- [ ] **Step 4: Merge guidance (informational, not executed by plan)**

  The implementer should surface to the user when complete:

  > "v0.1.0 tagged on engineer/stack-v01. Ready to merge to main when you approve. Run from worktree:
  > `git checkout main && git merge --no-ff engineer/stack-v01`
  > Then push tag: `git push --follow-tags`. Then optionally prune the worktree:
  > `git worktree remove .worktrees/engineer-stack-v01 && git branch -d engineer/stack-v01`."

- [ ] **Step 5: No commit needed** (tag is the artifact)

---

## Reference: relationship to spec

| Plan task | Spec section |
|---|---|
| Task 0 | "Worktree integration & multi-session safety" → "Lifecycle" |
| Task 1 (manifest) | "Architecture" → "Plugin manifest" |
| Task 2 (vendoring) | "Goals" A; Appendix B (swap-out path) |
| Task 3 (lint) | "Testing & validation" → "Layer 1 — Lint" |
| Tasks 4-15 (agents) | "Role agents (12)" — per-row content |
| Tasks 16-20 (skills) | "New skills (5)" — per-skill subsection |
| Tasks 21-23 (commands) | "Slash commands (3)" — per-command subsection |
| Task 24 (README) | "Portability" → "Stopgap for v1 Cursor users"; "Architecture" |
| Task 25 (smoke test) | "Testing & validation" → "Layer 1" + manual install verify |
| Task 26 (tag) | "Roadmap" → v0.1 |

---

## Out of scope for this plan (v0.1 only)

Per the spec's roadmap, these are explicitly **not** in v0.1 and not in this plan:

- MCP server (`engineering-stack-mcp`) — v0.2
- AGENTS.md export script (`bin/export-agents-md`) — v0.3
- GitHub Actions / GitLab CI configs — added when first contributor or public release warrants
- Layer 2 scenario evals — added in v0.2 alongside MCP server
- Pre-merge conflict detection, cross-session communication — v2 priorities, design begins at v1.0
- Real-world dogfooding-driven adjustments — happen continuously after v0.1

---

## Verification at end of plan

After Task 26, the following must be true:

- [ ] `packages/claude-engineering-plugin/bin/lint-plugin packages/claude-engineering-plugin` exits 0
- [ ] `packages/claude-engineering-plugin/bin/test-lint` exits 0 with 7 passed, 0 failed
- [ ] `git log --oneline engineer/stack-v01 | wc -l` shows ≥ 22 commits (1 per task that commits)
- [ ] `git tag -l v0.1.0` returns `v0.1.0`
- [ ] All 12 agents present, all 5 new skills present, all 3 commands present, all 14 vendored skills present, manifest valid, README and LICENSE present

If any verification fails, the implementer dispatches a fix and re-verifies before claiming completion.
