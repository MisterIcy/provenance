-- version-features.md, 10.6 section + quick-reference table: "JSON_TABLE --
-- extracts JSON into a relational table shape", introduced 10.6. Verify a
-- view built on JSON_TABLE (fixtures/10.6-delta.sql's `article_tags`) can
-- actually be queried against a live 10.6 server. GROUP_CONCAT collapses
-- the shredded rows to one line so the result is a single, order-stable
-- substring to check (see tests/README.md's content-case convention).
SELECT GROUP_CONCAT(tag ORDER BY tag SEPARATOR ',') AS tags
FROM article_tags
WHERE article_id = 1;
