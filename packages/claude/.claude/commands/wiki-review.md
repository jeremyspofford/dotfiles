Read `$WIKI_VAULT/CLAUDE.md` first for wiki capture format and tag registry.

Review a project's recent git activity and identify knowledge worth capturing in the wiki.

Usage: /wiki-review [path/to/repo] [--since YYYY-MM-DD]

- If no path is given, use CWD
- If no --since is given, default to today's commits
- Resolve the project slug from the repo path (strip ~/workspace/ prefix)
- If the project slug doesn't map to a known domain, use the directory name and flag it

## Workflow

1. Read the git log for the specified period (authors, messages, file changes)
2. Read the diffs to understand what actually changed
3. Analyze for things worth capturing:
   - Decisions made (why was X chosen over Y?)
   - Patterns used (reusable approaches, architecture choices)
   - Problems solved (gotchas, debugging insights, root causes)
   - Infrastructure/tooling changes (new services, config changes, pipeline updates)
   - Security considerations
   - Things learned (new APIs, service behaviors, edge cases)
4. Skip routine/mechanical changes (version bumps, formatting, boilerplate)
5. Present findings as a numbered list with brief explanations
6. Ask the user which items (if any) to capture
7. For confirmed items, write to `$WIKI_VAULT/raw/[domain]/[project]/YYYY-MM-DD-session.md` using the standard capture format with proper frontmatter

## What NOT to capture

- Code itself (that's in git)
- Task lists or ticket status
- Routine CRUD or config changes
- Anything already documented in the repo's own docs

## What TO capture

- "We chose X because Y" decisions
- "This broke because of Z" debugging insights
- Reusable patterns that could apply to other projects
- Service/API behaviors that surprised you
- Architecture trade-offs and their rationale
