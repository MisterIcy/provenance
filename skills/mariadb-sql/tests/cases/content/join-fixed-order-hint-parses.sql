-- optimizer-internals.md claims: "12.0+ adds scoped hint syntax:
-- /*+ JOIN_FIXED_ORDER() */ (alias for STRAIGHT_JOIN)". Verify the hint
-- parses and executes successfully on a 12.0+ server (our nearest milestone
-- at/above 12.0 is 12.3).
SELECT /*+ JOIN_FIXED_ORDER() */ a.id, au.id
FROM articles a JOIN authors au ON au.id = a.author_id
LIMIT 1;
