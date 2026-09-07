-- version-features.md claims: "RETURNING clause on INSERT/UPDATE/DELETE/
-- REPLACE | 10.5 | MariaDB-only". Verify INSERT ... RETURNING actually
-- returns the inserted row's generated id and name on a 10.5 server.
INSERT INTO tags (name) VALUES ('rust') RETURNING id, name;
