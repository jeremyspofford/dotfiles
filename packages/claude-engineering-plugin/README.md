# engineering-stack

Role-aware engineering orchestrator for Claude Code.

## What it does

engineering-stack provides 12 specialized role agents (frontend, backend, ux-designer, security, cloud, cicd, sre, network, qa, performance, visionary, conflict-reconciler) and an orchestration spine that runs a brainstorm → plan → execute → review lifecycle, pulling the right specialists into each step. It includes multi-session worktree safety and a merge-conflict reconciler for when parallel work overlaps. The plugin is built on a vendored copy of Anthropic's superpowers plugin so it stays independent of upstream maintenance churn.

## Install

For v0.1, the plugin is loaded as a local development plugin. Installation as `/plugin install <git-url>` from a remote repo is a v0.2 concern — once the plugin lives in its own remote repository.

To use it now, symlink (or copy) this directory into your Claude Code plugins directory, typically `~/.claude/plugins/`:

```bash
# From inside this directory:
ln -s "$PWD" ~/.claude/plugins/engineering-stack
```

After Claude Code reloads, the `/engineer`, `/visionary`, and `/reconcile` commands will be available.

## Usage

```bash
/engineer "build a calculator app deployed to AWS"
```

End-to-end engineering lifecycle: brainstorm scope, plan with the right specialists, execute, then review.

```bash
/visionary
```

Run a visionary pass on the current plan — surface non-obvious risks, opportunities, and second-order effects before commitment.

```bash
/reconcile .worktrees/engineer-add-billing
```

Reconcile a merge conflict between parallel worktree sessions, with the conflict-reconciler agent owning the integration.

## Architecture

```
Commands (commands/)
  ↓
Engineering-stack skills (skills/)
  — engineering-orchestrator, ensemble-planning, ensemble-review,
    visionary-pass, merge-conflict-reconciler
  ↓
Vendored superpowers skills (skills/superpowers-vendored/)
  — replaceable foundation
  ↓
Role agents (agents/) — 12 specialists
```

The layering is deliberate: commands are thin entrypoints that hand off to skills; engineering-stack skills carry the orchestration logic and depend on the vendored superpowers layer for primitives (brainstorming, planning, TDD, verification, code review). Role agents are leaf-level workers the orchestrator dispatches into. Vendoring superpowers means upstream maintenance changes never break this plugin's behavior.

## Cursor / other AI tools (stopgap for v0.1)

v0.1 is full-fidelity in Claude Code only. For Cursor and other AI tools (Cline, Continue, Goose, etc.), the v0.1 stopgap is manual:

1. Clone this plugin somewhere accessible.
2. In Cursor, add a `.cursor/rules/engineering-stack.mdc` file pointing at the plugin's `skills/engineering-orchestrator/SKILL.md` and the `agents/<role>.md` file for any role you want to invoke.
3. The Cursor AI will follow the discipline manually — orchestration is not automated.

Tier 2 (a shared MCP server) is planned for v0.2 to make multi-tool support fluid without per-tool rule files.

## Credits

Built on Anthropic's superpowers plugin (claude-plugins-official), vendored
into `skills/superpowers-vendored/`. The orchestration spine, role specialization,
visionary pass, and merge-conflict-reconciler are original work in this plugin.

## License

MIT — see [LICENSE](LICENSE).

## Contributing

PRs welcome. Run `bin/lint-plugin packages/claude-engineering-plugin/` before committing. The lint script is itself self-tested by `bin/test-lint` (13 fixtures); both should exit 0 on a clean tree.

## Roadmap

```
v0.1.0 (this release) — Claude Code plugin (Tier 1)
v0.2.0 — MCP server for Cursor / Cline / Continue / Goose (Tier 2)
v0.3.0 — AGENTS.md export script (Tier 3)
v1.0.0 — All tiers mature; v2 priorities (pre-merge conflict detection,
         cross-session communication) begin design
```
