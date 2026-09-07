-- version-features.md, 10.10 section: "explicit_defaults_for_timestamp
-- default changed to ON"; the 10.11 section confirms this default carries
-- into the 10.11 LTS train. Verify the default is actually ON (1) on a
-- fresh 10.11 server with no my.cnf override.
SELECT @@GLOBAL.explicit_defaults_for_timestamp;
