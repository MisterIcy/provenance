-- Additive schema/data changes for MariaDB 10.4, applied on top of
-- 00-baseline-schema.sql (and any 10.3-delta.sql, if present) by
-- scripts/run-version.sh for versions >= 10.4.
--
-- Introduces fixtures for the 10.4 claims in references/version-features.md:
--   - Instant DROP COLUMN (ALGORITHM=INSTANT extended to DROP COLUMN in 10.4)
--   - Unique index/constraint allowed on BLOB/TEXT columns (with a prefix length)

-- For the instant-DROP-COLUMN case: a table with a column meant to be
-- dropped by a content-verification case (not here, so the drop itself is
-- exercised as part of the test rather than baked into the fixture).
-- (Named article_drafts, not article_revisions -- that name is already
-- taken by the 10.3 delta's system-versioned-table fixture.)
CREATE TABLE article_drafts (
    id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    article_id      INT UNSIGNED NOT NULL,
    draft_no        INT UNSIGNED NOT NULL DEFAULT 1,
    deprecated_note VARCHAR(255) NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_article_drafts_article
        FOREIGN KEY (article_id) REFERENCES articles (id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO article_drafts (article_id, draft_no, deprecated_note) VALUES
    (1, 1, 'legacy note'),
    (1, 2, NULL);

-- For the unique-index-on-BLOB case: a table with a BLOB column and no
-- existing index on it, so a content-verification case can add a unique
-- prefix-length index.
CREATE TABLE attachments (
    id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    article_id   INT UNSIGNED NOT NULL,
    content_hash BLOB NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_attachments_article
        FOREIGN KEY (article_id) REFERENCES articles (id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO attachments (article_id, content_hash) VALUES
    (1, 0x68617368303031),
    (2, 0x68617368303032);
