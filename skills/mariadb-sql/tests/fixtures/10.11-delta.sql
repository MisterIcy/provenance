-- Additive schema/data for MariaDB 10.11 (LTS), applied on top of
-- 00-baseline-schema.sql plus the 10.3/10.4/10.5/10.6 deltas.
--
-- references/version-features.md, 10.11 section: "Largely consolidates
-- 10.7-10.10 features (UUID type, INET4/INET6, JSON_OVERLAPS, descending
-- indexes, explicit_defaults_for_timestamp=ON, GTID-based replication
-- defaults) into one LTS train -- when a caller says '10.11' expect all of
-- the above to be present." This harness's version matrix
-- (tests/README.md's version ordering) skips 10.7-10.10 entirely, so these
-- consolidated features are all first-testable here, at 10.11:
--   - Native UUID data type (landed 10.7)
--   - INET4 data type (landed 10.10; pairs with 10.5's INET6)
--   - Descending index columns (landed 10.8)
--
-- explicit_defaults_for_timestamp's default flip (10.10) and JSON_OVERLAPS
-- (10.9) and GRANT ... TO PUBLIC (genuinely new at 10.11) don't need new
-- schema -- their content cases run directly against session variables /
-- existing baseline objects.

-- Native UUID type: storage + comparison semantics distinct from CHAR(36).
CREATE TABLE sessions (
    id          UUID NOT NULL DEFAULT UUID(),
    author_id   INT UNSIGNED NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_sessions_author
        FOREIGN KEY (author_id) REFERENCES authors (id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO sessions (id, author_id) VALUES
    (UUID(), 1);

-- INET4 data type: native IPv4 storage (pairs with 10.5's INET6).
CREATE TABLE login_attempts (
    id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    author_id    INT UNSIGNED NOT NULL,
    client_ip    INET4 NOT NULL,
    attempted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_login_attempts_author
        FOREIGN KEY (author_id) REFERENCES authors (id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO login_attempts (author_id, client_ip) VALUES
    (1, '203.0.113.42');

-- Descending index columns: an explicit DESC column so a case can confirm
-- the index was actually created with that sort direction.
CREATE INDEX idx_articles_created_at_desc ON articles (created_at DESC);
