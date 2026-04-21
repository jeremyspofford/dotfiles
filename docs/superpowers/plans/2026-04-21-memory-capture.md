# Memory Capture MCP Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a cross-tool (Claude Code + Cursor) MCP server that provides deterministic, locked, atomic appends to `$WIKI_VAULT/Assistant/memory/YYYY-MM-DD.md`, wire both tools to call it, and add a Claude Code `SessionStart` catch-up hook that recovers from abnormal-exit days.

**Architecture:** TypeScript + bun stdio MCP server exposing one tool (`append_to_daily_log`) at `~/workspace/dotfiles/mcp-servers/memory-capture/` — self-contained, extraction-ready. Frontmatter `sources: []` array merged-and-deduped atomically per write using `proper-lockfile`. Claude Code integration reuses the existing stowed `~/.claude/settings.json` (rewrites `SessionEnd` prompt, adds catch-up hook). Cursor integration via reorganized stow package (`dotfiles/cursor/.cursor/...`) plus a memory-capture rule file.

**Tech Stack:**
- Runtime: `bun` (1.3.12 installed via mise)
- Language: TypeScript
- MCP SDK: `@modelcontextprotocol/sdk`
- Frontmatter: `gray-matter`
- File locking: `proper-lockfile`
- Test runner: `bun test`

**Spec:** [`docs/superpowers/specs/2026-04-21-memory-robustness-design.md`](../specs/2026-04-21-memory-robustness-design.md)

---

## Prerequisites before starting

- `bun --version` returns 1.3.x
- `$WIKI_VAULT` resolves to `/home/jeremy/Obsidian_Vault`
- `git status` in `~/workspace/dotfiles` is clean on `main`
- The existing `~/.claude/settings.json` symlink points to `~/workspace/dotfiles/claude/.claude/settings.json`

---

## File structure to be created/modified

### New files (MCP server — extraction-ready sibling package)

```
~/workspace/dotfiles/
└── mcp-servers/
    ├── README.md                                 # index + convention
    └── memory-capture/
        ├── README.md
        ├── package.json
        ├── tsconfig.json
        ├── .gitignore                            # node_modules
        ├── src/
        │   ├── index.ts                          # stdio server entry point
        │   ├── tool.ts                           # append_to_daily_log definition
        │   └── lib/
        │       ├── paths.ts                      # vault path + date helpers
        │       ├── daily-log.ts                  # frontmatter + skeleton + append
        │       └── lock.ts                       # proper-lockfile wrapper
        └── tests/
            ├── paths.test.ts
            ├── daily-log.test.ts
            ├── lock.test.ts
            ├── tool.test.ts
            ├── integration.test.ts
            └── concurrency.test.ts
```

### New files (Claude Code hook)

```
~/workspace/dotfiles/claude/.claude/hooks/
└── catchup-daily-log.sh                          # SessionStart catch-up
```

### New files (Cursor stow package — reorganized)

```
~/workspace/dotfiles/cursor/
└── .cursor/
    ├── mcp.json                                  # merged from existing ~/.cursor/mcp.json
    └── rules/
        ├── tutor-mode.mdc                        # moved from cursor/rules/
        └── memory-capture.mdc                    # NEW
```

### Modified files

- `~/workspace/dotfiles/claude/.claude/settings.json` — register MCP server, add catch-up hook, rewrite `SessionEnd` prompt
- `~/workspace/dotfiles/claude/.claude/CLAUDE.md` — instruct AI to use MCP tool instead of `Write`
- `~/workspace/dotfiles/cursor/rules/` — delete after moving contents into `cursor/.cursor/rules/`

---

## Phase 1 — MCP server foundations (TDD)

### Task 1: Project scaffolding

**Files:**
- Create: `mcp-servers/README.md`
- Create: `mcp-servers/memory-capture/README.md`
- Create: `mcp-servers/memory-capture/package.json`
- Create: `mcp-servers/memory-capture/tsconfig.json`
- Create: `mcp-servers/memory-capture/.gitignore`
- Create: `mcp-servers/memory-capture/src/index.ts` (placeholder)

- [ ] **Step 1: Create the package directory and scaffold**

```bash
cd ~/workspace/dotfiles
mkdir -p mcp-servers/memory-capture/{src/lib,tests}
cd mcp-servers/memory-capture
```

- [ ] **Step 2: Write `package.json`**

```json
{
  "name": "memory-capture",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "description": "MCP server for cross-tool daily-log memory capture",
  "main": "src/index.ts",
  "scripts": {
    "start": "bun run src/index.ts",
    "test": "bun test",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "latest",
    "gray-matter": "^4.0.3",
    "proper-lockfile": "^4.1.2"
  },
  "devDependencies": {
    "@types/bun": "latest",
    "@types/proper-lockfile": "^4.1.4",
    "typescript": "^5.6.3"
  }
}
```

- [ ] **Step 3: Write `tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "types": ["bun-types"],
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*", "tests/**/*"]
}
```

Note: `allowImportingTsExtensions: true` paired with `noEmit: true` is required because our imports use explicit `.ts` extensions (idiomatic for bun + TS; avoids ambiguity between runtime and typecheck).

- [ ] **Step 4: Write `.gitignore`**

```
node_modules/
*.lock
```

- [ ] **Step 5: Write `src/index.ts` placeholder**

```typescript
// stdio MCP server entry point — filled in by Task 7.
export {};
```

- [ ] **Step 6: Install dependencies**

```bash
bun install
```

Expected: `bun install` completes, creates `node_modules/` and `bun.lock`.

- [ ] **Step 7: Verify `bun test` runs**

```bash
bun test
```

Expected: exits 0 with "0 tests" (no test files yet).

- [ ] **Step 8: Write `mcp-servers/README.md`**

```markdown
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
```

- [ ] **Step 9: Write `mcp-servers/memory-capture/README.md`**

```markdown
# memory-capture

MCP server that writes curated notes to Jeremy's personal assistant daily
logs at `$WIKI_VAULT/Assistant/memory/YYYY-MM-DD.md`. Called from both
Claude Code and Cursor.

## Environment

- `WIKI_VAULT` (required) — absolute path to the Obsidian vault root.

## Tools

### `append_to_daily_log`

Appends a section to the target day's log file. Creates the file (with a
skeleton) if missing. Merges the calling tool into the frontmatter
`sources` array. Atomic under `proper-lockfile`.

Arguments:
- `content` (string, required) — markdown body to append
- `session_context` (string, required) — one-line header describing the work
- `source_tool` (string, required) — `"claude-code"` | `"cursor"` | ...
- `timestamp` (string, optional) — ISO datetime; defaults to now
- `date` (string, optional) — `YYYY-MM-DD`; defaults to today

Returns: `{ path, bytes_written, section_added, sources_updated }`.

## Running

```bash
bun run start
# or
bun run src/index.ts
```

See the spec at `docs/superpowers/specs/2026-04-21-memory-robustness-design.md`
for full design context.
```

- [ ] **Step 10: Commit**

```bash
cd ~/workspace/dotfiles
git add mcp-servers/
git commit -m "feat(mcp): scaffold memory-capture MCP server package"
```

---

### Task 2: Path and date helpers

**Files:**
- Create: `src/lib/paths.ts`
- Create: `tests/paths.test.ts`

- [ ] **Step 1: Write failing test**

Create `tests/paths.test.ts`:

```typescript
import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { resolveDailyLogPath, resolveVaultRoot, isoDate, formatTime } from "../src/lib/paths";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

describe("paths", () => {
  let tmp: string;

  beforeEach(() => {
    tmp = mkdtempSync(join(tmpdir(), "memcap-paths-"));
  });

  afterEach(() => {
    rmSync(tmp, { recursive: true, force: true });
  });

  test("resolveVaultRoot returns WIKI_VAULT env var when set", () => {
    expect(resolveVaultRoot({ WIKI_VAULT: tmp })).toBe(tmp);
  });

  test("resolveVaultRoot throws structured error when WIKI_VAULT is missing", () => {
    expect(() => resolveVaultRoot({})).toThrow("WIKI_VAULT");
  });

  test("resolveVaultRoot expands tilde", () => {
    const home = process.env.HOME!;
    expect(resolveVaultRoot({ WIKI_VAULT: "~/Obsidian_Vault", HOME: home })).toBe(`${home}/Obsidian_Vault`);
  });

  test("resolveDailyLogPath composes vault + Assistant/memory + date.md", () => {
    expect(resolveDailyLogPath(tmp, "2026-04-21")).toBe(`${tmp}/Assistant/memory/2026-04-21.md`);
  });

  test("isoDate returns YYYY-MM-DD for given Date", () => {
    expect(isoDate(new Date("2026-04-21T10:15:00Z"))).toBe("2026-04-21");
  });

  test("formatTime returns HH:MM from ISO datetime string (local time)", () => {
    expect(formatTime("2026-04-21T10:15:30Z")).toMatch(/^\d{2}:\d{2}$/);
  });
});
```

- [ ] **Step 2: Run to confirm failure**

```bash
bun test tests/paths.test.ts
```

Expected: FAIL — cannot resolve `../src/lib/paths`.

- [ ] **Step 3: Implement `src/lib/paths.ts`**

```typescript
import { join } from "node:path";

export function resolveVaultRoot(env: Record<string, string | undefined>): string {
  const raw = env.WIKI_VAULT;
  if (!raw) {
    throw new Error("WIKI_VAULT environment variable is not set");
  }
  if (raw.startsWith("~/")) {
    const home = env.HOME;
    if (!home) {
      throw new Error("Cannot expand ~ in WIKI_VAULT: HOME is not set");
    }
    return `${home}/${raw.slice(2)}`;
  }
  return raw;
}

export function resolveDailyLogPath(vaultRoot: string, date: string): string {
  return join(vaultRoot, "Assistant", "memory", `${date}.md`);
}

export function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

export function formatTime(isoTimestamp: string): string {
  const d = new Date(isoTimestamp);
  const hh = String(d.getHours()).padStart(2, "0");
  const mm = String(d.getMinutes()).padStart(2, "0");
  return `${hh}:${mm}`;
}
```

- [ ] **Step 4: Run tests, confirm pass**

```bash
bun test tests/paths.test.ts
```

Expected: 6 pass, 0 fail.

- [ ] **Step 5: Commit**

```bash
git add src/lib/paths.ts tests/paths.test.ts
git commit -m "feat(mcp): path and date helpers for daily log resolution"
```

---

### Task 3: Daily log module (frontmatter + skeleton + append)

**Files:**
- Create: `src/lib/daily-log.ts`
- Create: `tests/daily-log.test.ts`

- [ ] **Step 1: Write failing test**

```typescript
import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { mkdtempSync, rmSync, readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { ensureSkeleton, mergeSources, appendSection, readDailyLog } from "../src/lib/daily-log";

describe("daily-log", () => {
  let tmp: string;
  let logPath: string;

  beforeEach(() => {
    tmp = mkdtempSync(join(tmpdir(), "memcap-log-"));
    logPath = join(tmp, "2026-04-21.md");
  });

  afterEach(() => {
    rmSync(tmp, { recursive: true, force: true });
  });

  test("ensureSkeleton creates file with frontmatter and H1 when missing", () => {
    ensureSkeleton(logPath, "2026-04-21");
    const body = readFileSync(logPath, "utf8");
    expect(body).toContain("date: 2026-04-21");
    expect(body).toContain("ingested: false");
    expect(body).toContain("sources: []");
    expect(body).toContain("# 2026-04-21");
  });

  test("ensureSkeleton rewrites empty files", () => {
    writeFileSync(logPath, "");
    ensureSkeleton(logPath, "2026-04-21");
    const body = readFileSync(logPath, "utf8");
    expect(body).toContain("sources: []");
  });

  test("ensureSkeleton preserves a properly-formed existing log", () => {
    const fixture = `---\ndate: 2026-04-21\ningested: false\nsources:\n  - claude-code\n---\n\n# 2026-04-21\n\n## Session: pre-existing — claude-code @ 09:00\n\n- already here\n`;
    writeFileSync(logPath, fixture);
    ensureSkeleton(logPath, "2026-04-21");
    expect(readFileSync(logPath, "utf8")).toBe(fixture);
  });

  test("ensureSkeleton upgrades a legacy skeleton missing sources[]", () => {
    // Mimics what init-daily-log.sh writes — no `sources` field
    const legacy = `---\ndate: 2026-04-21\ningested: false\n---\n\n# 2026-04-21\n`;
    writeFileSync(logPath, legacy);
    ensureSkeleton(logPath, "2026-04-21");
    const body = readFileSync(logPath, "utf8");
    expect(body).toContain("sources: []");
    expect(body).toContain("date: 2026-04-21");
    expect(body).toContain("# 2026-04-21");
  });

  test("mergeSources adds new source to frontmatter", () => {
    ensureSkeleton(logPath, "2026-04-21");
    const updated = mergeSources(logPath, "claude-code");
    expect(updated).toEqual(["claude-code"]);
    expect(readFileSync(logPath, "utf8")).toContain("sources:\n  - claude-code");
  });

  test("mergeSources dedupes existing source", () => {
    ensureSkeleton(logPath, "2026-04-21");
    mergeSources(logPath, "claude-code");
    const updated = mergeSources(logPath, "claude-code");
    expect(updated).toEqual(["claude-code"]);
  });

  test("mergeSources appends second distinct source", () => {
    ensureSkeleton(logPath, "2026-04-21");
    mergeSources(logPath, "claude-code");
    const updated = mergeSources(logPath, "cursor");
    expect(updated).toEqual(["claude-code", "cursor"]);
  });

  test("appendSection adds formatted heading and body", () => {
    ensureSkeleton(logPath, "2026-04-21");
    appendSection(logPath, {
      session_context: "working on memory capture",
      source_tool: "claude-code",
      timestamp: "2026-04-21T10:15:00Z",
      content: "- decision: use single tool\n- preference: bun runtime",
    });
    const body = readFileSync(logPath, "utf8");
    expect(body).toMatch(/## Session: working on memory capture — claude-code @ \d{2}:\d{2}/);
    expect(body).toContain("- decision: use single tool");
    expect(body).toContain("- preference: bun runtime");
  });

  test("readDailyLog returns frontmatter and body", () => {
    ensureSkeleton(logPath, "2026-04-21");
    const result = readDailyLog(logPath);
    expect(result.data.date).toBe("2026-04-21");
    expect(result.data.ingested).toBe(false);
    expect(result.data.sources).toEqual([]);
  });
});
```

- [ ] **Step 2: Run to confirm failure**

```bash
bun test tests/daily-log.test.ts
```

Expected: FAIL — cannot resolve `../src/lib/daily-log`.

- [ ] **Step 3: Implement `src/lib/daily-log.ts`**

```typescript
import { existsSync, mkdirSync, readFileSync, writeFileSync, renameSync } from "node:fs";
import { dirname } from "node:path";
import matter from "gray-matter";
import { formatTime } from "./paths.ts";

export interface DailyLogFrontmatter {
  date: string;
  ingested: boolean;
  sources: string[];
  [key: string]: unknown;
}

/**
 * Atomic write: tmp file + rename. POSIX guarantees rename atomicity on the
 * same filesystem. Ensures a reader never sees a half-written file.
 */
function writeAtomic(path: string, content: string): void {
  const tmp = `${path}.tmp.${process.pid}.${Date.now()}`;
  writeFileSync(tmp, content, "utf8");
  renameSync(tmp, path);
}

/**
 * Ensure the daily log exists with the expected skeleton frontmatter.
 * Treats empty or whitespace-only files as missing — this handles the case
 * where another hook (init-daily-log.sh) wrote a partial skeleton we want
 * to overwrite, OR where a prior crash left an empty file.
 *
 * Also upgrades an existing skeleton that lacks the `sources: []` field:
 * the pre-existing init-daily-log.sh writes only `date` and `ingested`.
 * We merge in the `sources: []` field so later `mergeSources` calls see
 * consistent shape.
 */
export function ensureSkeleton(logPath: string, date: string): void {
  mkdirSync(dirname(logPath), { recursive: true });

  if (existsSync(logPath)) {
    const current = readFileSync(logPath, "utf8");
    if (current.trim().length === 0) {
      writeAtomic(logPath, buildSkeleton(date));
      return;
    }
    // File has real content — upgrade frontmatter if missing `sources`.
    const parsed = matter(current);
    if (!("sources" in parsed.data)) {
      parsed.data.sources = [];
      writeAtomic(logPath, matter.stringify(parsed.content, parsed.data));
    }
    return;
  }

  writeAtomic(logPath, buildSkeleton(date));
}

function buildSkeleton(date: string): string {
  return `---
date: ${date}
ingested: false
sources: []
---

# ${date}
`;
}

export function readDailyLog(logPath: string): matter.GrayMatterFile<string> {
  const raw = readFileSync(logPath, "utf8");
  return matter(raw);
}

/**
 * Merge a source_tool into frontmatter.sources[] and write atomically.
 * Idempotent: duplicate sources are deduped.
 */
export function mergeSources(logPath: string, sourceTool: string): string[] {
  const parsed = readDailyLog(logPath);
  const current = Array.isArray(parsed.data.sources) ? parsed.data.sources.slice() : [];
  if (!current.includes(sourceTool)) {
    current.push(sourceTool);
  }
  parsed.data.sources = current;
  writeAtomic(logPath, matter.stringify(parsed.content, parsed.data));
  return current;
}

export interface AppendOptions {
  session_context: string;
  source_tool: string;
  timestamp: string;
  content: string;
}

/**
 * Append a formatted session section at the end of the log. Writes atomically.
 */
export function appendSection(logPath: string, opts: AppendOptions): string {
  const heading = `## Session: ${opts.session_context} — ${opts.source_tool} @ ${formatTime(opts.timestamp)}`;
  const block = `\n${heading}\n\n${opts.content.trimEnd()}\n`;
  const current = readFileSync(logPath, "utf8");
  const next = current.endsWith("\n") ? current + block : current + "\n" + block;
  writeAtomic(logPath, next);
  return heading;
}
```

Note on atomicity: each helper writes via `writeAtomic` (tmp file + rename). The
enclosing `withLock` (Task 4) serializes concurrent callers, so the three
successive rename operations in a single `appendToDailyLog` call are safe as a
group. A crash mid-sequence leaves the file in one of three valid intermediate
states, never corrupted.

- [ ] **Step 4: Run tests, confirm pass**

```bash
bun test tests/daily-log.test.ts
```

Expected: 9 pass, 0 fail.

- [ ] **Step 5: Commit**

```bash
git add src/lib/daily-log.ts tests/daily-log.test.ts
git commit -m "feat(mcp): daily log frontmatter, skeleton, and append helpers"
```

---

### Task 4: Lock wrapper

**Design note:** `proper-lockfile.lock()` requires the target path to exist. The tool's control flow is: lock → ensureSkeleton → mergeSources → appendSection → unlock. Since `ensureSkeleton` may create the file, we touch an empty placeholder before locking when the target is missing. `ensureSkeleton` then treats empty files as not-yet-initialized (already handled in Task 3's implementation).

**Files:**
- Create: `src/lib/lock.ts`
- Create: `tests/lock.test.ts`

- [ ] **Step 1: Write failing test**

```typescript
import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { withLock } from "../src/lib/lock";

describe("lock", () => {
  let tmp: string;

  beforeEach(() => {
    tmp = mkdtempSync(join(tmpdir(), "memcap-lock-"));
  });

  afterEach(() => {
    rmSync(tmp, { recursive: true, force: true });
  });

  test("withLock runs the callback and releases", async () => {
    const target = join(tmp, "f.md");
    writeFileSync(target, "hi");
    const result = await withLock(target, async () => "done");
    expect(result).toBe("done");
  });

  test("withLock works when target file doesn't exist (touches placeholder)", async () => {
    const target = join(tmp, "nested", "not-yet.md");
    const result = await withLock(target, async () => "done");
    expect(result).toBe("done");
  });

  test("withLock serializes two concurrent callers", async () => {
    const target = join(tmp, "f.md");
    writeFileSync(target, "hi");
    const order: string[] = [];
    await Promise.all([
      withLock(target, async () => {
        order.push("A-start");
        await new Promise((r) => setTimeout(r, 50));
        order.push("A-end");
      }),
      withLock(target, async () => {
        order.push("B-start");
        order.push("B-end");
      }),
    ]);
    const seq = order.join(",");
    expect(["A-start,A-end,B-start,B-end", "B-start,B-end,A-start,A-end"]).toContain(seq);
  });

  test("withLock releases even when callback throws", async () => {
    const target = join(tmp, "f.md");
    writeFileSync(target, "hi");
    await expect(withLock(target, async () => { throw new Error("boom"); })).rejects.toThrow("boom");
    const result = await withLock(target, async () => "after");
    expect(result).toBe("after");
  });
});
```

- [ ] **Step 2: Run to confirm failure**

```bash
bun test tests/lock.test.ts
```

Expected: FAIL — cannot resolve `../src/lib/lock`.

- [ ] **Step 3: Implement `src/lib/lock.ts`**

```typescript
import lockfile from "proper-lockfile";
import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

/**
 * Execute `fn` under an exclusive file lock on `filepath`. Creates an empty
 * placeholder if the target doesn't exist yet (proper-lockfile requires the
 * target to exist). Callers are responsible for initializing content inside
 * the callback — `ensureSkeleton` in daily-log.ts handles the empty case.
 *
 * Lock config:
 * - stale: 10s — locks older than this are considered abandoned (crash recovery)
 * - retries: 10 attempts, 50-500ms backoff — handles normal contention
 */
export async function withLock<T>(filepath: string, fn: () => Promise<T>): Promise<T> {
  mkdirSync(dirname(filepath), { recursive: true });
  if (!existsSync(filepath)) {
    writeFileSync(filepath, "");
  }
  const release = await lockfile.lock(filepath, {
    stale: 10_000,
    retries: { retries: 10, minTimeout: 50, maxTimeout: 500 },
  });
  try {
    return await fn();
  } finally {
    await release();
  }
}
```

- [ ] **Step 4: Run lock tests, confirm pass**

```bash
bun test tests/lock.test.ts
```

Expected: 4 pass, 0 fail.

- [ ] **Step 5: Run full suite to confirm no regressions**

```bash
bun test
```

Expected: all `paths`, `daily-log`, `lock` tests pass (19 tests total across 3 files: 6 + 9 + 4).

- [ ] **Step 6: Commit**

```bash
git add src/lib/lock.ts tests/lock.test.ts
git commit -m "feat(mcp): file lock wrapper with stale timeout and retries"
```

---

### Task 5: Tool composition (`append_to_daily_log`)

**Files:**
- Create: `src/tool.ts`
- Create: `tests/tool.test.ts`

- [ ] **Step 1: Write failing test**

```typescript
import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { mkdtempSync, rmSync, readFileSync, existsSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { appendToDailyLog } from "../src/tool";

describe("appendToDailyLog", () => {
  let vault: string;

  beforeEach(() => {
    vault = mkdtempSync(join(tmpdir(), "memcap-tool-"));
  });

  afterEach(() => {
    rmSync(vault, { recursive: true, force: true });
  });

  test("creates file, merges sources, returns observable result", async () => {
    const result = await appendToDailyLog(
      {
        content: "- decided to use bun",
        session_context: "design session",
        source_tool: "claude-code",
        timestamp: "2026-04-21T10:15:00Z",
        date: "2026-04-21",
      },
      { WIKI_VAULT: vault }
    );
    expect(result.path).toBe(`${vault}/Assistant/memory/2026-04-21.md`);
    expect(result.sources_updated).toEqual(["claude-code"]);
    expect(result.section_added).toMatch(/^## Session: design session — claude-code @ /);
    expect(result.bytes_written).toBeGreaterThan(0);
    expect(existsSync(result.path)).toBe(true);
    const body = readFileSync(result.path, "utf8");
    expect(body).toContain("- decided to use bun");
    expect(body).toContain("sources:\n  - claude-code");
  });

  test("second write merges additional source and adds second section", async () => {
    await appendToDailyLog(
      { content: "first", session_context: "ctx1", source_tool: "claude-code", timestamp: "2026-04-21T10:00:00Z", date: "2026-04-21" },
      { WIKI_VAULT: vault }
    );
    const result = await appendToDailyLog(
      { content: "second", session_context: "ctx2", source_tool: "cursor", timestamp: "2026-04-21T14:30:00Z", date: "2026-04-21" },
      { WIKI_VAULT: vault }
    );
    expect(result.sources_updated).toEqual(["claude-code", "cursor"]);
    const body = readFileSync(result.path, "utf8");
    expect(body).toContain("first");
    expect(body).toContain("second");
  });

  test("returns structured error when WIKI_VAULT missing", async () => {
    await expect(
      appendToDailyLog(
        { content: "x", session_context: "y", source_tool: "claude-code", timestamp: "2026-04-21T10:00:00Z", date: "2026-04-21" },
        {}
      )
    ).rejects.toThrow(/WIKI_VAULT/);
  });

  test("defaults date and timestamp when not provided", async () => {
    const result = await appendToDailyLog(
      { content: "x", session_context: "y", source_tool: "claude-code" },
      { WIKI_VAULT: vault }
    );
    const today = new Date().toISOString().slice(0, 10);
    expect(result.path).toBe(`${vault}/Assistant/memory/${today}.md`);
  });
});
```

- [ ] **Step 2: Run to confirm failure**

```bash
bun test tests/tool.test.ts
```

Expected: FAIL — cannot resolve `../src/tool`.

- [ ] **Step 3: Implement `src/tool.ts`**

```typescript
import { statSync } from "node:fs";
import { resolveVaultRoot, resolveDailyLogPath, isoDate } from "./lib/paths.ts";
import { ensureSkeleton, mergeSources, appendSection } from "./lib/daily-log.ts";
import { withLock } from "./lib/lock.ts";

export interface AppendArgs {
  content: string;
  session_context: string;
  source_tool: string;
  timestamp?: string;
  date?: string;
}

export interface AppendResult {
  path: string;
  bytes_written: number;
  section_added: string;
  sources_updated: string[];
}

export async function appendToDailyLog(
  args: AppendArgs,
  env: Record<string, string | undefined> = process.env
): Promise<AppendResult> {
  const vault = resolveVaultRoot(env);
  const date = args.date ?? isoDate(new Date());
  const timestamp = args.timestamp ?? new Date().toISOString();
  const path = resolveDailyLogPath(vault, date);

  return withLock(path, async () => {
    ensureSkeleton(path, date);
    const sources_updated = mergeSources(path, args.source_tool);
    const section_added = appendSection(path, {
      session_context: args.session_context,
      source_tool: args.source_tool,
      timestamp,
      content: args.content,
    });
    const bytes_written = statSync(path).size;
    return { path, bytes_written, section_added, sources_updated };
  });
}
```

- [ ] **Step 4: Run tool tests, confirm pass**

```bash
bun test tests/tool.test.ts
```

Expected: 4 pass, 0 fail.

- [ ] **Step 5: Commit**

```bash
git add src/tool.ts tests/tool.test.ts
git commit -m "feat(mcp): append_to_daily_log tool composition"
```

---

### Task 6: MCP stdio server entry point

**Files:**
- Modify: `src/index.ts`

- [ ] **Step 1: Rewrite `src/index.ts` with MCP SDK**

```typescript
#!/usr/bin/env bun
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { appendToDailyLog } from "./tool.ts";

const server = new Server(
  { name: "memory-capture", version: "0.1.0" },
  { capabilities: { tools: {} } }
);

const TOOL_SCHEMA = {
  name: "append_to_daily_log",
  description:
    "Append a curated section to today's personal assistant daily log at " +
    "$WIKI_VAULT/Assistant/memory/YYYY-MM-DD.md. Creates the file if missing. " +
    "Merges source_tool into the frontmatter sources[] array atomically.",
  inputSchema: {
    type: "object",
    required: ["content", "session_context", "source_tool"],
    properties: {
      content: { type: "string", description: "Markdown body to append" },
      session_context: { type: "string", description: "One-line header describing current work" },
      source_tool: {
        type: "string",
        description: 'Calling tool identifier, e.g. "claude-code", "cursor", "claude-code-catchup"',
      },
      timestamp: { type: "string", description: "ISO datetime; defaults to now" },
      date: { type: "string", description: "YYYY-MM-DD; defaults to today. Used for catch-up writes." },
    },
  },
};

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [TOOL_SCHEMA],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name !== "append_to_daily_log") {
    throw new Error(`Unknown tool: ${request.params.name}`);
  }
  const args = request.params.arguments as any;
  try {
    const result = await appendToDailyLog(args);
    return {
      content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return {
      content: [{ type: "text", text: `ERROR: ${message}` }],
      isError: true,
    };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
console.error("memory-capture MCP server running on stdio");
```

- [ ] **Step 2: Type-check**

```bash
bun run typecheck
```

Expected: no errors.

- [ ] **Step 3: Smoke test — server starts and exits cleanly**

```bash
output=$(echo '' | timeout 2 bun run src/index.ts 2>&1 || true)
echo "--- output ---"
echo "$output"
echo "$output" | grep -q "memory-capture MCP server running on stdio" && echo "SMOKE OK" || { echo "SMOKE FAILED"; exit 1; }
```

Expected: prints `SMOKE OK`. If it prints `SMOKE FAILED`, the server crashed on startup (likely an import resolution error) — inspect the `--- output ---` section for the specific error, fix, and re-run. Do NOT treat a bare exit 124 (timeout) as success — only the presence of the "running on stdio" line proves the server started.

- [ ] **Step 4: Commit**

```bash
git add src/index.ts
git commit -m "feat(mcp): stdio server entry point with append_to_daily_log tool"
```

---

### Task 7: Integration test (real stdio round-trip)

**Files:**
- Create: `tests/integration.test.ts`

- [ ] **Step 1: Write failing test**

```typescript
import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { mkdtempSync, rmSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawn } from "node:child_process";

describe("stdio integration", () => {
  let vault: string;

  beforeEach(() => {
    vault = mkdtempSync(join(tmpdir(), "memcap-int-"));
  });

  afterEach(() => {
    rmSync(vault, { recursive: true, force: true });
  });

  test("spawns server, sends list_tools + call_tool, verifies file", async () => {
    const proc = spawn("bun", ["run", "src/index.ts"], {
      env: { ...process.env, WIKI_VAULT: vault },
      stdio: ["pipe", "pipe", "pipe"],
    });

    const responsesById = new Map<number, any>();
    let buffer = "";
    proc.stdout.on("data", (chunk) => {
      buffer += chunk.toString();
      const lines = buffer.split("\n");
      buffer = lines.pop() ?? "";
      for (const line of lines) {
        if (!line.trim()) continue;
        try {
          const msg = JSON.parse(line);
          if (typeof msg.id === "number") responsesById.set(msg.id, msg);
        } catch { /* ignore non-JSON lines */ }
      }
    });

    const send = (msg: object) => {
      proc.stdin.write(JSON.stringify(msg) + "\n");
    };

    const waitFor = async (id: number, timeoutMs = 5000) => {
      const deadline = Date.now() + timeoutMs;
      while (Date.now() < deadline) {
        if (responsesById.has(id)) return responsesById.get(id);
        await new Promise((r) => setTimeout(r, 50));
      }
      throw new Error(`Timeout waiting for response id=${id}. Received: ${[...responsesById.keys()]}`);
    };

    try {
      send({ jsonrpc: "2.0", id: 1, method: "initialize", params: { protocolVersion: "2024-11-05", capabilities: {}, clientInfo: { name: "test", version: "0" } } });
      await waitFor(1);
      send({ jsonrpc: "2.0", method: "notifications/initialized" });
      send({ jsonrpc: "2.0", id: 2, method: "tools/list" });
      const toolsResp = await waitFor(2);
      expect(JSON.stringify(toolsResp)).toContain("append_to_daily_log");

      send({
        jsonrpc: "2.0",
        id: 3,
        method: "tools/call",
        params: {
          name: "append_to_daily_log",
          arguments: {
            content: "- integration test bullet",
            session_context: "integration test",
            source_tool: "test-harness",
            timestamp: "2026-04-21T10:15:00Z",
            date: "2026-04-21",
          },
        },
      });
      const callResp = await waitFor(3);
      expect(callResp.result.isError).toBeFalsy();
    } finally {
      proc.kill();
    }

    const body = readFileSync(`${vault}/Assistant/memory/2026-04-21.md`, "utf8");
    expect(body).toContain("- integration test bullet");
    expect(body).toContain("test-harness");
  }, 10_000);
});
```

- [ ] **Step 2: Run to confirm it passes**

```bash
bun test tests/integration.test.ts
```

Expected: 1 pass (may take up to 2s due to spawn + wait).

- [ ] **Step 3: Commit**

```bash
git add tests/integration.test.ts
git commit -m "test(mcp): stdio integration test with real MCP protocol"
```

---

### Task 8: Concurrency test

**Files:**
- Create: `tests/concurrency.test.ts`

- [ ] **Step 1: Write failing test (but it should pass immediately — this verifies lock works)**

```typescript
import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { mkdtempSync, rmSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { appendToDailyLog } from "../src/tool";

describe("concurrency", () => {
  let vault: string;

  beforeEach(() => {
    vault = mkdtempSync(join(tmpdir(), "memcap-conc-"));
  });

  afterEach(() => {
    rmSync(vault, { recursive: true, force: true });
  });

  test("10 parallel writes all land, sources deduped, frontmatter intact", async () => {
    const matter = (await import("gray-matter")).default;

    const calls = Array.from({ length: 10 }, (_, i) =>
      appendToDailyLog(
        {
          content: `- bullet ${i}`,
          session_context: `ctx ${i}`,
          source_tool: i % 2 === 0 ? "claude-code" : "cursor",
          timestamp: "2026-04-21T10:15:00Z",
          date: "2026-04-21",
        },
        { WIKI_VAULT: vault }
      )
    );
    const results = await Promise.all(calls);
    expect(results).toHaveLength(10);

    const body = readFileSync(`${vault}/Assistant/memory/2026-04-21.md`, "utf8");

    // All 10 bullets present
    for (let i = 0; i < 10; i++) {
      expect(body).toContain(`- bullet ${i}`);
    }

    // Exactly 10 "## Session:" headings — catches any silent dropped write
    const sectionCount = (body.match(/^## Session:/gm) ?? []).length;
    expect(sectionCount).toBe(10);

    // Frontmatter parses to valid YAML with expected shape
    const parsed = matter(body);
    expect(parsed.data.date).toBe("2026-04-21");
    expect(parsed.data.ingested).toBe(false);
    expect(Array.isArray(parsed.data.sources)).toBe(true);
    expect([...parsed.data.sources].sort()).toEqual(["claude-code", "cursor"]);
  }, 15_000);
});
```

- [ ] **Step 2: Run, confirm pass**

```bash
bun test tests/concurrency.test.ts
```

Expected: 1 pass (takes a few seconds due to serialization).

- [ ] **Step 3: Run full suite**

```bash
bun test
```

Expected: all tests pass (6 test files, ~22 tests).

- [ ] **Step 4: Commit**

```bash
git add tests/concurrency.test.ts
git commit -m "test(mcp): concurrent write serialization and sources dedup"
```

---

## Phase 2 — Claude Code integration

### Task 9: Register MCP server in `settings.json`

**Files:**
- Modify: `~/workspace/dotfiles/claude/.claude/settings.json`

- [ ] **Step 1: Read the current `settings.json`**

```bash
cat ~/workspace/dotfiles/claude/.claude/settings.json
```

- [ ] **Step 2: Add an `mcpServers` entry**

Edit `settings.json` to add (at the top level, sibling to `permissions` and `hooks`):

```json
"mcpServers": {
  "memory-capture": {
    "command": "bun",
    "args": [
      "run",
      "/home/jeremy/workspace/dotfiles/mcp-servers/memory-capture/src/index.ts"
    ],
    "env": { "WIKI_VAULT": "/home/jeremy/Obsidian_Vault" }
  }
}
```

- [ ] **Step 3: Validate JSON**

```bash
bun -e 'JSON.parse(require("fs").readFileSync("/home/jeremy/workspace/dotfiles/claude/.claude/settings.json","utf8"))'
```

Expected: no output (valid JSON).

- [ ] **Step 4: Manual verification — confirm MCP server loads**

Preferred (scriptable):

```bash
claude mcp list 2>&1 | tee /tmp/mcp-list.txt
grep -q "memory-capture" /tmp/mcp-list.txt && echo "MCP LIST OK" || { echo "MCP LIST FAILED — server not registered"; exit 1; }
```

Expected: prints `MCP LIST OK`.

Fallback (interactive): open a Claude Code session and ask "List your MCP tools." The response should include `append_to_daily_log`. If the server crashed on startup, Claude Code shows nothing rather than an error — if the tool is missing, check `~/.claude/logs/` for the server's stderr output before assuming the config is correct.

- [ ] **Step 5: Commit**

```bash
cd ~/workspace/dotfiles
git add claude/.claude/settings.json
git commit -m "feat(claude): register memory-capture MCP server"
```

---

### Task 10: Rewrite `SessionEnd` hook prompt

**Files:**
- Modify: `~/workspace/dotfiles/claude/.claude/settings.json` (SessionEnd hook)

- [ ] **Step 1: Replace the existing `SessionEnd` hook prompt**

The current prompt (paraphrased): write session dump to `raw/sessions/` then append a curated summary to the daily log via the `Write` tool.

Replace with: keep the `raw/sessions/` half; swap the daily-log half to use the MCP tool.

New `SessionEnd` hook prompt (in `settings.json`):

```json
{
  "type": "prompt",
  "prompt": "Before this session ends, perform TWO actions:\n\n(1) Use the Write tool to create a session dump at $WIKI_VAULT/raw/sessions/[YYYY-MM-DD-HHMMSS]-session-dump.md (use the actual current date and time in the filename). Write this frontmatter exactly: source: session/[infer domain/project from CWD or conversation], source_project: [domain/project], captured_date: [today], captured_at: [datetime], session_context: [one line describing what we were working on], ingested: false. In the body, capture: key decisions made, technical insights, patterns identified, project status changes, anything worth preserving. Skip trivial or routine exchanges.\n\n(2) Call the memory-capture MCP server's append_to_daily_log tool with: source_tool=\"claude-code\", session_context=[one line describing the session], content=[3-8 curated bullet points of durable knowledge from the session: decisions, preferences, patterns, corrections]. Do NOT use the Write tool to edit $WIKI_VAULT/Assistant/memory/*.md directly — always route through the MCP tool so the frontmatter sources[] array stays consistent."
}
```

- [ ] **Step 2: Validate JSON**

```bash
bun -e 'JSON.parse(require("fs").readFileSync("/home/jeremy/workspace/dotfiles/claude/.claude/settings.json","utf8"))'
```

Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add claude/.claude/settings.json
git commit -m "feat(claude): route SessionEnd daily-log capture through MCP tool"
```

---

### Task 11: `SessionStart` catch-up hook script

**Files:**
- Create: `~/workspace/dotfiles/claude/.claude/hooks/catchup-daily-log.sh`

- [ ] **Step 1: Write `catchup-daily-log.sh`**

```bash
#!/usr/bin/env bash
# catchup-daily-log.sh — SessionStart hook
#
# Detects when yesterday's daily log is empty (no ## Session: headings) but
# transcripts from that date exist, and emits Claude Code's hook JSON
# protocol with additionalContext telling the AI to fill the gap.

set -euo pipefail

WIKI_VAULT="${WIKI_VAULT:-$HOME/Obsidian_Vault}"

# Portable "yesterday" — BSD date has -v, GNU date has -d
if date -v-1d +%Y-%m-%d >/dev/null 2>&1; then
  yesterday=$(date -v-1d +%Y-%m-%d)
else
  yesterday=$(date -d yesterday +%Y-%m-%d)
fi

log="$WIKI_VAULT/Assistant/memory/$yesterday.md"

[ -f "$log" ] || exit 0

# Structural check: any real append has at least one "## Session:" heading
if grep -q '^## Session:' "$log" 2>/dev/null; then
  exit 0
fi

# Portable transcript-date filter: use touch -t sentinels + find -newer.
# touch -t [[CC]YY]MMDDhhmm is BSD/GNU-common.
yesterday_touch="${yesterday//-/}"
start_ref=$(mktemp)
end_ref=$(mktemp)
trap 'rm -f "$start_ref" "$end_ref"' EXIT
touch -t "${yesterday_touch}0000" "$start_ref"
touch -t "${yesterday_touch}2359" "$end_ref"

transcripts=$(find "$HOME/.claude/projects" -name "*.jsonl" \
  -newer "$start_ref" ! -newer "$end_ref" 2>/dev/null || true)

[ -n "$transcripts" ] || exit 0

# Python 3 used only for JSON-escaping the additionalContext string.
# Soft dep: skip silently if not available.
command -v python3 >/dev/null 2>&1 || exit 0

transcripts_list=$(printf '%s' "$transcripts" | sed 's/^/- /')

context=$(python3 -c '
import json, sys
msg = f"""[catchup-needed] Yesterday'"'"'s log ({sys.argv[1]}) has no session entries yet, but transcripts from that date exist. Please:

1. Read these transcripts briefly
2. Extract 3-6 durable bullets (decisions, insights, preferences, patterns)
3. Call append_to_daily_log with:
     date="{sys.argv[1]}"
     source_tool="claude-code-catchup"
     session_context="<inferred from transcript>"
     content="<3-6 bullets as markdown>"

Transcripts:
{sys.argv[2]}
"""
print(json.dumps(msg))
' "$yesterday" "$transcripts_list") || exit 0

# Defensive: if python3 produced empty output, skip rather than emit malformed JSON
[ -n "$context" ] || exit 0

cat <<EOF
{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": $context}}
EOF

exit 0
```

- [ ] **Step 2: Make executable**

```bash
chmod +x ~/workspace/dotfiles/claude/.claude/hooks/catchup-daily-log.sh
```

- [ ] **Step 3: Manual test — seed a controlled gap and run the real hook**

The script reads `yesterday` from `date`, so to test the catch-up path deterministically we seed conditions that make *the real yesterday* look like a gap, run the script, and verify the JSON output. This is a temporary test fixture; Step 4 cleans it up.

```bash
# Determine yesterday (portable)
if date -v-1d +%Y-%m-%d >/dev/null 2>&1; then
  YESTERDAY=$(date -v-1d +%Y-%m-%d)
else
  YESTERDAY=$(date -d yesterday +%Y-%m-%d)
fi
echo "Testing catchup for: $YESTERDAY"

VAULT=/home/jeremy/Obsidian_Vault
LOG="$VAULT/Assistant/memory/$YESTERDAY.md"

# Back up any real log
if [ -f "$LOG" ]; then
  cp "$LOG" "/tmp/real-yesterday-log.bak"
fi

# Seed: skeleton with no ## Session: headings
cat > "$LOG" <<EOF
---
date: $YESTERDAY
ingested: false
sources: []
---

# $YESTERDAY
EOF

# Seed: a transcript file dated yesterday
mkdir -p ~/.claude/projects/catchup-test-seed
echo '{"role":"user","content":"test content"}' > ~/.claude/projects/catchup-test-seed/seed.jsonl
YTOUCH="${YESTERDAY//-/}"
touch -t "${YTOUCH}1200" ~/.claude/projects/catchup-test-seed/seed.jsonl

# Run the hook; capture stdout
OUTPUT=$(WIKI_VAULT="$VAULT" ~/workspace/dotfiles/claude/.claude/hooks/catchup-daily-log.sh)

echo "--- hook output ---"
echo "$OUTPUT"

# Verify: output is valid JSON with the expected structure
echo "$OUTPUT" | python3 -c '
import json, sys
try:
  msg = json.load(sys.stdin)
  assert msg["hookSpecificOutput"]["hookEventName"] == "SessionStart"
  assert "[catchup-needed]" in msg["hookSpecificOutput"]["additionalContext"]
  assert "catchup-test-seed" in msg["hookSpecificOutput"]["additionalContext"]
  print("HOOK OK")
except Exception as e:
  print(f"HOOK FAILED: {e}")
  sys.exit(1)
'
```

Expected: prints `HOOK OK`. If `HOOK FAILED`, inspect the `--- hook output ---` section.

- [ ] **Step 4: Clean up test fixtures**

```bash
rm -rf ~/.claude/projects/catchup-test-seed
if [ -f "/tmp/real-yesterday-log.bak" ]; then
  mv "/tmp/real-yesterday-log.bak" "$LOG"
else
  rm -f "$LOG"
fi
```

- [ ] **Step 5: Second manual test — confirm no-op when log already populated**

```bash
# Confirm today's log (or any log with ## Session:) produces no output
TODAY=$(date +%Y-%m-%d)
TODAY_LOG="/home/jeremy/Obsidian_Vault/Assistant/memory/$TODAY.md"
# Ensure today has at least one ## Session: heading; if not, seed one
if ! grep -q '^## Session:' "$TODAY_LOG" 2>/dev/null; then
  echo "" >> "$TODAY_LOG"
  echo "## Session: test sentinel — test @ 00:00" >> "$TODAY_LOG"
  SEEDED_TODAY=1
fi

# But we need yesterday to also be populated for this test. Use a fake WIKI_VAULT.
TMPVAULT=$(mktemp -d)
mkdir -p "$TMPVAULT/Assistant/memory"
if date -v-1d +%Y-%m-%d >/dev/null 2>&1; then
  Y=$(date -v-1d +%Y-%m-%d)
else
  Y=$(date -d yesterday +%Y-%m-%d)
fi
cat > "$TMPVAULT/Assistant/memory/$Y.md" <<EOF
---
date: $Y
ingested: false
sources: [claude-code]
---

# $Y

## Session: populated sentinel — claude-code @ 10:00

- a real entry exists here
EOF

OUTPUT=$(WIKI_VAULT="$TMPVAULT" ~/workspace/dotfiles/claude/.claude/hooks/catchup-daily-log.sh)
[ -z "$OUTPUT" ] && echo "NOOP OK" || { echo "NOOP FAILED: got output when none expected"; echo "$OUTPUT"; exit 1; }

rm -rf "$TMPVAULT"
# Remove sentinel we added to today's log if we seeded it
if [ "${SEEDED_TODAY:-0}" = "1" ]; then
  # Remove the last two lines (the blank + sentinel)
  head -n -2 "$TODAY_LOG" > "$TODAY_LOG.tmp" && mv "$TODAY_LOG.tmp" "$TODAY_LOG"
fi
```

Expected: prints `NOOP OK`.

- [ ] **Step 6: Commit**

```bash
cd ~/workspace/dotfiles
git add claude/.claude/hooks/catchup-daily-log.sh
git commit -m "feat(claude): SessionStart catch-up hook for abnormal-exit gaps"
```

---

### Task 12: Register catch-up hook in `settings.json`

**Files:**
- Modify: `~/workspace/dotfiles/claude/.claude/settings.json` (SessionStart array)

- [ ] **Step 1: Add the catch-up entry to the `SessionStart` array**

The current `SessionStart` array has two hooks: `init-daily-log.sh` and `auto-ingest.sh`. Insert the catch-up hook between them (catch-up must run AFTER init — otherwise today's skeleton is missing — and before auto-ingest is fine since they're independent):

```json
"SessionStart": [
  {
    "matcher": "",
    "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/init-daily-log.sh", "timeout": 10 }]
  },
  {
    "matcher": "",
    "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/catchup-daily-log.sh", "timeout": 10 }]
  },
  {
    "matcher": "",
    "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/auto-ingest.sh", "timeout": 30 }]
  }
]
```

- [ ] **Step 2: Validate JSON**

```bash
bun -e 'JSON.parse(require("fs").readFileSync("/home/jeremy/workspace/dotfiles/claude/.claude/settings.json","utf8"))'
```

- [ ] **Step 3: Commit**

```bash
git add claude/.claude/settings.json
git commit -m "feat(claude): register catch-up hook in SessionStart ordering"
```

---

### Task 13: Update global `CLAUDE.md` to point at MCP tool

**Files:**
- Modify: `~/workspace/dotfiles/claude/.claude/CLAUDE.md`

- [ ] **Step 1: Add a section explicitly pointing at the MCP tool**

Append (or update existing "Memory" section):

```markdown

## Memory capture

Use the `append_to_daily_log` MCP tool (from the `memory-capture` server) to
write durable notes to `$WIKI_VAULT/Assistant/memory/YYYY-MM-DD.md`:

- Any time something worth keeping comes up during a session — a decision,
  preference, correction, pattern, or explicit "remember this" — call the
  tool with `source_tool: "claude-code"`, a one-line `session_context`, and
  1-5 bullet points as `content`.
- At session end, the SessionEnd hook will prompt you to write a curated
  3-8 bullet summary via the same tool.

Do NOT use the `Write` tool to edit `Assistant/memory/*.md` files directly.
The MCP tool maintains the frontmatter `sources: []` array atomically under
a file lock; direct writes bypass that and can corrupt concurrent edits.

For session dumps to `$WIKI_VAULT/raw/sessions/` and wiki page writes,
continue using the `Write` tool as before.
```

- [ ] **Step 2: Commit**

```bash
git add claude/.claude/CLAUDE.md
git commit -m "docs(claude): route daily-log writes through memory-capture MCP tool"
```

---

## Phase 3 — Cursor integration

### Task 14: Reorganize `cursor/` stow package layout

**Files:**
- Move: `~/workspace/dotfiles/cursor/rules/tutor-mode.mdc` → `~/workspace/dotfiles/cursor/.cursor/rules/tutor-mode.mdc`
- Delete: `~/workspace/dotfiles/cursor/rules/` (empty after move)

- [ ] **Step 1: Create the new structure**

```bash
cd ~/workspace/dotfiles/cursor
mkdir -p .cursor/rules
git mv rules/tutor-mode.mdc .cursor/rules/tutor-mode.mdc
rmdir rules
```

- [ ] **Step 2: Verify layout**

```bash
find ~/workspace/dotfiles/cursor -type f
```

Expected:
```
~/workspace/dotfiles/cursor/README.md
~/workspace/dotfiles/cursor/.cursor/rules/tutor-mode.mdc
```

- [ ] **Step 3: Commit**

```bash
cd ~/workspace/dotfiles
git add cursor/
git commit -m "refactor(cursor): restructure stow package to mirror ~/.cursor/ layout"
```

---

### Task 15: Merge existing `~/.cursor/mcp.json` into dotfiles

**Files:**
- Create: `~/workspace/dotfiles/cursor/.cursor/mcp.json`

- [ ] **Step 1: Read existing `~/.cursor/mcp.json`**

```bash
cat ~/.cursor/mcp.json
```

- [ ] **Step 2: Merge — start with existing content, add `memory-capture` entry**

Create `~/workspace/dotfiles/cursor/.cursor/mcp.json` with the existing content PLUS the new server. Example (use the actual existing content as the base):

```json
{
  "mcpServers": {
    ...existing servers here...,
    "memory-capture": {
      "command": "bun",
      "args": ["run", "/home/jeremy/workspace/dotfiles/mcp-servers/memory-capture/src/index.ts"],
      "env": { "WIKI_VAULT": "/home/jeremy/Obsidian_Vault" }
    }
  }
}
```

- [ ] **Step 3: Validate JSON**

```bash
bun -e 'JSON.parse(require("fs").readFileSync("/home/jeremy/workspace/dotfiles/cursor/.cursor/mcp.json","utf8"))'
```

- [ ] **Step 4: Commit**

```bash
git add cursor/.cursor/mcp.json
git commit -m "feat(cursor): merge memory-capture MCP server into mcp.json"
```

---

### Task 16: Write Cursor memory-capture rule

**Files:**
- Create: `~/workspace/dotfiles/cursor/.cursor/rules/memory-capture.mdc`

- [ ] **Step 1: Write the rule file**

```markdown
---
description: Capture durable notes to the personal assistant vault
alwaysApply: true
---

# Memory capture

When something worth keeping comes up during our work together — a decision
made, a pattern identified, a correction, a preference expressed, or an
explicit "remember this" — call the `append_to_daily_log` MCP tool from
the `memory-capture` server with:

- `source_tool`: "cursor"
- `session_context`: one line describing the current work
- `content`: 1-5 bullet points in plain markdown
- `timestamp`: current ISO datetime

At the end of a session (or when clearly wrapping up a chunk of work),
call it once more with a 3-8 bullet summary under the same `session_context`.

Do NOT use file-writing tools to edit `Assistant/memory/*.md` directly.
The MCP tool maintains the frontmatter `sources: []` array atomically
under a file lock; direct writes bypass that protection.
```

- [ ] **Step 2: Commit**

```bash
git add cursor/.cursor/rules/memory-capture.mdc
git commit -m "feat(cursor): add memory-capture rule instructing MCP tool use"
```

---

### Task 17: Stow the cursor package

**Files:**
- Modifies symlinks in `~/.cursor/`

- [ ] **Step 1: Audit `~/.cursor/` for potential stow conflicts**

```bash
# List anything in ~/.cursor/ that would collide with the stowed layout
ls -la ~/.cursor/mcp.json 2>/dev/null
ls -la ~/.cursor/rules/ 2>/dev/null
```

For each existing file under `~/.cursor/mcp.json` or `~/.cursor/rules/*.mdc`:
- If it's already a symlink into `~/workspace/dotfiles/cursor/`, leave it (stow will handle).
- If it's a regular file with content we want to preserve, back it up: `cp <path> <path>.pre-stow-backup`
- After backup, remove the original so stow can create the symlink.

- [ ] **Step 2: Back up and remove conflicting originals**

```bash
# mcp.json
if [ -f ~/.cursor/mcp.json ] && [ ! -L ~/.cursor/mcp.json ]; then
  cp ~/.cursor/mcp.json ~/.cursor/mcp.json.pre-stow-backup
  rm ~/.cursor/mcp.json
fi

# Rule files — only the ones we're stowing could conflict
for rule in tutor-mode.mdc memory-capture.mdc; do
  p="$HOME/.cursor/rules/$rule"
  if [ -f "$p" ] && [ ! -L "$p" ]; then
    cp "$p" "$p.pre-stow-backup"
    rm "$p"
  fi
done
```

- [ ] **Step 3: Stow the cursor package**

```bash
cd ~/workspace/dotfiles
stow -v -d ~/workspace/dotfiles -t ~ cursor
```

Expected: stow reports `LINK` operations for `mcp.json` and each rule file with no conflicts. If stow reports a conflict, re-run Step 1 to find the un-handled file.

- [ ] **Step 4: Verify symlinks**

```bash
ls -la ~/.cursor/mcp.json
ls -la ~/.cursor/rules/
```

Expected: both are symlinks into `~/workspace/dotfiles/cursor/.cursor/...`.

- [ ] **Step 5: Confirm contents match**

```bash
diff ~/.cursor/mcp.json.pre-stow-backup ~/.cursor/mcp.json
```

Expected: no diff (merge preserved original entries).

- [ ] **Step 6: Remove backup once verified**

```bash
rm ~/.cursor/mcp.json.pre-stow-backup
```

- [ ] **Step 7: Manual verification — open Cursor, confirm MCP server is available**

Open Cursor IDE, open a chat, ask: "List the MCP tools you have access to." The response should include `append_to_daily_log`.

If the `env` key isn't honored by Cursor (server logs `WIKI_VAULT unset` error), apply the fallback: add `export WIKI_VAULT="/home/jeremy/Obsidian_Vault"` to `~/.zshenv` (which IS stowed via `shell/` package — add it there instead).

---

## Phase 4 — End-to-end validation

### Task 18: Manual test scenarios from spec

Run each scenario; report pass/fail and any discrepancies.

- [ ] **Scenario 1: Fresh day, no log file → tool creates skeleton + first section**

```bash
# Pick a future dated file that doesn't exist yet:
rm -f /home/jeremy/Obsidian_Vault/Assistant/memory/2099-01-01.md
```

In a Claude Code session, ask the AI:
> "Call append_to_daily_log with date=2099-01-01, source_tool='claude-code', session_context='test scenario 1', content='- scenario 1 bullet'"

Verify:
```bash
cat /home/jeremy/Obsidian_Vault/Assistant/memory/2099-01-01.md
```
Expected: valid frontmatter with `sources: [claude-code]`, one `## Session:` heading, body has the bullet. Clean up:
```bash
rm /home/jeremy/Obsidian_Vault/Assistant/memory/2099-01-01.md
```

- [ ] **Scenario 2: Existing skeleton from `init-daily-log.sh` → tool appends**

Start a fresh Claude Code session (the init hook creates today's skeleton). Immediately in the session, trigger a "worth keeping" moment ("Remember: I prefer tabs over spaces for go files."). Expect the AI to call `append_to_daily_log` with `source_tool="claude-code"`.

Verify:
```bash
cat /home/jeremy/Obsidian_Vault/Assistant/memory/$(date +%Y-%m-%d).md
```
Expected: frontmatter `sources: [claude-code]`, one `## Session:` heading, the preference recorded.

- [ ] **Scenario 3: Simulated abnormal prior exit → catch-up fires**

```bash
# Create an empty skeleton dated yesterday:
yesterday=$(date -d yesterday +%Y-%m-%d)
cat > /tmp/skeleton.md <<EOF
---
date: $yesterday
ingested: false
sources: []
---

# $yesterday
EOF
# Preserve the real yesterday's log if it exists:
mv /home/jeremy/Obsidian_Vault/Assistant/memory/$yesterday.md /tmp/yesterday-real.md 2>/dev/null || true
cp /tmp/skeleton.md /home/jeremy/Obsidian_Vault/Assistant/memory/$yesterday.md

# Seed a dummy transcript dated yesterday
mkdir -p ~/.claude/projects/catchup-test
touch -t "$(date -d yesterday +%Y%m%d)1200" ~/.claude/projects/catchup-test/dummy.jsonl
echo '{"role":"user","content":"testing catchup"}' > ~/.claude/projects/catchup-test/dummy.jsonl
touch -t "$(date -d yesterday +%Y%m%d)1200" ~/.claude/projects/catchup-test/dummy.jsonl
```

Start a fresh Claude Code session. In the session context, you should see a `[catchup-needed]` prompt. The AI should read the transcript, call `append_to_daily_log` with `date=<yesterday>` and `source_tool="claude-code-catchup"`.

Verify:
```bash
cat /home/jeremy/Obsidian_Vault/Assistant/memory/$yesterday.md
```
Expected: frontmatter `sources: [claude-code-catchup]`, one `## Session:` heading.

Clean up (non-destructive — only restores real data if backed up):
```bash
rm -rf ~/.claude/projects/catchup-test
if [ -f /tmp/yesterday-real.md ]; then
  mv /tmp/yesterday-real.md /home/jeremy/Obsidian_Vault/Assistant/memory/$yesterday.md
else
  # No real data was backed up — safe to remove the test-seeded file
  rm -f /home/jeremy/Obsidian_Vault/Assistant/memory/$yesterday.md
fi
```

- [ ] **Scenario 4: Cursor integration**

Open Cursor. In a chat, say: "Remember for later: I always want error messages to include file:line references."

Expect the AI to call `append_to_daily_log` with `source_tool="cursor"`.

Verify:
```bash
cat /home/jeremy/Obsidian_Vault/Assistant/memory/$(date +%Y-%m-%d).md
```
Expected: `sources` array now contains `cursor` (in addition to any earlier `claude-code`). A new `## Session: ... — cursor @ HH:MM` heading.

- [ ] **Report**

If all four scenarios pass, mark complete. If any fail, capture the exact error, which scenario, and what the file state looks like — surface those to Jeremy for investigation before proceeding.

---

## Rollback plan

If end-to-end validation reveals a bug that requires reverting:

```bash
cd ~/workspace/dotfiles
git log --oneline | head -20                 # identify pre-change commit
git revert <bad-commit-sha>                  # reverts cleanly since each task committed separately
```

Cursor-specific rollback (if the stow step broke something):

```bash
cd ~/workspace/dotfiles
stow -v -d ~/workspace/dotfiles -t ~ -D cursor
# Restore original mcp.json from backup if still present
cp ~/.cursor/mcp.json.pre-stow-backup ~/.cursor/mcp.json
```

---

## Out of scope (explicit non-goals)

- No writes to `raw/`, `wiki/`, or outside `Assistant/memory/`
- No auto-ingest triggering from the MCP tool — the existing `auto-ingest.sh` hook handles files with `ingested: false`
- No tag validation, content format enforcement, or profanity checks
- No Cursor-side catch-up hook (Cursor has no equivalent hook system; accepted trade-off per spec)
- No remote/HTTP transport — stdio only; extraction-time can add if needed

---

## After plan completion

Update the assistant roadmap at `$WIKI_VAULT/Assistant/ROADMAP.md`:
- Move "Memory capture MCP server" from `## Now — in progress` to a new `## Done` section with completion date
- If any of the "Later — parked" items surfaced as useful during implementation, reorder accordingly
