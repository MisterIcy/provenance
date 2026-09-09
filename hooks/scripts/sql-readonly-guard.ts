#!/usr/bin/env bun
// PreToolUse gate for DB CLI calls (mysql/psql/sqlite3) made by the
// sql-query-reviewer agent. The agent's Bash(mysql *)/Bash(psql *)/
// Bash(sqlite3 *) tool-permission patterns only restrict by binary name —
// they cannot see inside a `-e "..."` / `-c "..."` argument, so a command
// like `mysql -e "DELETE FROM ..."` would otherwise still match the
// allowlist. This hook inspects the actual command string and blocks it if
// it contains a mutating or DDL/DCL keyword; legitimate read-only calls fall
// through untouched so normal permission-mode behavior still applies.
//
// Heuristic, not a substitute for a read-only DB credential: keyword
// matching cannot catch every way to construct a mutating statement. It
// deliberately only ever runs on strings that hooks.json has already
// confirmed start with `mysql`/`psql`/`sqlite3` — it does not itself verify
// that, so it should not be reused behind a broader-matching hook as-is.
//
// A first version matched these keywords anywhere in the *raw* command
// string. That is blunt: a bare keyword can legitimately show up inside a
// quoted SQL string literal (`WHERE status = 'set'`), a backtick-quoted
// identifier, or a `--`/`/* */` comment, or in a shell command chained via
// `&&`/`;` that isn't even the same SQL statement. To cut those false
// positives down, this version:
//   1. Tokenizes the command like a shell would and splits it into segments
//      on `;`/`&&`/`||`/`|`/newlines (reusing git-guard.ts's tokenizer, which
//      handles quotes spanning multiple physical lines in one pass), so only
//      segments that actually invoke mysql/psql/sqlite3 are inspected.
//   2. Extracts just the argument(s) that plausibly carry SQL text — the
//      value of -e/--execute/-c/--command/-cmd always does; a bare
//      (non-flag) positional argument only does for sqlite3's second
//      positional (`sqlite3 DBFILE "SQL"` — the first positional is the db
//      file, never SQL text) and never for mysql/psql (whose bare positional
//      is a database name, not SQL) — rather than the whole segment, so an
//      unrelated flag value, a database/file name, or a chained shell
//      command's own text is never in scope.
//   3. Masks out single/double-quoted string literals, backtick-quoted
//      identifiers, and `--`/`/* */` comments before matching keywords, so a
//      keyword-shaped value/identifier/comment doesn't trip the guard.
//   4. Requires most keywords to appear at the start of a (semicolon
//      -delimited) statement, since they're normally SQL statement-leading
//      keywords (`DELETE FROM`, `CALL proc()`, `SET x=y`, ...) — this avoids
//      flagging identifiers like a bare `AS call` column alias. `INTO` is the
//      one exception kept as an anywhere-in-statement match, since it's
//      legitimately a mid-statement clause (`INSERT INTO`, `SELECT ... INTO
//      OUTFILE`) rather than ever a leading keyword itself.
//   5. Recognizes a heredoc (`<<DELIM` / `<<-DELIM` / `<<'DELIM'`) fed to a
//      mysql/psql/sqlite3 invocation and scans its body as SQL text too —
//      that body is the actual SQL sent to the tool's stdin, so skipping it
//      would let a real mutating statement slip through untouched. The body
//      is also blanked out of the ordinary segment scan so its lines aren't
//      independently misread as top-level shell commands.
// If the command still fails to tokenize (e.g. genuinely unbalanced quotes),
// this falls back to the original blunt whole-string keyword scan —
// conservative, so the gate still asks rather than silently allowing on
// unparseable input.
import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { splitSegments, joinLineContinuations } from "./git-guard.ts";

const SQL_BINARIES = new Set(["mysql", "psql", "sqlite3"]);

const LEADING_KEYWORDS = [
  "insert", "update", "delete", "drop", "alter", "truncate", "create",
  "grant", "revoke", "replace", "merge", "call", "exec", "execute", "lock",
  "unlock", "vacuum", "reindex", "attach", "detach", "pragma", "begin",
  "commit", "rollback", "savepoint", "set", "copy",
];
const LEADING_KEYWORDS_RE = new RegExp(`^\\s*(?:${LEADING_KEYWORDS.join("|")})\\b`, "i");
const INTO_RE = /\binto\b/i;

// Whole-string fallback used only when the command fails to tokenize.
const MUTATING_KEYWORDS = new RegExp(
  `\\b(?:${[...LEADING_KEYWORDS, "into"].join("|")})\\b`,
  "i",
);

const SQL_VALUE_FLAGS = new Set(["-e", "--execute", "-c", "--command", "-cmd", "--cmd"]);
const OTHER_VALUE_FLAGS = new Set([
  "-h", "--host", "-u", "--user", "-P", "--port", "-D", "--database",
  "--dbname", "-S", "--socket", "--defaults-file", "--defaults-extra-file",
  "-U", "--username", "-d", "-p", "--password", "-f", "--file", "-o", "--output",
]);

function extractSqlCandidates(binary: string, tokens: string[]): string[] {
  const candidates: string[] = [];
  let positionalCount = 0;
  for (let i = 1; i < tokens.length; i++) {
    const tok = tokens[i];
    if (SQL_VALUE_FLAGS.has(tok)) {
      if (i + 1 < tokens.length) candidates.push(tokens[i + 1]);
      i++;
      continue;
    }
    const eqMatch = tok.match(/^(--execute|--command)=([\s\S]*)$/);
    if (eqMatch) {
      candidates.push(eqMatch[2]);
      continue;
    }
    if (OTHER_VALUE_FLAGS.has(tok)) {
      i++;
      continue;
    }
    if (tok.startsWith("-")) continue;

    // Bare positional argument. mysql/psql's positional is a database name,
    // never SQL text. sqlite3's usage is `sqlite3 [opts] DBFILE [SQL]` — only
    // the second positional onward can be a SQL statement.
    positionalCount++;
    if (binary === "sqlite3" && positionalCount > 1) {
      candidates.push(tok);
    }
  }
  return candidates;
}

function maskNonKeywordRegions(sql: string): string {
  const blank = (m: string) => " ".repeat(m.length);
  return sql
    .replace(/'(?:[^'\\]|\\.|'')*'/g, blank)
    .replace(/"(?:[^"\\]|\\.)*"/g, blank)
    .replace(/`[^`]*`/g, blank)
    .replace(/--[^\n]*/g, blank)
    .replace(/\/\*[\s\S]*?\*\//g, blank);
}

export function sqlLooksMutating(sql: string): boolean {
  const masked = maskNonKeywordRegions(sql);
  if (INTO_RE.test(masked)) return true;
  return masked.split(";").some((statement) => LEADING_KEYWORDS_RE.test(statement));
}

function denyOutput(): string {
  return JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason:
        "Blocked: command appears to contain a mutating SQL statement or DDL/DCL keyword. sql-query-reviewer is read-only — only SELECT/EXPLAIN/SHOW/DESCRIBE-style queries are permitted.",
    },
  });
}

const HEREDOC_RE = /<<-?\s*(?:(['"])([\s\S]*?)\1|([A-Za-z_]\w*))/;

// Finds `<<DELIM` (or `<<-DELIM`/`<<'DELIM'`) heredocs in a (line-
// continuation-joined) command string. Returns the command string with each
// heredoc's body+delimiter lines blanked out (so the generic segment scan
// below never treats heredoc body lines as their own top-level commands),
// plus the body text of any heredoc whose introducing line invokes
// mysql/psql/sqlite3 — that text is the real SQL sent to the tool and must
// still be checked.
function extractHeredocs(commandStr: string): { stripped: string; sqlBodies: string[] } {
  const lines = commandStr.split("\n");
  const outputLines: string[] = [];
  const sqlBodies: string[] = [];
  let i = 0;

  while (i < lines.length) {
    const line = lines[i];
    const match = line.match(HEREDOC_RE);
    if (!match) {
      outputLines.push(line);
      i++;
      continue;
    }

    const delimiter = (match[2] ?? match[3] ?? "").trim();
    if (!delimiter) {
      outputLines.push(line);
      i++;
      continue;
    }

    let isSqlInvocation = false;
    try {
      const prefix = line.slice(0, match.index);
      for (const segment of splitSegments(prefix)) {
        if (segment.length && SQL_BINARIES.has(path.basename(segment[0]))) {
          isSqlInvocation = true;
        }
      }
    } catch {
      // Unparseable prefix - conservatively assume it's not a SQL
      // invocation; the body is still blanked out of the generic scan below
      // either way, so this can't silently allow anything through.
    }

    outputLines.push(line); // keep the introducing line for the normal scan
    i++;

    const bodyLines: string[] = [];
    while (i < lines.length && lines[i].trim() !== delimiter) {
      bodyLines.push(lines[i]);
      outputLines.push("");
      i++;
    }
    if (i < lines.length) {
      outputLines.push(""); // blank the delimiter line too
      i++;
    }

    if (isSqlInvocation) sqlBodies.push(bodyLines.join("\n"));
  }

  return { stripped: outputLines.join("\n"), sqlBodies };
}

export function checkCommand(commandStr: string): string | null {
  if (!commandStr) return null;

  const joined = joinLineContinuations(commandStr);
  const { stripped, sqlBodies } = extractHeredocs(joined);

  for (const body of sqlBodies) {
    if (sqlLooksMutating(body)) return denyOutput();
  }

  let segments: string[][];
  try {
    segments = [...splitSegments(stripped)];
  } catch {
    // Unbalanced quotes etc. - fall back to the blunt whole-string scan so
    // the gate still asks rather than silently allowing.
    return MUTATING_KEYWORDS.test(commandStr) ? denyOutput() : null;
  }
  for (const segment of segments) {
    if (segment.length === 0) continue;
    const binary = path.basename(segment[0]);
    if (!SQL_BINARIES.has(binary)) continue;
    for (const candidate of extractSqlCandidates(binary, segment)) {
      if (sqlLooksMutating(candidate)) return denyOutput();
    }
  }
  return null;
}

function main(): number {
  let commandStr = "";
  try {
    const raw = readFileSync(0, "utf8");
    const payload = JSON.parse(raw);
    commandStr = payload?.tool_input?.command ?? "";
  } catch {
    return 0;
  }

  const output = checkCommand(typeof commandStr === "string" ? commandStr : "");
  if (output) console.log(output);
  return 0;
}

const isMain = process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);
if (isMain) {
  process.exit(main());
}
