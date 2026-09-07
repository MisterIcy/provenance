-- version-features.md, 10.6 section: "SELECT ... SKIP LOCKED (InnoDB only)".
-- Verify the syntax is accepted (no syntax error) against a live 10.6
-- server, inside a transaction against the InnoDB `articles` table. The
-- column alias is the substring checked below, so a pass proves the
-- statement actually parsed and returned a row rather than just exiting 0.
START TRANSACTION;
SELECT id AS skip_locked_result FROM articles ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED;
COMMIT;
