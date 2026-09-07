-- version-features.md, 10.6 section: "SELECT ... OFFSET ... FETCH
-- (SQL-standard pagination syntax)". Verify the syntax parses and paginates
-- correctly on a live 10.6 server. GROUP_CONCAT collapses the paginated
-- rows to one line so the result is a single substring to check.
SELECT GROUP_CONCAT(id ORDER BY id SEPARATOR ',') AS ids
FROM (
    SELECT id
    FROM articles
    ORDER BY id
    OFFSET 1 ROWS
    FETCH NEXT 2 ROWS ONLY
) t;
