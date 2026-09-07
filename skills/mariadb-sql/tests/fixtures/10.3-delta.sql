-- Additive delta for the mariadb-sql test harness, applied on top of
-- 00-baseline-schema.sql for versions >= 10.3 (see run-version.sh's
-- cumulative-delta logic and tests/README.md).
--
-- Backs the "### 10.3" claims in references/version-features.md: sequences,
-- system-versioned tables, and invisible columns (all MariaDB-only).
-- Purely additive -- does not change any existing baseline object's
-- pre-10.3 behavior.

-- Sequences (CREATE/ALTER/DROP SEQUENCE, NEXTVAL/PREVIOUS VALUE FOR,
-- SETVAL()) -- MariaDB-only, no MySQL equivalent.
CREATE SEQUENCE article_view_counter START WITH 100 INCREMENT BY 1;

-- System-versioned (temporal) table -- MariaDB-only. AS OF / FOR SYSTEM_TIME
-- queries become available against it.
CREATE TABLE article_revisions (
    id    INT UNSIGNED NOT NULL,
    title VARCHAR(255) NOT NULL,
    PRIMARY KEY (id)
) WITH SYSTEM VERSIONING;

INSERT INTO article_revisions (id, title) VALUES (1, 'Original title');

-- Invisible column -- MariaDB-only, excluded from SELECT * and from an
-- INSERT with no explicit column list. Added via ALTER so the baseline
-- `articles` definition stays otherwise untouched.
ALTER TABLE articles
    ADD COLUMN internal_notes VARCHAR(255) INVISIBLE NOT NULL DEFAULT 'n/a';
