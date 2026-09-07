# MariaDB skill test harness — Docker-verified, version-by-version

## Context

`skills/mariadb-sql/` gives the `sql-query-reviewer` agent MariaDB dialect knowledge (`correctness.md`, `performance.md`, `safety-and-config.md`, `version-features.md`). The last change substantially expanded `version-features.md` with claims sourced from MariaDB's changelogs across 10.2 → 12.3. None of this is currently checked against a real server, and there's no eval suite proving `sql-query-reviewer` actually produces correct findings when the skill is loaded. Two risks compound: the reference docs could contain factual errors (version-gating, syntax, defaults), and the agent could fail to apply them correctly even when they're right.

Goal: a test harness that (1) verifies the skill's documented claims against real MariaDB instances per version, and (2) evals `sql-query-reviewer`'s actual review output — built incrementally, oldest supported version first, so failures are always attributable to the newest delta, not a backlog of untested history.

**Decisions already made with the user:**
- Version matrix: **LTS/GA milestones only** — `10.2, 10.3, 10.4, 10.5, 10.6, 10.11, 11.4, 11.8, 12.3` (9 versions; 10.6 stays the `mariadb-dba` baseline). All 9 tags confirmed to exist on Docker Hub (`docker manifest inspect mariadb:<tag>` succeeded for all).
- Test focus: **both** content-verification (doc claims vs. live server) and agent evals (`sql-query-reviewer`'s review quality).
- Location: `skills/mariadb-sql/tests/`, **and** a new GitHub Actions workflow now.
- No specialized subagents yet — work is split across sequenced/parallel `general-purpose` Agent-tool calls.

## Directory layout

```
skills/mariadb-sql/tests/
  docker/
    docker-compose.yml        # one service per milestone version (profiles: only the invoked version starts)
  fixtures/
    00-baseline-schema.sql    # 10.2-safe common schema: FK'd tables, unique idx, blob/text, JSON-as-text col
    10.3-delta.sql            # additive on top of baseline: sequence, system-versioned table, invisible column
    10.4-delta.sql            # instant DROP COLUMN target, unique idx on blob
    10.5-delta.sql            # RETURNING-eligible table, CYCLE-clause recursive CTE, WITHOUT OVERLAPS
    10.6-delta.sql            # JSON_TABLE-backed view
    10.11-delta.sql
    11.4-delta.sql
    11.8-delta.sql            # vector column + index
    12.3-delta.sql            # IS JSON predicate target, associative-array proc
  cases/
    content/                  # ground-truth checks: one case = query + expected exit/output, per doc claim
    agent-evals/
      evals.json               # skill-creator-style evals.json, each case tagged with target_version
  scripts/
    run-version.sh            # boot one version, wait healthy, apply cumulative fixtures up to it, run content cases, tear down
    run-matrix.sh             # loop run-version.sh oldest→newest, aggregate pass/fail, non-zero exit on any failure
    run-agent-evals.sh        # for each evals.json case, run sql-query-reviewer against the right container, grade assertions
  README.md                  # how to run locally, how to add a new version/case

.github/workflows/mariadb-tests.yml   # matrix job per version, docker-enabled runner
```

## The two test layers

1. **Content verification** — one case per documented claim (e.g. "`CYCLE` errors below 10.5, succeeds at 10.5+", "`sql_mode` includes `STRICT_TRANS_TABLES` by default from 10.2.4"). Each case is a SQL snippet plus an expected exit code / output pattern, run directly against the live container via the `mysql` client — no LLM involved, purely mechanical. This is what catches drift or errors in `correctness.md`/`performance.md`/`version-features.md` itself.

2. **Agent evals** — `evals.json` entries (following `references/evaluating-skills.md`'s existing format, extended with a `target_version` field) where the prompt asks `sql-query-reviewer` to review a query written to trip a specific documented pitfall at a specific version. Assertions check the agent's actual output (e.g. "flags the `NOT IN` + nullable-subquery bug as HIGH correctness", "does not claim `RETURNING` is available"). Graded per the existing convention: mechanically-checkable assertions via a grading script, human judgment for the rest.

## Iterative build order (oldest → newest, cumulative)

Each version's fixture delta only adds what's new at that version; content cases and agent-eval cases are written and must pass **before moving to the next version**, so a failure is always traceable to the newest layer, not an unverified backlog.

## Agent split (general-purpose `Agent` calls, no specialized subagents)

- **Agent A (sequential, first — walking skeleton).** Scaffold `docker-compose.yml`, `run-version.sh`, `run-matrix.sh`, and `00-baseline-schema.sql`, wired up against `mariadb:10.2` only. Must actually boot the container, connect, and run a real query in this session before anyone reports "done" — no other agent starts until this is proven working end-to-end.
- **Agents B1–B8 (parallel, after A lands).** One per remaining milestone (`10.3, 10.4, 10.5, 10.6, 10.11, 11.4, 11.8, 12.3`). Each writes that version's delta fixture, content-verification cases, and agent-eval cases, using Agent A's `run-version.sh` contract unmodified. Safe to parallelize — each only touches its own delta/case files. Each agent must run `run-version.sh <its version>` itself against the real container and report actual pass/fail output, not a claim.
- **Agent C (sequential, after B\*).** Builds `run-matrix.sh`'s aggregation and `run-agent-evals.sh`, confirms cumulative fixtures apply cleanly oldest→newest in one full run, writes `tests/README.md`.
- **Agent D (sequential, after C).** Adds `.github/workflows/mariadb-tests.yml` (matrix job per version, `services: mariadb: image: mariadb:<version>`), and a short pointer in the root `CLAUDE.md` Commands section.

I'll review each wave's report before releasing the next, and spot-check by actually running the scripts myself rather than trusting completion claims.

## Verification

- After Agent A: run `skills/mariadb-sql/tests/docker/run-version.sh 10.2` myself, confirm exit 0 with real query output.
- After each B agent: rerun that version's script *and* re-run 10.2's, confirming no regression.
- After Agent C: run the full `run-matrix.sh`, expect a clean pass/fail table across all 9 versions, exit 0.
- After Agent D: validate the workflow YAML (`actionlint` if available, else manual review) — CI workflow changes get your explicit review before anything is pushed.
