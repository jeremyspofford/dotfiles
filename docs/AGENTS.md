# Agent configuration

An agent is an installed coding assistant. A skill is a folder of instructions for an agent.
The manifest, a configuration list at `agents/manifest.toml`, owns content, discovery commands, formats, and operating-system paths. Skills live in `agents/skills/`.
`PATH` lists directories searched for commands. Only commands found there get configuration.
It installs and starts no agent. Agent login remains separate.

To generate settings from `~/dotfiles`:

1. Run `bash scripts/generate-agent-configs.sh --dry-run`. This validates inputs and reports proposed paths without writing.
2. Review the paths and resolve any conflicts.
3. Run `bash scripts/generate-agent-configs.sh` to write settings and links.

JSON and TOML are configuration file formats. Generated defaults use minimal valid content.
Each skill gets a symbolic link to its source folder, without copying content or replacing whole skills directories.
Keep the checkout at a stable path.

Unknown or modified files or links stop generation before writes. Review them, then move them aside.
Add wanted non-secret settings to the manifest and rerun. Never put login credentials in the manifest.
`~/.local/state/dotfiles/agents.json` records output paths and hashes, not credentials. A hash identifies file contents for comparison.
Records for absent agents and unused outputs remain for review. Removing an agent never silently deletes configuration.

## Paths and limits

| Agent | Configuration in home | Skills in home |
| --- | --- | --- |
| [claude](https://code.claude.com/docs/en/settings) | `~/.claude/settings.json` | `~/.claude/skills` |
| [codex](https://developers.openai.com/codex/config-basic/) | `~/.codex/config.toml` | `~/.agents/skills` |
| [gemini](https://geminicli.com/docs/cli/skills/) | `~/.gemini/settings.json` | `~/.gemini/skills` |
| [grok](https://docs.x.ai/build/settings) | `~/.grok/config.toml` | `~/.grok/skills` |
| [pi](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent) | `~/.pi/agent/settings.json` | `~/.pi/agent/skills` |
| [opencode](https://opencode.ai/docs/config/) | `~/.config/opencode/opencode.json` | `~/.config/opencode/skills` |
| [Ollama](https://docs.ollama.com/faq) | Process/service environment; no portable file path | None |

The manifest maps Linux, macOS, Windows, and WSL (Windows Subsystem for Linux).
Bash setup supports Linux, macOS, and WSL. Native Windows paths are descriptive; links require developer mode or suitable privileges.
WSL configures Linux agents, not Windows executables. Custom agent-home environment variables require matching manifest changes.
Defaults target documented standard homes.

Ollama is unsupported: it uses process/service environment settings, not a portable configuration file.
Service setup differs across Linux's systemd, macOS's launchctl, and Windows.
The generator reports this limit; it invents no file or skill loader.

## Remove generated agent files

1. Read `~/.local/state/dotfiles/agents.json` before deleting the checkout.
2. Compare each file's hash or link target with its recorded value.
3. Remove only outputs that still match. Preserve edited files and explain any retained output before proceeding.
4. Remove matching entries from the record. Remove the record itself only when no entries remain.

Never recursively delete an agent directory. It can contain credentials or user-created skills.
