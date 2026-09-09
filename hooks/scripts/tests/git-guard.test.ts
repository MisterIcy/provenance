import { describe, expect, it } from "vitest";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { commandInvokes } from "../git-guard.ts";

const GUARD = path.join(import.meta.dirname, "..", "git-guard.ts");

function runGuard(
  command: string,
  subcommand = "push",
  optionEnvVar = "TEST_OPT",
  env?: Record<string, string>,
) {
  const fullEnv = { ...process.env };
  delete fullEnv[optionEnvVar];
  if (env) Object.assign(fullEnv, env);

  return spawnSync("bun", [GUARD, subcommand, optionEnvVar], {
    input: JSON.stringify({ tool_input: { command } }),
    encoding: "utf8",
    env: fullEnv,
  });
}

describe("commandInvokes", () => {
  it("matches plain git push", () => {
    expect(commandInvokes("git push origin main", "push")).toBe(true);
  });

  it("matches plain git commit", () => {
    expect(commandInvokes("git commit -m 'msg'", "commit")).toBe(true);
  });

  it("does not match unrelated commands", () => {
    expect(commandInvokes("echo hello world", "push")).toBe(false);
    expect(commandInvokes("git status", "push")).toBe(false);
  });

  it("handles global options before the subcommand", () => {
    expect(commandInvokes("git -C repo -c user.name=x push", "push")).toBe(true);
    expect(commandInvokes("git --git-dir=/x/.git push", "push")).toBe(true);
  });

  it("handles compound commands", () => {
    expect(commandInvokes("echo hi && git push", "push")).toBe(true);
    expect(commandInvokes("git push; echo done", "push")).toBe(true);
    expect(commandInvokes("some_cmd | git push", "push")).toBe(true);
  });

  it("double dash stops option scan but subcommand after it still matches", () => {
    expect(commandInvokes("git -- push", "push")).toBe(true);
  });

  it("handles an env assignment prefix", () => {
    expect(commandInvokes("FOO=bar git push", "push")).toBe(true);
  });

  it("treats unbalanced quotes as a conservative match", () => {
    expect(commandInvokes('git status "unterminated', "push")).toBe(true);
    expect(commandInvokes('git status "unterminated', "commit")).toBe(true);
  });

  it("does not mistake a backslash line-continued docker command for git push/commit", () => {
    const command =
      'docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/app -w /app ' +
      "ghcr.io/carthage-software/mago:1.47.4 lint \\\n" +
      "  libraries/Efront/Domain/JobDispatch/JobSettlementService.php \\\n" +
      "  tests/Integration/Domain/JobDispatch/JobSettlementServiceTest.php " +
      "2>&1 | tail -40";
    expect(commandInvokes(command, "push")).toBe(false);
    expect(commandInvokes(command, "commit")).toBe(false);
  });

  it("still detects a real git push across a line continuation", () => {
    const command = "git \\\n  push origin main";
    expect(commandInvokes(command, "push")).toBe(true);
  });

  it("does not match env-only assignment with no actual git invocation", () => {
    expect(commandInvokes("git=1 push", "push")).toBe(false);
  });

  it("does not match an escaped/quoted semicolon glued onto the subcommand", () => {
    expect(commandInvokes("git push\\; rm -rf /", "push")).toBe(false);
    expect(commandInvokes('git "push;" rm -rf /', "push")).toBe(false);
  });
});

// Adversarial cases surfaced by a dedicated red-team pass over this guard
// (see the git history / PR description for the full report). None of these
// are reachable in production today — hooks.json's literal-prefix matcher
// (`Bash(git push *)` / `Bash(git commit *)`) requires the command to start
// with the literal words "git push"/"git commit", which every disguise below
// also breaks — but they're fixed here anyway since the tokenizer should not
// silently misparse real shell quoting/substitution forms.
describe("commandInvokes — adversarial quoting/substitution forms", () => {
  it("detects a backtick command substitution", () => {
    expect(commandInvokes("`git push`", "push")).toBe(true);
  });

  it("still detects a $(...) command substitution", () => {
    expect(commandInvokes("VAR=$(git push)", "push")).toBe(true);
  });

  it("detects ANSI-C quoting ($'push')", () => {
    expect(commandInvokes("git $'push'", "push")).toBe(true);
  });

  it("detects locale-translated quoting ($\"push\")", () => {
    expect(commandInvokes('git $"push"', "push")).toBe(true);
  });
});

// Documented known limitation: git-guard.ts re-tokenizes the command string
// line by line with no concept of heredoc bodies, so inert heredoc data that
// happens to contain the literal words "git push" is scanned as if it were
// its own command. Not reachable in production — the real command here
// starts with "cat", not "git push"/"git commit", so hooks.json's matcher
// never routes it to this guard at all. Documented (not "fixed") so a future
// change to the matcher layer doesn't silently rely on this being safe.
describe("commandInvokes — known limitation: heredoc body is not inert", () => {
  it("treats heredoc body text as a match even though it would never really run", () => {
    const command = "cat <<'EOF' > msg.txt\ngit push\nEOF";
    expect(commandInvokes(command, "push")).toBe(true);
  });
});

describe("git-guard CLI", () => {
  it("produces no output for a non-git command", () => {
    const result = runGuard("echo hello");
    expect(result.status).toBe(0);
    expect(result.stdout.trim()).toBe("");
  });

  it("asks when the option is off", () => {
    const result = runGuard("git push origin main");
    const payload = JSON.parse(result.stdout);
    expect(payload.hookSpecificOutput.permissionDecision).toBe("ask");
  });

  it("allows when the option is on", () => {
    const result = runGuard("git push origin main", "push", "TEST_OPT", { TEST_OPT: "true" });
    const payload = JSON.parse(result.stdout);
    expect(payload.hookSpecificOutput.permissionDecision).toBe("allow");
  });

  it("produces no output for a multiline docker command", () => {
    const command =
      'docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/app -w /app ' +
      "ghcr.io/carthage-software/mago:1.47.4 lint \\\n" +
      "  libraries/Efront/Domain/JobDispatch/JobSettlementService.php \\\n" +
      "  tests/Integration/Domain/JobDispatch/JobSettlementServiceTest.php " +
      "2>&1 | tail -40";
    let result = runGuard(command, "push");
    expect(result.stdout.trim()).toBe("");
    result = runGuard(command, "commit");
    expect(result.stdout.trim()).toBe("");
  });
});
