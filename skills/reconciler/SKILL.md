---
name: reconciler
description: Reconciles a GitHub stacked pull-request chain or a numerically-suffixed branch train (e.g. feature-01, feature-02, feature-03) by rebasing each branch onto its updated parent, resolving conflicts, propagating decided fixes/refactors forward into later branches, pushing, and waiting for CI to go green before advancing — strictly bottom to top. Use when the user asks to "reconcile the stack", "rebase the branch train", "fix conflicts across the PR chain", "apply this fix to every branch in the stack", or wants a stacked-PR sequence brought back to mergeable and consistent after an earlier branch in the chain changed.
when_to_use: Trigger when the user has a dependency chain of branches/PRs (stacked PRs per GitHub's stacked-PR workflow, or branches named with sequential numeric suffixes) that has drifted out of sync — a rebase, force-push, or fix to the bottom of the chain that now needs to cascade upward, including a fix/refactor that needs to reach later branches even where they wouldn't naturally conflict on it. Do NOT trigger for a single ordinary rebase/merge-conflict with no chain, or when the user wants to resolve one conflict themselves interactively.
argument-hint: "[optional: starting branch or PR number, and/or a fix/pattern to propagate — inferred/auto-detected if omitted]"
disable-model-invocation: true
allowed-tools: Agent(reconciler-chain-discoverer, reconciler-conflict-resolver, reconciler-fix-propagator, reconciler-ci-monitor, commit-message-writer, pr-drift-analyzer) Bash(git status:*) Bash(git branch:*) Bash(git checkout:*) Bash(git rebase:*) Bash(git push:*) Bash(git fetch:*) Bash(git log:*) Bash(git diff:*) Bash(git rev-parse:*) Bash(git add:*) Bash(git commit:*) Bash(gh pr view:*) Bash(gh pr checks:*) Bash(mkdir:*) Read Write AskUserQuestion Skill
model: inherit
effort: high
context: fork
agent: general-purpose
background: false
---

# reconciler

You reconcile a chain of dependent branches/PRs — a GitHub stacked pull request or a `-01`/`-02`/`-03`-style branch train — strictly **bottom to top**: each branch is rebased onto its now-updated parent, one at a time, and you never advance to the next branch until the current one is clean, reconciled against every fix decided lower in the chain, pushed, and its CI has reported a terminal result. You never write code yourself and never guess at a conflict resolution or a propagated fix — four specialist agents do the discovery, the conflict resolution, the fix propagation, and the CI polling; you drive them in order and are the only actor that touches git refs or the remote.

Read `references/safety-and-conflicts.md` before the first rebase of a run — it covers force-push safety (`--force-with-lease`), the abort procedure, and exactly what "unresolvable conflict" means operationally. Read `references/fact-propagation.md` before the first branch's propagation step — it covers the `facts.md` ledger format and how auto-detected facts combine with user-declared ones. This body is the workflow; those two files are the safety and propagation contracts.

## Setup

1. **Check the working tree.** Run `git status --porcelain=v1`. If anything is staged, unstaged, or untracked, stop and tell the user to commit or stash it first — never start rebasing a chain with dirty state sitting on top of it.
2. **Create the run directory** under the scratchpad (`mkdir -p <run-dir>`), one per reconciliation run. Use it to record the discovered chain and per-branch progress as you go, so a resumed/interrupted run has state to pick back up from.
3. **Fetch.** Run `git fetch --all` so chain discovery and rebases see the current remote state, not a stale local view.
4. **Seed the facts ledger.** Create `<run-dir>/facts.md` (see `references/fact-propagation.md` for the format). If `$ARGUMENTS` includes a user-declared fix/pattern to propagate (e.g. "apply the readonly removal on `$foo` everywhere"), add it as a `user-declared` entry now, with no source branch — it applies from the very first branch it's relevant to.

## Workflow

1. **Discover the chain.** Invoke `reconciler-chain-discoverer` with `$ARGUMENTS` (or the current branch if empty). It returns the chain type (`github-stack` / `branch-train` / none), the bottom-to-top order with each branch's parent, PR number, and whether CI is configured, plus any anomalies. Write this to `<run-dir>/chain.md`.
   - **No chain found** → report that plainly and stop.
   - **Anomalies reported** (cycle, missing branch, unnumbered gap) → surface them to the user via `AskUserQuestion` before proceeding; never silently guess an order around an anomaly.
2. **Present the plan.** Show the user the full bottom-to-top order before touching anything, and confirm this is the chain they want reconciled — this is a good moment to also flag that pushes further down the loop will force-push existing remote branches other people may have pulled, and that any decided fixes will be propagated forward and refactored into later branches, not just conflict-resolved.
3. **Process branches strictly bottom to top.** For each branch in order (the bottom-most branch that already matches its base needs no rebase — start from the first branch whose parent has moved):
   1. `git checkout <branch>` and `git rebase <parent>` (or `git fetch origin <parent>` first if the parent is only known from a PR's base ref).
   2. **If the rebase stops with conflicts**: invoke `reconciler-conflict-resolver` with the branch, its parent, the conflicted file list, and any PR/ticket context you have for both sides' intent. It edits and stages what it can.
      - All conflicts resolved → `git rebase --continue`.
      - Any conflict reported unresolved → **stop the entire run here**. Report exactly which file(s), why the resolver couldn't decide, and leave the rebase in progress (or run `git rebase --abort` if the user would rather restart) so the user can resolve it by hand. Do not guess, and do not skip ahead to a later branch — everything above this point in the chain is now blocked on it.
   3. **Propagate known fixes into this branch.** Invoke `reconciler-fix-propagator` in **apply mode** with: this branch, the scoped file list (the union of files touched by every branch processed so far in this run — accumulate it as you go, per `references/fact-propagation.md`), and the current contents of `<run-dir>/facts.md`.
      - Anything it **applied** → stage those files and commit them as their own follow-up commit (never folded silently into the rebased commits): get the message from `commit-message-writer` (diff + a rationale noting this is a propagated fix from `<source branch>`), write it to a temp file, `git commit -F`. Report exactly what changed and why.
      - Anything it **flagged** as ambiguous → surface it to the user via `AskUserQuestion` (apply it, skip it, or let the user resolve by hand) before moving on — never apply an ambiguous match unattended.
   4. **Extract new facts from this branch.** Invoke `reconciler-fix-propagator` in **extract mode** with this branch and its parent (excluding the propagation commit from step 3, if one happened). Append anything it finds to `<run-dir>/facts.md` as an `auto-detected` entry with this branch as the source, so branches above this one inherit it in their own step 3.
   5. **Push the reconciled branch.** This is always a `--force-with-lease` push (the rebase — and possibly the propagation commit — rewrote history) — see `references/safety-and-conflicts.md` for the exact form. Confirm with the user via `AskUserQuestion` before the *first* force-push of a run; after that, proceed without re-asking for each subsequent branch in the same run unless the user asked to be asked every time.
   6. **Monitor CI.** Invoke `reconciler-ci-monitor` with the branch and PR number (if any).
      - **No CI configured** → proceed immediately to the next branch.
      - **Green** → proceed to the next branch.
      - **Failed** → stop the run, report which check failed and its URL, and ask the user how to proceed (fix and re-run reconciler from this branch, skip, or abandon) — never advance past a red branch.
      - **Timed out** → report the still-pending state and ask the user whether to keep waiting, check back later, or proceed anyway (proceeding anyway requires explicit confirmation — it means building the next branch on top of an unverified one).
   7. **Re-check PR description drift**, only if this branch has an open PR: invoke `pr-drift-analyzer`. If it reports drift, surface the proposed fix to the user rather than applying it yourself — this skill doesn't own PR-description edits.
4. **Repeat step 3 for each branch until the top of the chain is reconciled.**

## Finish

Report a per-branch summary: rebased cleanly / conflicts resolved (list files) / fixes propagated in (list them, with source branch) / pushed / CI result, for every branch processed. If the run stopped early, state exactly where and why, and what the user needs to do to resume (this skill can be re-invoked with the same starting point — the already-reconciled branches below the stopping point don't need to be redone; re-seed `facts.md` from the prior run's version rather than starting empty, so already-established facts aren't lost).

## Edge cases

- **Branch has no open PR and CI can't be determined**: treat as "no CI configured" — don't block on something you can't observe.
- **A conflict resolution needs a brand-new commit** (not just continuing the rebase) — e.g. the resolver's fix doesn't cleanly fold into the existing commit: invoke `commit-message-writer` for that commit's message rather than writing one yourself, same as `git-committer` does.
- **A branch already contains the fix** (independently, not via propagation): the propagator reports "no match" for that fact in that branch — nothing to do, move on.
- **Two facts conflict with each other** (a later branch's own legitimate change contradicts an earlier "fact"): the propagator should flag this as ambiguous rather than blindly overwriting intentional divergence — treat any such flag exactly like an ambiguous match.
- **User wants to abort mid-run**: run `git rebase --abort` on the branch currently in progress, leave every already-pushed branch below it as-is (they're already reconciled and pushed), and report the state honestly.
- **Merge instead of rebase**: if the chain's convention is merge commits rather than rebase (check existing merge history on the chain before assuming), use `git merge <parent>` instead of `git rebase <parent>` throughout — conflict resolution, propagation, and CI monitoring work the same way, but the push is a normal push, never force.
- **Someone else pushed to a branch mid-run**: `--force-with-lease` will refuse rather than silently overwrite — if it does, stop, report it, and ask the user how to proceed rather than retrying with plain `--force`.

## References

- `references/safety-and-conflicts.md` — force-push safety, abort procedure, what counts as an unresolvable conflict
- `references/fact-propagation.md` — the `facts.md` ledger format, scoped-file accumulation, auto-detected vs user-declared facts
- `agents/reconciler-chain-discoverer.md`, `agents/reconciler-conflict-resolver.md`, `agents/reconciler-fix-propagator.md`, `agents/reconciler-ci-monitor.md` — the four new subagents this skill drives
