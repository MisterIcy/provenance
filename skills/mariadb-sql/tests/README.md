# mariadb-sql skill test harness

Docker-verified tests for the claims made by `skills/mariadb-sql/SKILL.md` and
its `references/*.md` files. Each MariaDB milestone version the skill talks
about gets its own throwaway container, a baseline schema, and a set of
content-verification cases that assert a specific documented claim is
actually true against a live server. There's also an agent-eval suite that
checks the `sql-query-reviewer` subagent actually *applies* that knowledge
correctly when reviewing realistic queries.

## Version ordering

Oldest -> newest, used everywhere in this harness (compose profiles, the
cumulative-fixture-delta logic, and version-tagged content cases):

```
10.2, 10.3, 10.4, 10.5, 10.6, 10.11, 11.4, 11.8, 12.3
```

## Running a single version

```bash
# from the repo root
skills/mariadb-sql/tests/scripts/run-version.sh 10.2

# from the tests/ directory
cd skills/mariadb-sql/tests
scripts/run-version.sh 10.2

# leave the container running afterwards (skip teardown), e.g. to poke at it
scripts/run-version.sh 10.2 --keep
```

This boots only the requested version's Docker Compose service (via
Compose profiles, see `docker/docker-compose.yml`), waits for it to report
healthy, applies `fixtures/00-baseline-schema.sql` plus any cumulative
`fixtures/<version>-delta.sql` files for versions <= the one requested, runs
every applicable case under `cases/content/`, prints a PASS/FAIL summary,
and tears the container down (unless `--keep` is passed). Exits non-zero on
any failure.

## Running the whole matrix

```bash
skills/mariadb-sql/tests/scripts/run-matrix.sh
```

Runs `run-version.sh` for all 9 versions, oldest to newest, and prints an
aggregated table with **passed/failed counts per version**, not just a
boolean:

```
=== Matrix summary ===
VERSION    PASSED   FAILED   RESULT
10.2       2        0        PASS
10.3       5        0        PASS
10.4       7        0        PASS
10.5       10       0        PASS
10.6       13       0        PASS
10.11      19       0        PASS
11.4       24       0        PASS
11.8       27       0        PASS
12.3       29       0        PASS

RESULT: all versions PASSED
```

(Real output from a full run on 2026-09-07 — the passed-count grows
monotonically because content cases are cumulative: a case tagged
`.version` >= some minimum only starts running from that version onward,
and never regresses.) Non-zero exit if any version failed. Versions with no
fixtures/cases yet still "run" (schema-only) rather than being skipped, so a
version that *does* have cases can't have its failure hidden.

Each version boots its own container sequentially, so a full matrix run
takes several minutes — this is expected; let it run to completion rather
than assuming a hang.

## Running agent evals

```bash
# list all cases with their target version
skills/mariadb-sql/tests/scripts/run-agent-evals.sh list

# boot the right container and print one case's prompt + assertions,
# ready to hand to a subagent invocation
skills/mariadb-sql/tests/scripts/run-agent-evals.sh prepare <id>

# after you've invoked the subagent and captured its response to a file,
# grade it against the case's assertions
skills/mariadb-sql/tests/scripts/run-agent-evals.sh grade <id> --response response.txt \
    --verdicts "1=pass,2=pass,3=fail,4=pass"
```

**Important caveat — read before assuming this is fully automated.** A plain
bash script has no way to invoke the Claude Code Agent/Task tool — that's a
capability of a running Claude Code session, not a shell primitive. So
`run-agent-evals.sh` cannot itself send a case's prompt to the
`sql-query-reviewer` subagent, and cannot itself judge free-text semantic
assertions like *"response identifies the target version as 10.4 and states
DROP COLUMN is eligible for ALGORITHM=INSTANT starting at 10.4"* — that
requires a human, or a Claude Code session acting as grader, to actually
read the subagent's output.

The real, end-to-end workflow is:

1. `scripts/run-agent-evals.sh prepare <id>` — boots the case's target
   version's container (applying fixtures), and prints the exact prompt,
   the assertions to grade against, the live DB connection details (host,
   port, credentials), and the case's reference `expected_output` (for the
   grader's eyes only — never shown to the subagent under test). Tears the
   container down afterwards unless `--keep` is passed.
2. From a Claude Code session, invoke the `sql-query-reviewer` subagent
   (via the Agent tool) with that exact prompt.
3. Capture its response, read it against each printed assertion yourself,
   and run `scripts/run-agent-evals.sh grade <id> --response <file>
   --verdicts "1=pass,2=fail,..."` (assertion indices are 1-based, in the
   order `prepare` printed them). `grade` aggregates your verdicts into a
   pass/fail and refuses to call a case PASS if any assertion was left
   unjudged (`--verdicts` must cover every index or the result is
   `INCOMPLETE`, not a silent pass). It also prints one weak mechanical
   hint (whether the response text mentions the target version string at
   all) — that's a sanity signal only, not a substitute for judging the
   real assertions.

There is deliberately no "run all cases end-to-end" single command, because
step 2 cannot be scripted. `evals.json`'s 19 cases are all pure code-review
reasoning prompts ("does this check out", "is X really true") — none
instructs the reviewer to connect to a database, so **static-mode**
subagent invocation is the correct match for every current case; the
`prepare` step's live connection info exists for future live-mode cases
were any added later.

### Known limitation: no host SQL client for live-mode evals

If a future eval case *did* require live-mode review, note that the
`sql-query-reviewer` subagent's tool grant is `Bash(mysql *), Bash(psql
*), Bash(sqlite3 *)` — a bare client binary on `PATH`, not `docker compose
exec`. This harness's own `run_sql()` helper works around exactly this by
exec-ing the client *inside* the container, but the subagent has no
`docker` tool access at all. So a live-mode eval only works on a host that
has a `mysql`/`mariadb` client installed and reachable via the container's
mapped host port (see the port table in "Adding a new version" below) —
verify with `which mysql mariadb` before relying on it.

### Invoking the subagent when it isn't registered as an Agent-tool type

`agents/sql-query-reviewer.md` may not always be picked up as an invokable
Agent-tool subagent type in a given session (e.g. if it's an untracked file
not yet part of a loaded plugin manifest). In that case, drive a
`general-purpose` agent instead, handing it `agents/sql-query-reviewer.md`'s
full body verbatim as its instructions plus the eval case's prompt — this
reproduces the subagent's actual persona/constraints faithfully rather than
skipping the eval. This is exactly how the two real eval runs referenced in
this repo's Agent-C build were driven.

## Fixture-delta naming convention

- `fixtures/00-baseline-schema.sql` — the common schema, applied to every
  version. Must stay safe on the oldest version in the matrix (currently
  10.2) — no syntax/behavior that requires a newer version.
- `fixtures/<version>-delta.sql` (e.g. `fixtures/10.3-delta.sql`) — additive
  schema/data changes that only apply from `<version>` onward. `run-version.sh`
  applies the baseline, then every delta file for a version <= the one
  requested, in oldest-to-newest order. A delta file for a version with no
  file yet is simply skipped.

## Content-verification case convention

Each case lives under `cases/content/` as a pair (plus an optional third
file):

- `<name>.sql` — the query/statement(s) to run against the live server for
  the version under test. Should be tied to a specific claim documented in
  one of the `references/*.md` files (cite it in a comment at the top).
- `<name>.expected` — line 1 is the expected process exit code (`0` for
  success, a MySQL/MariaDB client error's exit code otherwise); every
  subsequent line is concatenated and must appear as a literal substring
  somewhere in the command's combined stdout+stderr.
- `<name>.version` (optional) — a single line naming the MINIMUM version
  (from the ordering list above) this case applies to, e.g. `10.5`. A case
  with no `.version` file is assumed to apply from 10.2 onward. A case is
  only run when the version `run-version.sh` was invoked with is >= this
  minimum.

Example: `cases/content/sql-mode-strict-by-default.sql` /
`.expected` asserts that `sql_mode` includes `STRICT_TRANS_TABLES` by
default on 10.2+, per `references/version-features.md`.

## Agent-eval case convention

`cases/agent-evals/evals.json` — one JSON file, `{skill_name, evals: [...]}`.
Each entry:

- `id` — integer, referenced by `run-agent-evals.sh prepare/grade`.
- `target_version` — which MariaDB milestone version the scenario is set
  on; must be one of the 9 versions in the ordering list.
- `prompt` — the exact text to hand the `sql-query-reviewer` subagent,
  written as a realistic user message (states its own version, includes the
  SQL/DDL in question, and usually poses a teammate's mistaken claim to
  correct).
- `expected_output` — a prose description of the ideal correct answer, for
  a grader's reference only. Never shown to the subagent under test.
- `assertions` — a list of specific, checkable claims the subagent's actual
  response should satisfy. These are semantic (free-text judgment calls),
  not mechanically string-matchable in general — see "Running agent evals"
  above for why and how they're actually graded.

## Adding a new version to the matrix

1. Add the version to `ALL_VERSIONS` in **both** `scripts/run-version.sh`
   and `scripts/run-matrix.sh` (kept as separate arrays deliberately — no
   shared-sourcing indirection for a 9-element list), in the correct
   oldest->newest position.
2. Add a new `mariadb-<version>:` service to `docker/docker-compose.yml`
   (copy an existing one, change `image:`, `profiles:`, and pick an unused
   host port for `ports:` — see the existing port table there, e.g. `13xxx`
   for 10.x, `134xx`/`13408` for 11.x, `135xx` for 12.x; avoid colliding
   with any other Compose project's mapped ports on the host).
3. Add the same version -> host-port mapping to the `PORT_MAP` associative
   arrays in **both** `scripts/run-version.sh` and
   `scripts/run-agent-evals.sh`.
4. If the new version introduces features worth asserting, add
   `fixtures/<version>-delta.sql`, tag any new `cases/content/*.version`
   files appropriately, and/or add `evals.json` entries with that
   `target_version`.
5. Run `scripts/run-version.sh <version>` on its own first to confirm it
   boots and passes before adding it to a full matrix run.

## Known gaps

Not every `references/*.md` file is exercised by content-verification cases.
`references/optimizer-internals.md` (optimizer cost model, statistics,
join/semi-join strategy internals) and `references/query-profiling.md`
(SHOW PROFILE, Performance Schema, slow query log, ANALYZE FORMAT=JSON
runtime fields, status counters) are knowledge-only — they document tooling
and methodology rather than version-gated SQL syntax facts that a single
mechanical SQL-exec case can check against a live server. Claims like a
variable's deprecation status, a rename, or a tool's behavior aren't the
kind of thing `<name>.sql` / `<name>.expected` can assert. No test cases
exist for these two files, and none are planned — this is a deliberate,
documented gap, not an oversight.

## Known gotchas

- **`mysql`/`mariadb` client binary name.** Images through ~11.x ship
  `mysql`/`mysqladmin` (with `mariadb`/`mariadb-admin` as aliases); 12.3+
  dropped the mysql*-named compat binaries entirely and only ships
  `mariadb`/`mariadb-admin`. Both `run-version.sh`'s `run_sql()` and the
  Compose healthcheck resolve whichever exists in the target container
  (`command -v mariadb || command -v mysql`, and the `-admin` equivalent)
  rather than hardcoding one name — do the same in any new script that execs
  the in-container client.
- **Host client absent.** There is no host-installed `mysql`/`mariadb`
  client assumed anywhere in this harness's own scripts (they all exec the
  client *inside* the container via `docker compose exec`) — but the
  `sql-query-reviewer` subagent's tool grant only covers a bare `mysql`/
  `psql`/`sqlite3` binary on `PATH`, so a live-mode agent eval needs one
  installed on the host. See "Known limitation" above.
- **Port collisions.** Each version's Compose service maps a unique host
  port (13302-13503 range) so multiple versions could in principle run
  concurrently — but `run-version.sh`/`run-matrix.sh` never do that
  deliberately; they run one at a time. If a host port is already bound by
  something else, `docker compose up` will fail loudly — check the port
  table in `docker-compose.yml` and change the mapping there if you hit a
  real collision (unrelated Docker Compose projects on a shared dev machine
  are the usual cause).
- **Orphaned containers after an interrupted run.** If a run is killed
  mid-flight (Ctrl-C, terminal closed) before the `trap cleanup EXIT` in
  `run-version.sh` fires, or after backgrounding the script's own process
  without waiting on it, a container can be left running detached. Check
  `docker ps` for a stale `mariadb-<version>` container and `docker compose
  --profile <version> -f docker/docker-compose.yml down` it manually.
- **`run-matrix.sh` takes a while.** 9 sequential container boots
  (image pull if not cached, healthcheck wait, schema apply, case run) adds
  up to several minutes end-to-end — don't assume a long-running matrix
  invocation has hung.
