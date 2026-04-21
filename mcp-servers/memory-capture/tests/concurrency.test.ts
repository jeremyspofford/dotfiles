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
    const dateStr =
      parsed.data.date instanceof Date
        ? parsed.data.date.toISOString().slice(0, 10)
        : parsed.data.date;
    expect(dateStr).toBe("2026-04-21");
    expect(parsed.data.ingested).toBe(false);
    expect(Array.isArray(parsed.data.sources)).toBe(true);
    expect([...parsed.data.sources].sort()).toEqual(["claude-code", "cursor"]);
  }, 15_000);
});
