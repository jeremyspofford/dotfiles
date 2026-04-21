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
      cwd: "/home/jeremy/workspace/dotfiles/mcp-servers/memory-capture",
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
