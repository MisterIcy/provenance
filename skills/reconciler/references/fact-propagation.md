# Fact propagation

A rebase alone only carries a fix as far as git's own diff/patch mechanics reach: if branch `-02` independently repeats the pattern branch `-01` just fixed (e.g. both declare `private readonly int $foo`, and `-01`'s fix removed `readonly` from its own copy), rebasing `-02` onto the new `-01` will **not** touch `-02`'s copy — there's no textual conflict, so git has nothing to reconcile. Fact propagation exists to close that gap: it's a semantic pass, not a git operation.

## The `facts.md` ledger

One file per run, at `<run-dir>/facts.md`. Each entry:

```
## Fact N
- Description: <plain-language statement of the decided fix/refactor>
- Before: <code shape>
- After: <code shape>
- Source: <user-declared | branch-name>
- Status: active
```

- **User-declared** facts are seeded once at the start of the run (Setup step 4) from `$ARGUMENTS`, with no source branch — they apply to every branch in the chain from the first one relevant to them.
- **Auto-detected** facts are appended after each branch is processed (workflow step 3.4), extracted from that branch's own diff against its parent. Only that branch and everything above it in the chain sees the fact — a fact never applies retroactively to branches already reconciled below it.
- Never delete or edit a past entry; if a later branch's propagator flags a fact as conflicting with that branch's own intentional divergence, add a note under the existing entry (e.g. `Status: superseded in <branch> — see run summary`) rather than removing it, so the ledger stays an honest record of what was decided and where.

## Scoped file list

Propagation only ever searches files that some branch in this chain has actually touched — never the whole repository, and never files outside this chain's own concern. Build this list incrementally:

1. After chain discovery, seed it from each branch's `git diff --name-only <parent>..<branch>` (the chain-discoverer's output gives you the pairs needed to compute this, or compute it yourself once the chain order is known).
2. As you process each branch, the file list only grows (union), never shrinks — a file touched by `-03` stays in scope even while reconciling `-07`.

Pass this accumulated list into `reconciler-fix-propagator`'s apply-mode input every time so its search stays bounded and fast rather than grepping the entire tree.

## Applying vs. flagging

The propagator agent (`agents/reconciler-fix-propagator.md`) decides per-occurrence whether a match is clear enough to apply automatically or needs a human decision — that judgment call lives entirely in the agent, not in this skill's orchestration logic. This skill's job is purely mechanical once the agent reports back:

- **Applied** → stage + commit as its own follow-up commit (a message from `commit-message-writer`, never silently folded into the rebase-replayed commits) so the propagation is visible and revertable on its own.
- **Flagged** → always surface to the user via `AskUserQuestion` before doing anything; never auto-apply an ambiguous match and never auto-skip it either — the user decides.

## Resuming a run

If a run stops partway (an unresolved conflict, a red CI check, a user-requested abort), the facts extracted from every branch already fully reconciled (rebased, propagated into, pushed, green) remain valid. When re-invoking the skill for the same chain, re-seed `<run-dir>/facts.md` (a fresh run directory) from the prior run's ledger rather than starting empty — otherwise branches above the resume point would silently lose fixes that were already correctly established below it.
