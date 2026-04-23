Display the wiki command reference below. Do not read any files or execute any workflows. Just print this exactly as formatted.

---

## Wiki Commands

```
COMMAND              USAGE                                                        DESCRIPTION
-------              -----                                                        -----------
/wiki-capture        /wiki-capture [--project d/p] [--type TYPE] [--tags t1,t2]   Write a capture note to raw/
/wiki-ingest         /wiki-ingest [domain/project]                                Process pending raw notes into wiki pages
/wiki-query          /wiki-query <question>                                       Answer a question from wiki content only
/wiki-lint           /wiki-lint [domain/project]                                  Audit wiki for issues and inconsistencies
/wiki-status         /wiki-status                                                 Report pending notes, page counts, last ingest
/wiki-tag            /wiki-tag propose <tagname> [--category CAT]                 Propose a new tag for the approved registry
/wiki-review         /wiki-review [path/to/repo] [--since YYYY-MM-DD]            Review git diffs for knowledge worth capturing
/lecture-note        /lecture-note <paste markdown>                               Import Chrome extension lecture note into vault
/wiki-help           /wiki-help                                                   This help message
```

### /wiki-capture

Write a raw capture note to `$WIKI_VAULT/raw/[domain]/[project]/`.

```
Options:
  --project domain/project    Project slug (inferred from CWD if omitted)
  --type TYPE                 One of: decision, pattern, reference, note (default: note)
  --tags tag1,tag2            Approved tags only (see /wiki-tag)
```

Appends to today's file if it already exists. Content is classified automatically. All captures get YAML frontmatter with `ingested: false`.

### /wiki-ingest

Process all raw notes with `ingested: false` into structured wiki pages.

```
Arguments:
  domain/project              Scope to a specific project (optional, default: all pending)
```

For each raw note: reads it, discusses takeaways, creates/updates concept, project, and entity pages, updates all indexes, logs the operation, and archives the raw note. Also ingests pending `Assistant/memory/` daily logs.

### /wiki-query

Answer a question using only wiki content. No hallucination, no inference.

```
Arguments:
  <question>                  The question to answer (required)
```

Reads `wiki/index.md` first, then relevant pages. Cites sources. If the answer isn't in the wiki, says so. Offers to file valuable answers as new pages.

### /wiki-lint

Audit the wiki for quality issues.

```
Arguments:
  domain/project              Scope to a specific project (optional, default: full vault)
```

Checks for: contradictions between pages, orphan pages, missing concept pages, `needs-review` pages, stale sources, missing frontmatter fields, unapproved tags, bad filenames. Reports as a numbered list with file paths and fixes.

### /wiki-status

Dashboard view of wiki health. No arguments.

Reports: last ingest date per domain, pending raw note count, `needs-review` notes (listed by path), wiki page count by type, and pending `Assistant/memory/` logs.

### /wiki-tag

Propose a new tag for the approved registry.

```
Arguments:
  propose <tagname>           Tag to propose (required)
  --category CAT              Registry category (optional)
```

Does NOT use the tag immediately. Identifies affected pages, presents proposal, waits for approval. On approval: adds to registry, applies to new content, back-fills identified pages, logs the change.

### /wiki-review

Review a project's recent git activity for knowledge worth capturing.

```
Arguments:
  path/to/repo                Path to the git repo (optional, default: CWD)
  --since YYYY-MM-DD          Start date for git log (optional, default: today)
```

Reads git log and diffs, identifies decisions, patterns, gotchas, and learnings. Skips routine changes. Presents findings and lets you pick what to capture. Writes confirmed items to `raw/[domain]/[project]/`. Designed for end-of-day review of work done in other IDEs (e.g. Cursor).

### /lecture-note

Import a lecture note from the Chrome extension into the vault.

```
Arguments:
  <markdown>                  Paste the full markdown output from the Chrome extension /note shortcut
```

Creates the file in the correct cert folder, fixes frontmatter/tags/links, removes low-quality SR cards, and updates the cert `_Index.md` lecture table and section checklist. One command replaces manual file creation + copy-paste + index updates.
