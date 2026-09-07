-- version-features.md ("### 10.3"): "Sequences: full CREATE/ALTER/DROP
-- SEQUENCE, NEXT VALUE FOR, PREVIOUS VALUE FOR, SETVAL() (MariaDB-only)."
-- Verify the sequence created in fixtures/10.3-delta.sql (START WITH 100)
-- actually produces that configured start value on the first NEXTVAL call.
SELECT NEXTVAL(article_view_counter);
