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
