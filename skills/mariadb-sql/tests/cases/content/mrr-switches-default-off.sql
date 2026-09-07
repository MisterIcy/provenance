-- optimizer-internals.md claims: "mrr, mrr_cost_based -- off by default
-- (5.3+). Multi-Range Read improves I/O locality... but isn't reliably a
-- win, hence off". Verify both flags report =off in optimizer_switch
-- (applies across the whole 10.2+ matrix).
SELECT @@optimizer_switch;
