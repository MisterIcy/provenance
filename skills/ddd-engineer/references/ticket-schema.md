# DDD ticket schema

The single normalized representation `ddd-intake-classifier` produces and every downstream agent consumes. Its purpose is to make the pipeline **input-agnostic**: a feature request, a change request, a bug report, and a Sentry issue all collapse into this one shape, so no downstream agent needs to know which of the four it came from.

The classifier writes it to `<run-dir>/ticket.md`. Downstream agents only read it — the ticket is the fixed record of what was asked, not mutable pipeline state.

## Shape

A YAML front block, then ordered body sections. Every section is always present — write `_none_` (or `_n/a_`) rather than omitting one.

```yaml
id: <kebab-slug-from-title>
source_type: feature_request | change_request | bug_report | sentry_issue
title: <one line>
priority: low | medium | high | critical      # classifier's best read
languages: []                                  # detected programming languages, e.g. [typescript, php]; [] if unknown
```

### Problem statement
One paragraph, in domain terms, of what is wrong or missing. No solution language — the "what," not the "how."

### Current behavior
What the system does today. For a `bug_report`/`sentry_issue`, the observed faulty behavior; for a `feature_request`, the absence being filled; for a `change_request`, the behavior being changed.

### Desired behavior / acceptance criteria
A checklist of observable, testable conditions that mean "done." Each item must be verifiable by a test or a demonstrable interaction — not a vague quality ("make it faster" → a concrete latency target, or an open question asking for one). This is the contract `unit-test-writer` and `ddd-code-reviewer-adversary` hold the change to.

### Reproduction
For `bug_report`/`sentry_issue`: the minimal steps, inputs, or trace, including the failing assertion/exception where known. For `feature_request`/`change_request`: `_n/a_`.

### Affected bounded contexts (initial read)
The classifier's **first guess**, explicitly labeled a guess, at which existing contexts/modules the work touches. `ddd-domain-modeler` owns the authoritative mapping and will correct it; this only gives the modeler a warm start.

### Constraints
Known hard constraints: security/compliance requirements, performance budgets, backward-compatibility/API obligations, deadlines. These flow to the adversaries — a stated security constraint is a directive to `ddd-security-adversary`; a stated perf budget becomes an acceptance criterion.

### Open questions
Anything the classifier couldn't resolve. These do **not** block the pipeline from starting, but the arbiter must account for each before declaring done — an unresolved *load-bearing* open question is a legitimate reason to escalate.

## Rules

- Never invent facts to fill a section. Missing information is `_none_` or an **Open question**, not a guess.
- `source_type` is set once by the classifier and never changed downstream — it's provenance, not routing state.
- Downstream agents add their outputs as *separate* run artifacts (the domain model, the manifest, the test result, the verdicts, the arbiter's decision) — they don't rewrite the ticket. The final resolution lives in `arbiter-decision.md`, not in the ticket.
