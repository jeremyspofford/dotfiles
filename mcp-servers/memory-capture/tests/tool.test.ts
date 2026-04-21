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
