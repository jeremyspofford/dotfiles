---
description: Propose new feature directions for the current project (shortcut for /engineer visionary).
---

# /visionary

Args: $ARGUMENTS

This is a discoverable top-level shortcut for `/engineer visionary`. It exists
because users who think *"I want fresh ideas for this project"* type
`/visionary` — not `/engineer`. Both routes converge on the same
`visionary-pass` skill; this command is the discoverability surface.

## Routing

Parse `$ARGUMENTS`:

- `--help` → print the **Usage** block below and stop. Do nothing else.
- `--scope=<area>` (and only that flag) → invoke the `visionary-pass` skill
  with the parsed scope hint. The skill will use the scope to focus its
  proposals on a subarea (e.g. `performance`, `developer-experience`,
  `mobile`, etc.).
- Anything else, including no arguments → invoke the `visionary-pass` skill
  with no scope. The skill will propose directions across the whole project.

The `visionary-pass` skill handles reading the project state, running the
`visionary` role agent, and emitting 3-7 proposals. This command is a thin
shell — it does not duplicate that logic.

## Usage

```
/visionary                    # propose new directions for current project
/visionary --scope=<area>     # focus proposals on a subarea
/visionary --help
```

## Examples

`/visionary`, `/visionary --scope=performance`
