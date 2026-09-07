-- query-profiling.md claims: "From 11.5, FLUSH STATUS's global-reset
-- behavior splits into a separate FLUSH GLOBAL STATUS; FLUSH
-- STATUS/FLUSH SESSION STATUS becomes session-scoped only." Verify the
-- FLUSH GLOBAL STATUS syntax itself exists and succeeds. Our nearest
-- matrix milestone at/above 11.5 is 11.8, so tagged there. Asserted on
-- exit code alone (no substring): the mysql/mariadb client prints no
-- "Query OK" text for a non-SELECT statement in default non-interactive
-- (piped) batch mode -- a pre-11.5 server would instead exit non-zero
-- with an unknown-syntax error, which the exit-code check alone catches.
FLUSH GLOBAL STATUS;
