-- version-features.md claims (11.4): "Descending indexes now usable for
-- MIN()/MAX()." Verify that MAX(score) against the 11.4-delta fixture's
-- score_events table, which has a KEY idx_score_desc (score DESC), is
-- satisfied by the optimizer without a table scan.
EXPLAIN SELECT MAX(score) FROM score_events;
