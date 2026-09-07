-- version-features.md claims: "CYCLE clause on recursive CTEs | 10.5 |
-- Explicit cycle detection". Verify a recursive CTE with a CYCLE clause
-- succeeds on a 10.5 server, walking the org_chart manager graph. MariaDB's
-- CYCLE grammar only supports the `CYCLE <col_list> RESTRICT` form (no
-- SET/USING cycle-mark/path columns), confirmed against a live 10.5 server.
WITH RECURSIVE chain AS (
    SELECT id, manager_id, name, 1 AS depth
    FROM org_chart
    WHERE id = 4
    UNION
    SELECT o.id, o.manager_id, o.name, chain.depth + 1
    FROM org_chart o, chain
    WHERE o.id = chain.manager_id
)
CYCLE id RESTRICT
SELECT id, name, depth
FROM chain
ORDER BY depth;
