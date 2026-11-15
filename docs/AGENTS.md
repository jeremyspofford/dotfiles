# Agent configuration

`agents/manifest.toml` owns native config content, discovery commands, formats,
and OS paths. `agents/skills/` owns skill content. Run:

```sh
bash scripts/generate-agent-configs.sh --dry-run
bash scripts/generate-agent-configs.sh
```

Only commands found on PATH are configured. No agent binary is installed or
started. JSON/TOML defaults are deliberately minimal; native authentication stays
with each agent. Per-skill symlinks avoid copying skill content or replacing an
entire user skills directory. Keep the source checkout at a stable location.

Existing unowned or modified files cause a failure before writes. Review and move
them aside, incorporate desired non-secret settings into the manifest, then rerun.
The output inventory at `~/.local/state/dotfiles/agents.json` stores paths and
hashes, never credentials. It retains records for absent agents; removing an agent
does not silently delete its configuration. To tear down, remove only files whose
hash/link still matches the inventory, then remove those entries. Never recursively
delete an agent directory; it may contain credentials or user-created skills.

| Agent | Native config relative to home | Skill discovery relative to home |
| --- | --- | --- |
| [claude](https://code.claude.com/docs/en/settings) | `.claude/settings.json` | `.claude/skills` |
| [codex](https://developers.openai.com/codex/config-basic/) | `.codex/config.toml` | `.agents/skills` |
| [gemini](https://geminicli.com/docs/cli/skills/) | `.gemini/settings.json` | `.gemini/skills` |
| [grok](https://docs.x.ai/build/settings) | `.grok/config.toml` | `.grok/skills` |
| [pi](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent) | `.pi/agent/settings.json` | `.pi/agent/skills` |
| [opencode](https://opencode.ai/docs/config/) | `.config/opencode/opencode.json` | `.config/opencode/skills` |
| [Ollama](https://docs.ollama.com/faq) | Process/service environment; no portable config-file path | None |

The manifest spells out Linux, macOS, Windows and WSL mappings. Bash bootstrap is
supported on Linux/macOS/WSL; native Windows mappings are descriptive and generator
symlinks require developer mode or suitable privileges. WSL configures Linux
agents, not Windows executables. Custom agent home environment variables require
corresponding manifest changes; defaults here target documented standard homes.

Ollama is explicitly unsupported by this config-file generator. Its documented
service environment differs between systemd, launchctl and Windows; inventing a
config file would imply support that does not exist.
