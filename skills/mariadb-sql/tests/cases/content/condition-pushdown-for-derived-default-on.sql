-- optimizer-internals.md claims: "condition_pushdown_for_derived -- on
-- (10.2.2+). Pushes outer WHERE into a derived table that couldn't be
-- merged, before materialization." Our matrix floor is 10.2, so this
-- applies from 10.2 onward with no version tag. Verify the flag reports
-- =on in optimizer_switch.
SELECT @@optimizer_switch;
