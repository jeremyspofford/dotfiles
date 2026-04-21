import lockfile from "proper-lockfile";
import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

/**
 * Execute `fn` under an exclusive file lock on `filepath`. Creates an empty
 * placeholder if the target doesn't exist yet (proper-lockfile requires the
 * target to exist). Callers are responsible for initializing content inside
 * the callback.
 *
 * Lock config:
 * - stale: 10s — locks older than this are considered abandoned (crash recovery)
 * - retries: 10 attempts, 50-500ms backoff — handles normal contention
 */
export async function withLock<T>(filepath: string, fn: () => Promise<T>): Promise<T> {
  mkdirSync(dirname(filepath), { recursive: true });
  if (!existsSync(filepath)) {
    writeFileSync(filepath, "");
  }
  const release = await lockfile.lock(filepath, {
    stale: 10_000,
    retries: { retries: 10, minTimeout: 50, maxTimeout: 500 },
  });
  try {
    return await fn();
  } finally {
    await release();
  }
}
