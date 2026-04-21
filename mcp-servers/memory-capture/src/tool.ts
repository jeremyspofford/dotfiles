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
