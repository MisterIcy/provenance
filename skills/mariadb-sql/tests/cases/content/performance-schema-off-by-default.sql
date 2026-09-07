-- query-profiling.md claims: "Disabled by default (since 10.0.12, for the
-- CPU/memory overhead) and startup-only". 10.0.12 predates our whole
-- matrix (10.2+), so no .version tag. Concatenate the flag into one output
-- line so the assertion isn't just a bare "0" that could match anything.
SELECT CONCAT('performance_schema=', @@performance_schema);
