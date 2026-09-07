-- Baseline schema for the mariadb-sql test harness.
--
-- MUST remain safe on plain MariaDB 10.2 (the oldest version in the matrix):
--   - no native JSON type (10.2 only has JSON-as-LONGTEXT with a CHECK alias,
--     and we deliberately avoid relying on the JSON CHECK-constraint alias
--     here too, to stay conservative) -- the "json" column below is a plain
--     LONGTEXT column, queried with JSON_EXTRACT() (added in 10.2), not
--     validated with JSON-specific constraint syntax.
--   - no sequences (10.3+), no system versioning (10.3+), no RETURNING (10.5+)
--   - no window functions/CTEs required by the schema itself (available since
--     10.2, but not needed to define these tables)
--
-- Applied fresh into the `skilltest` database by scripts/run-version.sh.

-- Parent table.
CREATE TABLE authors (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    email       VARCHAR(255) NOT NULL,
    bio         TEXT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_authors_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Child table, FK'd to authors, with a blob and a JSON-as-text column.
CREATE TABLE articles (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    author_id   INT UNSIGNED NOT NULL,
    title       VARCHAR(255) NOT NULL,
    body        TEXT NOT NULL,
    cover_image BLOB NULL,
    -- JSON-as-text: plain LONGTEXT, not MariaDB's JSON alias/CHECK, so this
    -- stays valid on any 10.2.x point release without depending on the
    -- CHECK-constraint enforcement landing at exactly 10.2.4+.
    metadata    LONGTEXT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_articles_author
        FOREIGN KEY (author_id) REFERENCES authors (id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_articles_author_id ON articles (author_id);

-- Seed data.
INSERT INTO authors (email, bio) VALUES
    ('ada@example.com', 'Mathematician and writer.'),
    ('grace@example.com', 'Computer scientist, compiler pioneer.'),
    ('linus@example.com', NULL);

INSERT INTO articles (author_id, title, body, cover_image, metadata) VALUES
    (1, 'On Analytical Engines', 'A survey of computation.', NULL, '{"tags": ["math", "history"], "views": 120}'),
    (1, 'Notes on Notation', 'Further notes.', NULL, '{"tags": ["math"], "views": 42}'),
    (2, 'Compilers 101', 'How compilers work.', NULL, '{"tags": ["cs", "compilers"], "views": 980}'),
    (3, 'Kernels and Kindness', 'Musings on open source.', NULL, NULL);
