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
