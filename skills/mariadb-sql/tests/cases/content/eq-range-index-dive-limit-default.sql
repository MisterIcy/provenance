-- optimizer-internals.md claims: "eq_range_index_dive_limit (default changed
-- 0 -> 200 at 10.4.3): for equality-range predicates exceeding this limit...".
-- Verify the session default is actually 200 on a 10.4+ server.
SELECT @@eq_range_index_dive_limit;
