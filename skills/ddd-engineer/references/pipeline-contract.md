# DDD pipeline contract

The stage graph the `ddd-engineer` skill drives, the run-artifact layout every agent reads and writes, and the two rules that keep the loop bounded: the **evolve gate** (human approval for new domain structure) and the **three-round hard stop** (escalate instead of looping forever).

## Run artifacts

Each run gets a working directory the skill creates under the scratchpad, one per ticket. All inter-agent handoff goes through files here — agents don't pass large payloads through chat. Production code is written to the **real repository**; the run dir holds only reasoning/coordination artifacts.

```
<run-dir>/
  ticket.md                              # ddd-intake-classifier   (see ticket-schema.md)
  domain-model.md                        # ddd-domain-modeler      (mode: fit | evolve)
  implementer-manifest.md                # ddd-implementer         (what each writer produced this round)
  test-result.md                         # unit-test-writer        (pass/fail per suite + command, DDD-pipeline mode)
  verdicts/
    ddd-invariant-adversary.md           # one file per adversary, rewritten each round
    ddd-boundary-adversary.md
    ddd-security-adversary.md
    ddd-pattern-adversary.md
    ddd-code-reviewer-adversary.md
  arbiter-decision.md                    # ddd-tech-lead-arbiter   (accept | iterate | escalate)
  round                                  # plain file holding the current round number (1, 2, 3)
```

## Stage graph

```
1. ddd-intake-classifier   → ticket.md
2. ddd-domain-modeler      → domain-model.md   (mode: fit | evolve)
     └─ if evolve  → EVOLVE GATE (human approval) → arbiter sign-off → continue
3. ddd-implementer         → pure coordinator: drives its writer squad to edit the real source, writes only implementer-manifest.md
     internally orchestrates, per round, its own squad:
       ddd-aggregate-writer, ddd-controller-writer, ddd-service-writer, ddd-repository-writer,
       ddd-value-object-writer, ddd-factory-writer, ddd-event-handler-writer, ddd-wiring-writer
     with ddd-pattern-evaluator reviewing each artifact as it is produced (targeted in-round retry, one per artifact)
4. unit-test-writer        → writes/updates tests (incl. aggregate-invariant, domain-event, value-object, acceptance-criteria tests), runs them, writes test-result.md
5. adversaries (parallel)  → verdicts/*.md
       ddd-invariant-adversary, ddd-boundary-adversary, ddd-security-adversary,
       ddd-pattern-adversary, ddd-code-reviewer-adversary
6. ddd-tech-lead-arbiter   → arbiter-decision.md
       accept   → hand off to git-committer, done
       iterate  → bump round, GOTO 3 (full implementer rerun)   [only on round 1 or 2]
       escalate → hard stop, surface to human                    [on round 3]
```

## The evolve gate

`ddd-domain-modeler` runs in one of two modes:

- **fit** — the work maps onto existing contexts/aggregates/shared kernels. No gate; continue straight to the implementer.
- **evolve** — the work needs *new* domain structure (a new bounded context, aggregate root, or shared kernel, or a moved boundary). Architecturally expensive to reverse once code is built on it, so it's gated twice:
  1. **Human approval (hard).** The skill presents the evolve proposal to the human (via `AskUserQuestion`) and waits for explicit approval before any code is written. This gate always fires — **no plugin option skips it**. A wrong boundary call must never reach the implementer unseen.
  2. **Arbiter sign-off.** After the human approves, `ddd-tech-lead-arbiter` reviews the proposal for internal consistency before the implementer starts. (The arbiter can ratify an approval; it can never override a human rejection.)

If the human rejects, the skill sends the proposal back to `ddd-domain-modeler` with the rejection reason, or stops if the human asks to stop. It does **not** fall back to a fit mapping on its own — forcing a bad fit is exactly what evolve exists to avoid.

## The three-round hard stop

The implementer → tests → adversaries → arbiter loop reruns **the whole implementer step from scratch** each round (not a targeted patch — a full rerun so a fix in one writer's output can't silently break another's).

- The round number starts at 1, tracked in `<run-dir>/round`. The **skill** owns incrementing it; the arbiter only reads it.
- The arbiter may return `iterate` at most twice (rounds 1 and 2). On round 3, if consensus still isn't reached, it must return `escalate` instead.
- `escalate` is a hard stop: the skill halts, commits nothing, and surfaces to the human a synthesis of what the adversaries keep flagging and where the disagreement sits. Resolution is then the human's.
- The arbiter reaches `accept` when every adversary verdict is clear or has only `advisory` (non-blocking) notes, and every load-bearing open question from the ticket is resolved. Cosmetic or explicitly-deferred items don't block `accept`.

## Language / skill loading

No agent in this pipeline is language-specific. Each code-touching or code-reading agent (`ddd-implementer` and its writer squad, `ddd-pattern-evaluator`, `unit-test-writer`, and every adversary that reads code) has `Skill` access and is instructed to **detect the stack from the target files and load the matching convention skill** — the same pattern `sql-query-reviewer` uses to pull in `mariadb-sql`. Per-language convention skills (`typescript`, `php`, …) are authored separately and picked up automatically once they exist; until then the agents infer conventions from surrounding code.
