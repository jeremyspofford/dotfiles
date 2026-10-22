# Herdr

Herdr is the persistent terminal workspace for daily project work. Use the
operating system's built-in terminal (**Terminal** on macOS). Start Herdr from a
project directory:

```sh
cd ~/workspace/<project>
herdr
```

A useful layout per project is a **Work** tab with an **Agent** pane and a
**Shell** pane, both in the repo; Herdr keeps whatever layout you build. In the
Agent pane, run `codex` or `claude` when ready. On macOS the shell prefers the
Codex CLI bundled with the ChatGPT app when it is installed; its binary
directory takes precedence over old mise shims, and app updates own that CLI's
version. No agent tasks are started automatically.

Running `herdr` attaches to the default session, or starts it if absent. The
server keeps pane processes alive when you detach or close the terminal. It does
not survive a reboot as a running process. See the upstream
[session guide](https://herdr.dev/docs/session-state/) for restoration behavior.

Use one workspace per project. Start with the mouse: click workspaces, tabs, and
panes; right-click for actions; drag pane dividers to resize. Start your coding
agent from a project pane when ready. Herdr detects supported agent processes and
shows their state in the sidebar. The desktop Codex chat is separate from a CLI
agent running inside a pane.

## A few shortcuts

Press Ctrl-B, release, then the listed key:

| Key | Action |
| --- | --- |
| `v` | Split right |
| `-` | Split down |
| `c` | New tab |
| `w` | Workspace picker |
| `z` | Zoom the focused pane |
| `q` | Detach; pane processes keep running |
| `?` | Show all active bindings |

These are Herdr's defaults, independent of tmux's Ctrl-A prefix. There is no need
to nest tmux inside Herdr for ordinary use.

## Configuration and troubleshooting

Configuration comes from `chezmoi/dot_config/private_herdr/config.toml` and is
installed at `~/.config/herdr/config.toml`. New panes follow the current directory
and use the normal shell environment. Homebrew owns binary updates.

```sh
herdr status
herdr integration status
herdr server reload-config
```

`herdr server stop` terminates the server and its pane processes; use detach for
normal day-to-day exits. Agent-specific integrations are optional and separate
from the shell configuration. They can improve agent status/session restoration.

Upstream references: [first-time guide](https://herdr.dev/agent-guide.md),
[keyboard guide](https://herdr.dev/docs/keyboard/), and
[agent integrations](https://herdr.dev/docs/integrations/).
