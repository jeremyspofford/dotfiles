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
