-- optimizer-internals.md claims: "the optimizer only consults histograms
-- when optimizer_use_condition_selectivity >= 4 (default since 10.4.1)".
-- Verify the session default is actually 4 on a 10.4+ server.
SELECT @@optimizer_use_condition_selectivity;
