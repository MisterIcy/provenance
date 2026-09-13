# Safety and conflicts

## Force-push safety

Every push in a reconciliation run follows a rebase, so it always rewrites the branch's history — plain `git push` will be rejected, and plain `git push --force` is unsafe because it can silently clobber a commit someone else pushed to that branch since you last fetched it. Always use:

```
git push --force-with-lease origin <branch>
```

`--force-with-lease` refuses the push if the remote branch has moved since your last fetch of it, instead of overwriting blind. If it refuses, that means someone else pushed to this branch mid-run — stop, report it, and ask the user how to proceed. Never retry with plain `--force` to push through a lease rejection; that is the exact case the lease exists to catch.

Confirm with the user via `AskUserQuestion` before the first force-push of a run. This is a deliberate, one-time gate per run, not per branch — asking before every single branch in a 5-branch train adds friction without adding safety once the user has approved the run's shape. If the user wants to be asked every time, honor that instead.

## Abort procedure

If a rebase needs to be abandoned partway (an unresolvable conflict, or the user wants to stop):

```
git rebase --abort
```

This restores the branch to its pre-rebase state — safe to run at any point before `git rebase --continue` has completed the rebase. It does **not** undo anything already pushed for branches earlier in the chain; those stay reconciled. Report the abort plainly and leave the branch as it was before this run touched it.

## What counts as an unresolvable conflict

The `reconciler-conflict-resolver` agent is instructed to stop rather than guess when a conflict is a genuine **logic collision**: both sides of the chain changed the same behavior in substantively incompatible ways, and picking one side would silently discard the other's intent. Examples:

- Both sides changed the same function's behavior for the same input in different, non-composable ways.
- One side removed something the other side's new code depends on.
- A merge would require a design decision (which validation rule wins, which of two renamed APIs is canonical) that the resolver has no authority to make.

This is distinct from **mechanical conflicts** the resolver is expected to handle: both sides added unrelated lines near each other, a rename that doesn't affect the other side's logic, whitespace/formatting collisions, or one side's change being a strict superset of the other's.

When the resolver reports an unresolved conflict, the reconciler skill stops the entire run at that branch — it does not skip ahead to a later branch in the chain, since every branch above the blocked one depends on it. Report the exact file(s) and hunks, the resolver's reasoning for why it couldn't decide, and leave the rebase in progress (or abort it, per the user's preference) so the user can resolve it by hand and re-invoke the skill from that point.
