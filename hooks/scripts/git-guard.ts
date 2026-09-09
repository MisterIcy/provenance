#!/usr/bin/env bun
// Shared PreToolUse gate for `git commit` / `git push`.
//
// Reads the hook payload from stdin, tokenizes tool_input.command (handling
// compound commands, quoting, and git global options like -C/-c), and decides
// whether it invokes the given git subcommand. Fails open (exits 0, no
// output, letting the normal permission flow apply) on a malformed/missing
// payload instead of crashing the hook and blocking unrelated Bash calls. A
// command string that itself fails to tokenize (e.g. unbalanced quotes) is
// treated as a match instead, so the gate still asks rather than silently
// allowing.
//
// Usage: git-guard.ts <subcommand> <PLUGIN_OPTION_ENV_VAR>
import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ENV_ASSIGNMENT = /^[A-Za-z_][A-Za-z0-9_]*=/;
const CONTROL_OPERATORS = new Set([";", "&", "&&", "||", "|", "(", ")", "`", "\n"]);
const GLOBAL_OPTS_WITH_ARG = new Set([
  "-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path",
  "--super-prefix", "--config-env",
]);

class TokenizeError extends Error {}

// A small posix-shell-like tokenizer: handles single/double quotes and
// backslash escapes, and splits on the punctuation characters used below as
// control operators. Raises TokenizeError on unbalanced quotes, mirroring
// Python's shlex.shlex ValueError behavior.
function tokenize(line: string): string[] {
  const tokens: string[] = [];
  let current: string | null = null;
  let i = 0;
  const n = line.length;

  // "`" is treated as a control operator (like the parens of a $(...)
  // subshell) so that a backtick command substitution such as `` `git
  // push` `` isolates "git push" as its own segment instead of gluing the
  // backticks onto the adjacent tokens.
  const isPunct = (ch: string) => "();<>|&`".includes(ch);
  const isWhitespace = (ch: string) => ch === " " || ch === "\t";

  while (i < n) {
    const ch = line[i];
    if (ch === "\n") {
      // An unquoted newline ends the current command the same way ";" does
      // (a real shell reads it as a statement separator). Quoted content
      // spanning multiple physical lines never reaches this branch — the
      // quote-consuming loops above read raw characters, newlines included,
      // until the matching closing quote. Emitting it as its own control-
      // operator token (rather than treating it as inert whitespace) lets
      // callers feed the whole multi-line command through tokenize() in one
      // pass instead of pre-splitting on "\n", which used to break a quoted
      // argument that legitimately spans multiple lines.
      if (current !== null) {
        tokens.push(current);
        current = null;
      }
      tokens.push("\n");
      i++;
      continue;
    }
    if (isWhitespace(ch)) {
      if (current !== null) {
        tokens.push(current);
        current = null;
      }
      i++;
      continue;
    }
    // $'...' (ANSI-C quoting) and $"..." (locale-translated quoting) both
    // dequote to their literal content for our purposes, same as '...'/"...".
    // Skip the "$" and let the normal quote handling below consume the rest.
    if (ch === "$" && (line[i + 1] === "'" || line[i + 1] === '"')) {
      i++;
      continue;
    }
    if (ch === "'") {
      current = current ?? "";
      const end = line.indexOf("'", i + 1);
      if (end === -1) throw new TokenizeError("unbalanced single quote");
      current += line.slice(i + 1, end);
      i = end + 1;
      continue;
    }
    if (ch === '"') {
      current = current ?? "";
      let j = i + 1;
      let buf = "";
      let closed = false;
      while (j < n) {
        const c = line[j];
        if (c === '\\' && j + 1 < n && '"\\$`'.includes(line[j + 1])) {
          buf += line[j + 1];
          j += 2;
          continue;
        }
        if (c === '"') {
          closed = true;
          j++;
          break;
        }
        buf += c;
        j++;
      }
      if (!closed) throw new TokenizeError("unbalanced double quote");
      current += buf;
      i = j;
      continue;
    }
    if (ch === "\\") {
      if (i + 1 >= n) throw new TokenizeError("trailing backslash");
      current = current ?? "";
      current += line[i + 1];
      i += 2;
      continue;
    }
    if (isPunct(ch)) {
      if (current !== null) {
        tokens.push(current);
        current = null;
      }
      // Greedily match two-char operators (&&, ||)
      if ((ch === "&" || ch === "|") && line[i + 1] === ch) {
        tokens.push(ch + ch);
        i += 2;
      } else {
        tokens.push(ch);
        i += 1;
      }
      continue;
    }
    current = current ?? "";
    current += ch;
    i++;
  }
  if (current !== null) tokens.push(current);
  return tokens;
}

export function* splitSegments(line: string): Generator<string[]> {
  const tokens = tokenize(line);
  let segment: string[] = [];
  for (const token of tokens) {
    if (CONTROL_OPERATORS.has(token) || token === "<" || token === ">") {
      if (segment.length) yield segment;
      segment = [];
    } else {
      segment.push(token);
    }
  }
  if (segment.length) yield segment;
}

export function findSubcommand(tokens: string[]): string | null {
  let i = 0;
  const n = tokens.length;
  while (i < n && ENV_ASSIGNMENT.test(tokens[i])) {
    i++;
  }
  if (i >= n || path.basename(tokens[i]) !== "git") {
    return null;
  }
  i++;
  while (i < n) {
    const tok = tokens[i];
    if (tok === "--") {
      i++;
      break;
    }
    if (GLOBAL_OPTS_WITH_ARG.has(tok)) {
      i += 2;
      continue;
    }
    if (tok.startsWith("-") && tok !== "-") {
      i++;
      continue;
    }
    break;
  }
  return i < n ? tokens[i] : null;
}

export function joinLineContinuations(commandStr: string): string {
  // Bash honors a trailing "\" as a line continuation; splitting on raw
  // newlines without collapsing these first hands the tokenizer a dangling
  // escape on the truncated line, which throws and gets treated as a match
  // for every subcommand check (see commandInvokes below).
  return commandStr.replace(/\\\n/g, "");
}

export function commandInvokes(commandStr: string, subcommand: string): boolean {
  let segments: string[][];
  try {
    segments = [...splitSegments(joinLineContinuations(commandStr))];
  } catch {
    // Unbalanced quotes etc. - be conservative and treat as a match so the
    // gate still asks rather than silently allowing.
    return true;
  }
  for (const segment of segments) {
    if (findSubcommand(segment) === subcommand) return true;
  }
  return false;
}

function main(): number {
  if (process.argv.length !== 4) return 0;
  const subcommand = process.argv[2];
  const optionEnvVar = process.argv[3];

  let commandStr: unknown;
  try {
    const raw = readFileSync(0, "utf8");
    const payload = JSON.parse(raw);
    commandStr = payload?.tool_input?.command ?? "";
  } catch {
    return 0;
  }

  if (!commandStr || typeof commandStr !== "string") return 0;

  let matched: boolean;
  try {
    matched = commandInvokes(commandStr, subcommand);
  } catch {
    matched = true; // fail closed on the tokenizer, not on the payload
  }

  if (!matched) return 0;

  const plural: Record<string, string> = { commit: "commits", push: "pushes" };
  const pluralWord = plural[subcommand] ?? `${subcommand}s`;

  let decision: string;
  let reason: string;
  if (process.env[optionEnvVar] === "true") {
    decision = "allow";
    reason = `${optionEnvVar} is enabled`;
  } else {
    decision = "ask";
    reason = `${optionEnvVar} is off — ${pluralWord} require explicit approval`;
  }

  console.log(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: decision,
      permissionDecisionReason: reason,
    },
  }));
  return 0;
}

const isMain = process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);
if (isMain) {
  process.exit(main());
}
