import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { mkdtempSync, rmSync, readFileSync, writeFileSync } from "node:fs";
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
