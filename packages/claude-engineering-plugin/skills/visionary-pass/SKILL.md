---
name: visionary-pass
description: Use only on explicit user request (via /visionary or /engineer visionary). Runs visionary agent to propose new project directions.
---

# Visionary Pass

## Overview

Visionary pass runs the `visionary` role agent against the current state of
a project and returns a small set of proposals — new directions, features,
or architectural shifts that the project could take next. Each proposal is
written as a "starter spec" terse enough to feed back into `/engineer
"<proposal>"` if the user wants to pursue it.

This is the only skill in the engineering stack that does not run on
autopilot. It is opt-in by design.

## When invoked

**Never automatically.** Only on explicit user request via:

- `/engineer visionary` — invoked from inside an active engineering session,
  typically after a finished branch.
- `/visionary` — standalone shortcut that runs visionary-pass against the
  current project without going through `/engineer`.

`engineering-orchestrator` will not call this skill on its own; it appears
as step 9 of the lifecycle but is dashed/optional.

## Why deliberate-only

The visionary agent is a high-value, low-frequency tool. Its output is
"what should this project become?" — the kind of question whose answer
matters most when it is asked at the right moment, and matters least when
it is asked reflexively after every task.

Running visionary-pass at the end of every cycle would dilute it into
noise. Users would learn to skim past its output, and the genuinely good
proposals would get lost. Making it explicit-only forces the user to opt
in when they actually have headspace for the question, and treats the
output as worth reading because they asked for it.

## Inputs

- **Project root path** — the worktree or repo to evaluate against.
- **Recent git log / commit summaries** — typically the last 30-90 days,
  enough to convey trajectory without overwhelming the agent.
- **Current spec(s) / open plans** — what the project is currently building
  or has just shipped.
- **(Optional) user-known pain points or context** — free-form. The user
  can paste in customer feedback, a bug they keep seeing, a competitive
  observation, etc. This is not required but sharpens proposals when
  available.

## Outputs

**3-7 proposals**, each containing:

- **Rationale** — why this direction makes sense given the project's
  current state.
- **User value** — what concrete benefit a user gets if this is built.
- **Fit with existing architecture** — how this layers onto what already
  exists; whether it requires breaking changes or extends cleanly.
- **Rough scope estimate** — small / medium / large, or rough
  task-count/duration if the agent can ground it.
- **Risk** — what could go wrong, what assumptions are load-bearing, what
  the failure mode is if the proposal is wrong.

Each proposal is written as a **starter spec** — terse enough that the user
can paste it back into `/engineer "<proposal text>"` and have the orchestrator
take it through the full lifecycle without further refinement.

## Process

1. Resolve the inputs above. If the project root isn't a git repo, fall back
   to whatever context the user provides explicitly; do not invent project
   history.
2. Invoke the `visionary` role agent (defined in `agents/visionary.md`) in
   advisor mode with the assembled context.
3. Format the agent's output for user consumption: numbered list of
   proposals with the five fields above. Keep prose tight; bullet lists are
   fine.
4. Return the formatted output. Do not auto-pursue any proposal — the user
   picks zero, one, or several and decides what (if anything) to feed back
   into `/engineer`.

## Key invariant

**Opt-in only.** No code path elsewhere in the engineering stack should
call this skill without the user explicitly asking. If you find yourself
considering it as a default step, stop and re-read this section.
