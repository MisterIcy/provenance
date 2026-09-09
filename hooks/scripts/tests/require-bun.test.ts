import { describe, expect, it } from "vitest";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";

const SCRIPTS_DIR = path.join(import.meta.dirname, "..");

const WRAPPERS = [
  "guard-git-commit.sh",
  "guard-git-push.sh",
  "guard-sql-readonly.sh",
  "check-pr-drift.sh",
];

function pathWithoutBun(): string {
  // A PATH containing only standard system bin dirs (so bash, command, jq,
  // etc. still resolve) but none of the directories bun could live in on
  // this machine (e.g. ~/.bun/bin, a Homebrew prefix) — plus a fresh empty
  // directory so the PATH is never empty.
  const dir = mkdtempSync(path.join(tmpdir(), "no-bun-"));
  return ["/usr/bin", "/bin", "/usr/sbin", "/sbin", dir].join(path.delimiter);
}

describe("require_bun fail-closed behavior", () => {
  it.each(WRAPPERS)("%s exits 2 with a non-empty stderr message when bun is missing", (wrapper) => {
    const result = spawnSync("/bin/bash", [path.join(SCRIPTS_DIR, wrapper)], {
      input: "{}",
      encoding: "utf8",
      env: { PATH: pathWithoutBun() },
    });
    expect(result.status).toBe(2);
    expect(result.stderr.trim().length).toBeGreaterThan(0);
  });
});
