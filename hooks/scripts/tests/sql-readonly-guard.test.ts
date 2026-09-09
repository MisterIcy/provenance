import { describe, expect, it } from "vitest";
import { checkCommand, sqlLooksMutating } from "../sql-readonly-guard.ts";

const MUTATING_KEYWORDS = [
  "insert", "update", "delete", "drop", "alter", "truncate", "create",
  "grant", "revoke", "replace", "merge", "call", "exec", "execute", "lock",
  "unlock", "vacuum", "reindex", "attach", "detach", "pragma", "begin",
  "commit", "rollback", "savepoint", "set", "copy", "into",
];

function isDenied(output: string | null): boolean {
  if (!output) return false;
  return JSON.parse(output).hookSpecificOutput.permissionDecision === "deny";
}

describe("checkCommand — baseline keyword coverage", () => {
  it.each(MUTATING_KEYWORDS)("blocks a leading %s statement", (keyword) => {
    const output = checkCommand(`mysql -e "${keyword.toUpperCase()} something"`);
    expect(isDenied(output)).toBe(true);
  });

  it("allows a plain SELECT", () => {
    expect(checkCommand('mysql -e "SELECT * FROM users"')).toBeNull();
  });

  it("allows EXPLAIN", () => {
    expect(checkCommand('mysql -e "EXPLAIN SELECT 1"')).toBeNull();
  });

  it("allows SHOW", () => {
    expect(checkCommand('psql -c "SHOW tables"')).toBeNull();
  });

  it("allows DESCRIBE", () => {
    expect(checkCommand('mysql -e "DESCRIBE users"')).toBeNull();
  });

  it("returns null for an empty command", () => {
    expect(checkCommand("")).toBeNull();
  });
});

// Adversarial cases surfaced by a dedicated red-team pass over this guard
// (see the git history / PR description for the full report). Each of these
// is reachable in production today, since hooks.json only ever routes
// commands starting with mysql/psql/sqlite3 to this guard.
describe("checkCommand — false-positive regressions (legitimate reads must pass through)", () => {
  it("does not block a string literal value equal to a keyword ('set')", () => {
    expect(checkCommand(`mysql -e "SELECT * FROM users WHERE status = 'set'"`)).toBeNull();
  });

  it("does not block a LIKE literal containing 'into' as a substring", () => {
    expect(
      checkCommand(`mysql -e "SELECT * FROM orders WHERE note LIKE '%into archive%'"`),
    ).toBeNull();
  });

  it("does not block a string literal value equal to a keyword ('copy')", () => {
    expect(checkCommand(`psql -c "SELECT * FROM t WHERE tag = 'copy'"`)).toBeNull();
  });

  it("does not block a backtick-quoted identifier equal to a keyword", () => {
    expect(checkCommand("mysql -e \"SELECT `set` FROM config\"")).toBeNull();
  });

  it("does not block a keyword appearing only inside a SQL line comment", () => {
    expect(checkCommand('mysql -e "SELECT 1 -- please dont delete this row"')).toBeNull();
  });

  it("does not block a keyword-shaped substring with no word boundary (set2)", () => {
    expect(checkCommand('mysql -e "SELECT set2 FROM x"')).toBeNull();
  });

  it("does not block a keyword-shaped substring with no word boundary (2set)", () => {
    expect(checkCommand('mysql -e "SELECT 2set FROM x"')).toBeNull();
  });

  it("does not block an identifier containing a keyword as a substring (settings)", () => {
    expect(checkCommand('mysql -e "SELECT settings FROM config"')).toBeNull();
  });

  it("does not block an identifier containing a keyword as a substring (userscopy)", () => {
    expect(checkCommand('mysql -e "SELECT userscopy FROM x"')).toBeNull();
  });

  it("does not block a hyphenated literal value containing a keyword ('my-set-value')", () => {
    expect(checkCommand(`mysql -e "SELECT * FROM t WHERE k='my-set-value'"`)).toBeNull();
  });

  it("does not block an unrelated &&-chained shell command that merely mentions a keyword", () => {
    expect(checkCommand('mysql -e "SELECT 1" && echo "will not delete anything"')).toBeNull();
  });

  it("does not block a bare column alias equal to a keyword (AS call)", () => {
    expect(checkCommand('mysql -e "SELECT 1 AS call"')).toBeNull();
  });

  it("does not block a string literal value equal to a keyword ('grant')", () => {
    expect(checkCommand(`mysql -e "SELECT * FROM t WHERE role = 'grant'"`)).toBeNull();
  });

  it("does not block a string literal value equal to a keyword ('lock')", () => {
    expect(checkCommand(`mysql -e "SELECT * FROM t WHERE state = 'lock'"`)).toBeNull();
  });

  it("does not block a keyword appearing only inside a SQL line comment (execute)", () => {
    expect(checkCommand('mysql -e "SELECT 1 -- do not execute anything else"')).toBeNull();
  });

  it("does not block a sqlite3 literal equal to a keyword ('table')", () => {
    expect(
      checkCommand(`sqlite3 mydb.db "SELECT * FROM sqlite_master WHERE type='table'"`),
    ).toBeNull();
  });

  it("does not block an identifier with no word boundary (recall_count)", () => {
    expect(checkCommand('mysql -e "SELECT recall_count FROM metrics"')).toBeNull();
  });
});

describe("checkCommand — true positives still caught (no detection regressions)", () => {
  it("blocks INTO OUTFILE as a mid-statement clause", () => {
    expect(isDenied(checkCommand(`mysql -e "SELECT * FROM t INTO OUTFILE '/tmp/x.csv'"`))).toBe(true);
  });

  it("blocks SELECT ... INTO @var", () => {
    expect(isDenied(checkCommand('mysql -e "SELECT id INTO @v FROM t LIMIT 1"'))).toBe(true);
  });

  it("blocks a real DELETE", () => {
    expect(isDenied(checkCommand('mysql -e "DELETE FROM users"'))).toBe(true);
  });

  it("blocks a real TRUNCATE", () => {
    expect(isDenied(checkCommand('psql -c "TRUNCATE orders"'))).toBe(true);
  });

  it("blocks a lowercase real delete", () => {
    expect(isDenied(checkCommand('mysql -e "delete from users"'))).toBe(true);
  });

  it("blocks when a second &&-chained invocation is the mutating one", () => {
    expect(
      isDenied(checkCommand('mysql -e "SELECT * FROM t1" && mysql -e "DELETE FROM t2"')),
    ).toBe(true);
  });

  it("blocks a real SET statement", () => {
    expect(isDenied(checkCommand("mysql -e \"SET SESSION sql_mode=''\""))).toBe(true);
  });

  it("blocks a real PRAGMA statement", () => {
    expect(isDenied(checkCommand('sqlite3 mydb.db "PRAGMA journal_mode=WAL"'))).toBe(true);
  });

  it("blocks a multiline composite command with a real mutating statement buried among safe queries", () => {
    const command = [
      'mysql -e "SELECT 1"',
      'mysql -e "SELECT 2"',
      'mysql -e "DELETE FROM audit_log WHERE id=1"',
    ].join("\n");
    expect(isDenied(checkCommand(command))).toBe(true);
  });

  it("blocks a mutating statement following a semicolon within one -e argument", () => {
    expect(isDenied(checkCommand('mysql -e "SELECT 1; DELETE FROM x"'))).toBe(true);
  });
});

describe("checkCommand — non-SQL commands (matcher-layer dependency, documented risk)", () => {
  it("does not touch a git commit message mentioning a keyword (not a SQL binary)", () => {
    expect(checkCommand('git commit -m "delete old feature flag"')).toBeNull();
  });

  it("does not touch a docker build log line mentioning a keyword (not a SQL binary)", () => {
    expect(
      checkCommand('docker build -t app . && echo "log: truncate old data at start"'),
    ).toBeNull();
  });
});

describe("sqlLooksMutating (unit-level)", () => {
  it("ignores masked string literals", () => {
    expect(sqlLooksMutating("SELECT * FROM t WHERE x = 'delete'")).toBe(false);
  });

  it("still matches a real leading keyword", () => {
    expect(sqlLooksMutating("DELETE FROM t")).toBe(true);
  });

  it("matches INTO anywhere in the statement", () => {
    expect(sqlLooksMutating("SELECT * INTO OUTFILE 'x'")).toBe(true);
  });
});
