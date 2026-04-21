# MCP Servers

Custom Model Context Protocol servers for Jeremy's tooling, each self-contained
in its own subdirectory. Servers here are **not** stowed — they're invoked by
absolute path from `~/.claude/settings.json` and `~/.cursor/mcp.json`.

## Convention

Each server lives in its own subdirectory with:
- Its own `package.json`, `tsconfig.json`, tests
- No imports from outside its directory
- Environment variables (e.g. `$WIKI_VAULT`) for any external paths — never hardcoded
- A README explaining what the server exposes

This isolation is the extraction contract: when a server is proven, it can be
`git subtree split` into its own repository without untangling dependencies.

## Servers

- [`memory-capture/`](./memory-capture/) — cross-tool daily-log memory capture for `$WIKI_VAULT/Assistant/memory/`.
