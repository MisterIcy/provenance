#!/usr/bin/env bun
// PostToolUse gate for the pr-description-sync skill. Runs after a `git push`
// Bash call; exits silently unless the feature is enabled and the branch has
// an open PR. Never edits anything itself — it only asks Claude, via
// additionalContext, to run the pr-description-sync skill.
import { execFileSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

export function getOpenPrNumber(): string | null {
  try {
    const out = execFileSync("gh", ["pr", "view", "--json", "number", "-q", ".number"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    });
    const trimmed = out.trim();
    return trimmed || null;
  } catch {
    return null;
  }
}

export function isGhAvailable(): boolean {
  try {
    execFileSync("gh", ["--version"], { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

export function buildContext(prNumber: string): string {
  return JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: `A git push just completed and the current branch has an open PR (#${prNumber}). Invoke the provenance:pr-description-sync skill now to check whether the PR's title/description has drifted from the actual changes, and update it if the user approves.`,
    },
  });
}

function main(): number {
  if (process.env.CLAUDE_PLUGIN_OPTION_PR_SYNC_ENABLED !== "true") return 0;
  if (!isGhAvailable()) return 0;

  const prNumber = getOpenPrNumber();
  if (!prNumber) return 0;

  console.log(buildContext(prNumber));
  return 0;
}

const isMain = process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);
if (isMain) {
  process.exit(main());
}
