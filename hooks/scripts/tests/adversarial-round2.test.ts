import { describe, expect, it } from "vitest";
import { checkCommand, sqlLooksMutating } from "../sql-readonly-guard.ts";
import { commandInvokes } from "../git-guard.ts";

// Round 2 adversarial pass. Every assertion below encodes what a real shell /
// real SQL engine would actually do with the command, independent of what
// the guard returns — ground truth, not "whatever the code currently does".
// This pass originally found 8 confirmed bugs (6 false positives from
// bare-positional dbname/filename handling and one multiline-quote parsing
// gap, plus 2 false negatives: a heredoc-fed mutating statement and a git
// global option not in the known-values list) — all since fixed in
// sql-readonly-guard.ts (binary-aware positional extraction, unified
// whole-string tokenization, heredoc body attribution) and git-guard.ts
// (added --super-prefix/--config-env). Every case below now passes; this
// file stays as the regression suite proving it.

function isDenied(output: string | null): boolean {
  if (!output) return false;
  return JSON.parse(output).hookSpecificOutput.permissionDecision === "deny";
}

// ---------------------------------------------------------------------------
// SQL guard (sql-readonly-guard.ts)
// ---------------------------------------------------------------------------

describe("SQL guard — bare positional dbname/filename mistaken for SQL text", () => {
  // mysql's and psql's bare positional argument (when not preceded by
  // -D/--dbname/--database) is the DATABASE NAME to connect to, not SQL text.
  // extractSqlCandidates treats every bare positional as a SQL candidate,
  // so a database literally named after a leading keyword trips the guard
  // even though no SQL statement of any kind is present.
  it("does not block connecting to a database literally named 'call'", () => {
    expect(checkCommand('mysql call -e "SELECT 1"')).toBeNull();
  });

  it("does not block connecting to a database literally named 'copy'", () => {
    expect(checkCommand('mysql copy -e "SELECT 1"')).toBeNull();
  });

  it("does not block connecting to a psql database literally named 'commit'", () => {
    expect(checkCommand('psql commit -c "SELECT 1"')).toBeNull();
  });

  // sqlite3's bare positional is the DB FILE PATH. Merely opening a file
  // (no query at all) can never be "mutating SQL" — there is no statement.
  it("does not block merely opening a sqlite3 file named copy.db (no query at all)", () => {
    expect(checkCommand("sqlite3 copy.db")).toBeNull();
  });

  it("does not block opening set.db and running a harmless dot-command", () => {
    expect(checkCommand('sqlite3 set.db ".tables"')).toBeNull();
  });

  // Contrast case: a filename containing a keyword as a *prefix* with a
  // trailing underscore-joined word is NOT an exact keyword match (no word
  // boundary after "drop"+"_"), so this one is correctly safe either way.
  it("does not block a filename that merely starts with a keyword-like prefix (drop_table_backups.db)", () => {
    expect(checkCommand('sqlite3 drop_table_backups.db "SELECT 1"')).toBeNull();
  });
});

describe("SQL guard — value-taking flags correctly shield their value (no false positive)", () => {
  it("does not block -D with a keyword-named database (flag correctly consumes its value)", () => {
    expect(checkCommand('mysql -D copy -e "SELECT 1"')).toBeNull();
  });

  it("does not block -f with a keyword-named script file (filename, not SQL text)", () => {
    expect(checkCommand('mysql -f delete_migration.sql -e "SELECT 1"')).toBeNull();
  });

  it("does not block -h with a keyword-prefixed hostname", () => {
    expect(checkCommand('mysql -h setdb.internal.example.com -e "SELECT 1"')).toBeNull();
  });

  it("does not block a long --flag=value form even with a keyword-ish path", () => {
    expect(checkCommand("mysql --defaults-extra-file=/etc/mysql/set.cnf -e \"SELECT 1\"")).toBeNull();
  });
});

describe("SQL guard — escaping/quoting edge cases (ground-truth SQL semantics)", () => {
  it("does not block a doubled-single-quote apostrophe literal containing 'into' as a substring", () => {
    // Real SQL: 'It''s time to look into things' is one properly-escaped
    // string literal (doubled '' = literal apostrophe). The whole thing is
    // a read-only SELECT with no actual INTO clause.
    expect(
      checkCommand(`mysql -e "SELECT * FROM t WHERE note = 'It''s time to look into things'"`),
    ).toBeNull();
  });

  it("does not block a backslash-escaped Windows path literal containing 'into' as a path segment", () => {
    expect(
      checkCommand(
        String.raw`mysql -e "SELECT * FROM t WHERE path = 'C:\\Users\\into\\docs'"`,
      ),
    ).toBeNull();
  });

  it("does not block a double-quoted SQL string literal with backslash-escaped inner quotes", () => {
    expect(
      checkCommand(
        String.raw`mysql -e 'SELECT * FROM t WHERE note = "he said \"stop this\""'`,
      ),
    ).toBeNull();
  });

  it("does not block backtick-quoted identifiers that are themselves two different keywords", () => {
    expect(checkCommand('mysql -e "SELECT `call`, `set` FROM tickets"')).toBeNull();
  });
});

describe("SQL guard — legitimate read-only query shapes", () => {
  it("does not block a CTE whose name is keyword-prefixed (WITH delete_candidates AS ...)", () => {
    expect(
      checkCommand(
        'mysql -e "WITH delete_candidates AS (SELECT id FROM t WHERE flag=1) SELECT * FROM delete_candidates"',
      ),
    ).toBeNull();
  });

  it("does not block a window-function query (OVER/PARTITION BY)", () => {
    expect(
      checkCommand(
        'mysql -e "SELECT *, ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) AS rn FROM employees"',
      ),
    ).toBeNull();
  });

  it("does not block two chained read-only statements in one -e argument", () => {
    expect(checkCommand('mysql -e "SELECT 1; SELECT 2"')).toBeNull();
  });
});

describe("SQL guard — false NEGATIVES (high severity: real mutating SQL must not slip through)", () => {
  it("catches a real DELETE fed to psql via a heredoc body", () => {
    // Ground truth: this genuinely deletes every row in x. Fixed via
    // extractHeredocs(), which attributes the heredoc body to the preceding
    // "psql ... <<SQL" invocation and scans it as SQL text.
    const command = "psql -h localhost mydb <<SQL\nDELETE FROM x;\nSQL";
    expect(isDenied(checkCommand(command))).toBe(true);
  });
});

describe("SQL guard — multi-line -e argument (quoted string spanning physical lines)", () => {
  it("does not block a legitimate multi-line SELECT whose string literal happens to contain 'delete'", () => {
    // Ground truth: this is a plain, harmless SELECT. The literal
    // 'do not delete this' is just string data. Fixed by unifying
    // tokenization over the whole command string in one pass (git-guard.ts's
    // tokenizer now treats a bare newline as a statement separator token
    // instead of the caller pre-splitting on "\n"), so a quoted argument
    // that spans physical lines no longer breaks tokenization.
    const command = [
      'mysql -e "SELECT *',
      "FROM orders",
      "WHERE note = 'do not delete this'\"",
    ].join("\n");
    expect(checkCommand(command)).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// Git guard (git-guard.ts)
// ---------------------------------------------------------------------------

describe("git guard — real subcommands that merely resemble push/commit", () => {
  it("does not treat 'git stash push' as a remote push", () => {
    // Ground truth: git stash push stashes local changes; it never contacts
    // a remote and is not `git push`.
    expect(commandInvokes("git stash push", "push")).toBe(false);
  });

  it("does not treat 'git commit-graph write' as a commit", () => {
    // Ground truth: commit-graph is a distinct real git subcommand (commit
    // graph file maintenance); it creates no commit.
    expect(commandInvokes("git commit-graph write", "commit")).toBe(false);
  });

  it("does not treat a custom script named git-helper.sh as the real git binary", () => {
    expect(commandInvokes("./scripts/git-helper.sh push origin", "push")).toBe(false);
  });

  it("does not treat 'git diff | grep push' as a push (the word is grep's search term)", () => {
    expect(commandInvokes("git diff | grep push", "push")).toBe(false);
  });
});

describe("git guard — unusual but valid quoting", () => {
  it("does not split on a semicolon that is inside a quoted -C path value", () => {
    // Ground truth: real bash treats the whole quoted string as one -C
    // argument; the embedded ';' is literal data, not a command separator.
    // This is a single `git status` invocation, not push/commit.
    expect(commandInvokes('git -C "repo;rm -rf /" status', "push")).toBe(false);
    expect(commandInvokes('git -C "repo;rm -rf /" status', "commit")).toBe(false);
  });

  it("handles a -C path containing spaces", () => {
    expect(commandInvokes('git -C "path with spaces/repo" status', "push")).toBe(false);
    expect(commandInvokes('git -C "path with spaces/repo" status', "commit")).toBe(false);
  });

  it("handles a -c global option with a complex quoted value before a real push", () => {
    expect(
      commandInvokes(
        'git -c http.extraHeader="AUTHORIZATION: bearer TOKEN123" push origin main',
        "push",
      ),
    ).toBe(true);
  });

  it("handles --namespace=value (equals form) before a real push", () => {
    expect(commandInvokes("git --namespace=refs/foo push", "push")).toBe(true);
  });
});

describe("git guard — process substitution and arithmetic expansion", () => {
  it("does not mistake git show inside process substitution for push/commit", () => {
    const command = "diff <(git show HEAD:file.txt) <(cat other.txt)";
    expect(commandInvokes(command, "push")).toBe(false);
    expect(commandInvokes(command, "commit")).toBe(false);
  });

  it("does not mistake arithmetic expansion for a control operator that hides a later git status", () => {
    const command = "echo $((1+2)) && git status";
    expect(commandInvokes(command, "push")).toBe(false);
    expect(commandInvokes(command, "commit")).toBe(false);
  });

  it("still detects a real git push whose argument uses arithmetic expansion", () => {
    expect(commandInvokes("git push $((1+1))", "push")).toBe(true);
  });
});

describe("git guard — environment-variable-heavy real invocations", () => {
  it("detects a real commit behind several quoted env-var assignments", () => {
    const command =
      'GIT_AUTHOR_NAME="A B" GIT_AUTHOR_EMAIL=a@example.com ' +
      'GIT_COMMITTER_DATE="2020-01-01T00:00:00" git commit -m "msg"';
    expect(commandInvokes(command, "commit")).toBe(true);
    expect(commandInvokes(command, "push")).toBe(false);
  });

  it("detects a real commit behind an env value containing URL special characters", () => {
    const command =
      'DATABASE_URL="postgres://user:pass@host:5432/db?sslmode=require" git commit -am "fix"';
    expect(commandInvokes(command, "commit")).toBe(true);
  });
});

describe("git guard — real multi-line commit fed from a heredoc, body is inert prose", () => {
  it("detects the real 'git commit -F -' invocation and ignores unrelated heredoc body text", () => {
    // Ground truth: this genuinely creates a commit (message read from
    // stdin). The heredoc body merely *mentions* the word "push" in prose;
    // it does not itself invoke git, so it must not match "push".
    const command = "git commit -F - <<'EOF'\nThis commit does not push anything\nEOF";
    expect(commandInvokes(command, "commit")).toBe(true);
    expect(commandInvokes(command, "push")).toBe(false);
  });
});

describe("git guard — obscure global option no longer swallows the real subcommand", () => {
  it("still detects a real push behind --super-prefix (space-separated global option)", () => {
    // Ground truth: `git --super-prefix /foo/ push origin main` really runs
    // `git push`. Fixed by adding --super-prefix (and --config-env) to
    // GLOBAL_OPTS_WITH_ARG so its value token is correctly skipped instead
    // of being misread as the subcommand.
    const command = "git --super-prefix /foo/ push origin main";
    expect(commandInvokes(command, "push")).toBe(true);
  });
});

// sqlLooksMutating unit-level sanity check for one of the escaping cases
// above, isolating the SQL-text-only behavior from the shell/CLI extraction
// layer.
describe("sqlLooksMutating — unit-level escaping sanity check", () => {
  it("fully masks a doubled-single-quote literal containing 'into'", () => {
    expect(sqlLooksMutating("SELECT * FROM t WHERE note = 'It''s time to look into things'")).toBe(
      false,
    );
  });
});
