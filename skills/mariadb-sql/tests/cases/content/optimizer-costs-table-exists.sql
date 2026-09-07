-- optimizer-internals.md claims: "11.0's Optimizer Cost Model overhaul
-- rebaselined this... with per-engine costs (key lookup, row read,
-- comparison, copy) now visible in information_schema.optimizer_costs".
-- Verify the table exists and returns at least one engine's cost row on an
-- 11.4+ server (our nearest milestone at/above the 11.0 overhaul).
SELECT * FROM information_schema.optimizer_costs LIMIT 1;
