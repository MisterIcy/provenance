-- optimizer-internals.md claims: "rowid_filter -- on (10.4.3+). Builds a
-- Bloom-filter-like rowid filter from a selective range index...".
-- Verify optimizer_switch reports rowid_filter=on by default on a 10.4+
-- server.
SELECT @@optimizer_switch;
