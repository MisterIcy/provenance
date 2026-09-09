import { describe, expect, it } from "vitest";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { commandInvokes, stripHeredocs } from "../git-guard.ts";

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

// Heredoc bodies are inert data in real bash — never parsed as shell syntax
// — so stripHeredocs() removes them before tokenizing, and commandInvokes
// must not be fooled by their contents either way (a literal "git push" in
// the body isn't a real invocation, and stray punctuation in the body must
// not corrupt parsing of the real command around it).
describe("commandInvokes — heredoc bodies are inert", () => {
  it("does not match literal 'git push' text inside a heredoc body", () => {
    const command = "cat <<'EOF' > msg.txt\ngit push\nEOF";
    expect(commandInvokes(command, "push")).toBe(false);
    expect(commandInvokes(command, "commit")).toBe(false);
  });

  it("does not treat an apostrophe inside a heredoc body as an unbalanced quote", () => {
    // Regression: a code comment like "let's" inside a heredoc used to throw
    // TokenizeError (unmatched "'"), which commandInvokes conservatively
    // treated as a match for every subcommand — turning an unrelated `cat`
    // + `node` script into a false "git push"/"git commit" approval prompt.
    const command =
      "cat <<'EOF' > /tmp/tdz_test.mjs\n" +
      "// factory created BEFORE const is initialized... but let's mimic real hoisting\n" +
      "console.log('done');\n" +
      "EOF\n" +
      "node /tmp/tdz_test.mjs";
    expect(commandInvokes(command, "push")).toBe(false);
    expect(commandInvokes(command, "commit")).toBe(false);
  });

  it("does not let heredoc body punctuation (parens, pipes, backticks) leak into parsing", () => {
    const command =
      "cat <<'EOF' > /tmp/x.js\n" +
      "const fn = (...args) => `${args | 0}`;\n" +
      "EOF\n" +
      "git status";
    expect(commandInvokes(command, "push")).toBe(false);
    expect(commandInvokes(command, "commit")).toBe(false);
  });

  it("still detects a real git push/commit that follows a heredoc", () => {
    const command = "cat <<'EOF' > msg.txt\nsome body text\nEOF\ngit push origin main";
    expect(commandInvokes(command, "push")).toBe(true);
  });

  it("still detects a real git push/commit that precedes a heredoc", () => {
    const command = "git commit -F- <<'EOF'\nsome body text\nEOF";
    expect(commandInvokes(command, "commit")).toBe(true);
  });

  it("supports the <<- form with tab-indented closing delimiter", () => {
    const command = "cat <<-'EOF'\n\tgit push\n\tEOF\nnode script.js";
    expect(commandInvokes(command, "push")).toBe(false);
  });

  it("supports an unquoted heredoc delimiter", () => {
    const command = "cat <<EOF\ngit push\nEOF";
    expect(commandInvokes(command, "push")).toBe(false);
  });
});

describe("stripHeredocs", () => {
  it("removes a quoted-delimiter heredoc body, including the closing delimiter line", () => {
    expect(stripHeredocs("cat <<'EOF'\nline one\nline two\nEOF")).toBe("cat <<'EOF'");
  });

  it("removes an unquoted-delimiter heredoc body", () => {
    expect(stripHeredocs("cat <<EOF\nline one\nEOF")).toBe("cat <<EOF");
  });

  it("respects <<- tab-stripping when matching the closing delimiter", () => {
    expect(stripHeredocs("cat <<-'EOF'\nbody\n\tEOF")).toBe("cat <<-'EOF'");
  });

  it("leaves non-heredoc content untouched", () => {
    expect(stripHeredocs("git push origin main")).toBe("git push origin main");
  });

  it("leaves content after the closing delimiter untouched", () => {
    expect(stripHeredocs("cat <<'EOF'\nbody\nEOF\ngit push")).toBe("cat <<'EOF'\ngit push");
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
