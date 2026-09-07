-- version-features.md claims: "ONLY_FULL_GROUP_BY / STRICT_TRANS_TABLES on by
-- default | 10.2.4 | ... sql_mode default changed (10.2.4):
-- STRICT_TRANS_TABLES, ERROR_FOR_DIVISION_BY_ZERO, NO_AUTO_CREATE_USER,
-- NO_ENGINE_SUBSTITUTION". Verify the default session sql_mode actually
-- contains STRICT_TRANS_TABLES on a fresh 10.2 server with no my.cnf override.
SELECT @@GLOBAL.sql_mode;
