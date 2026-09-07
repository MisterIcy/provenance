-- version-features.md claims: "Associative arrays (DECLARE TYPE ..
-- TABLE OF .. INDEX BY, Oracle-compatible procedural syntax) | 12.1 (12.3
-- consolidates 12.1/12.2's Oracle-compatibility features)". Verify calling
-- the assoc_array_total procedure (fixtures/12.3-delta.sql), which builds a
-- VARCHAR-indexed associative array of INT and sums its elements, produces
-- the expected total. The procedure was created under sql_mode=ORACLE, but
-- CALLing an already-compiled procedure does not require ORACLE mode.
CALL assoc_array_total(@t);
SELECT @t AS total;
