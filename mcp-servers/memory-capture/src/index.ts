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
