Read `$WIKI_VAULT/CLAUDE.md` first, then execute the `/wiki capture` workflow defined there.

Usage: /wiki capture [--project domain/project] [--type decision|pattern|reference|note] [--tags tag1,tag2]

- Infer --project from CWD if omitted
- Default --type is note
- Use only approved tags from the Tag Registry in $WIKI_VAULT/CLAUDE.md
