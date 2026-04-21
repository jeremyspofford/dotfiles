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
 * Treats empty or whitespace-only files as missing. Upgrades legacy
 * skeletons (from init-daily-log.sh) that lack `sources: []`.
 *
 * Note: gray-matter caches parsed results by content string. We never
 * mutate the returned .data object — always build a fresh one for writes.
 */
export function ensureSkeleton(logPath: string, date: string): void {
  mkdirSync(dirname(logPath), { recursive: true });

  if (existsSync(logPath)) {
    const current = readFileSync(logPath, "utf8");
    if (current.trim().length === 0) {
      writeAtomic(logPath, buildSkeleton(date));
      return;
    }
    const parsed = matter(current);
    if (!("sources" in parsed.data)) {
      // Build a fresh data object — never mutate the cached parsed.data
      const newData = { ...parsed.data, sources: [] };
      writeAtomic(logPath, matter.stringify(parsed.content, newData));
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
  const parsed = matter(raw);
  // gray-matter auto-coerces bare YAML dates (e.g. 2026-04-21) to Date objects.
  // Normalize back to ISO date string so callers always receive a string.
  if (parsed.data.date instanceof Date) {
    parsed.data.date = parsed.data.date.toISOString().slice(0, 10);
  }
  return parsed;
}

/**
 * Merge a source_tool into frontmatter.sources[] and write atomically.
 * Never mutates parsed.data — builds a fresh data object for the write.
 */
export function mergeSources(logPath: string, sourceTool: string): string[] {
  const parsed = readDailyLog(logPath);
  const current = Array.isArray(parsed.data.sources) ? [...parsed.data.sources] : [];
  if (!current.includes(sourceTool)) {
    current.push(sourceTool);
  }
  // Build a fresh data object — never mutate the gray-matter cache
  const newData = { ...parsed.data, sources: current };
  writeAtomic(logPath, matter.stringify(parsed.content, newData));
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
