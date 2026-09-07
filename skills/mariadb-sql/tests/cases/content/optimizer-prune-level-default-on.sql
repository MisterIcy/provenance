-- optimizer-internals.md claims: "optimizer_prune_level (on by default)
-- discards provably-worse partial plans without fully costing them."
-- The doc only claims "on", not a specific numeric value -- and the
-- underlying default numeric value itself changes across versions (1 vs 2
-- in different milestones), so assert on-ness via a derived marker rather
-- than a literal number, which would break forward-compatibility for
-- reasons unrelated to the claim being tested.
SELECT IF(@@optimizer_prune_level <> 0, 'PRUNE_ON', 'PRUNE_OFF');
