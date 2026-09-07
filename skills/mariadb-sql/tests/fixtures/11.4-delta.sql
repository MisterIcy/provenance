-- Additive schema for MariaDB 11.4+, applied after 00-baseline-schema.sql
-- (and any 10.3/10.4/10.5/10.6/10.11 deltas present). Introduces fixtures
-- for 11.4-only features per references/version-features.md:
--   - Descending indexes usable for MIN()/MAX() (11.4)
--   - EXCHANGE PARTITION ... WITH VALIDATION (11.4)
-- The new JSON functions attributed to 11.4 (JSON_OBJECT_TO_ARRAY,
-- JSON_OBJECT_FILTER_KEYS, etc.) are exercised directly against the
-- baseline `articles.metadata` LONGTEXT column and need no extra fixture.

-- Table for exercising a descending index being used to satisfy MAX()
-- without a table scan (verified via EXPLAIN in the content case).
CREATE TABLE score_events (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    score       INT NOT NULL,
    PRIMARY KEY (id),
    KEY idx_score_desc (score DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO score_events (score) VALUES (5), (3), (9), (1), (7);

-- Partitioned table + a plain source table for exercising
-- ALTER TABLE ... EXCHANGE PARTITION ... WITH VALIDATION.
CREATE TABLE partitioned_orders (
    id      INT NOT NULL,
    amount  INT NOT NULL
) ENGINE=InnoDB
PARTITION BY RANGE (id) (
    PARTITION p0 VALUES LESS THAN (100),
    PARTITION p1 VALUES LESS THAN (200)
);

CREATE TABLE order_exchange_src (
    id      INT NOT NULL,
    amount  INT NOT NULL
) ENGINE=InnoDB;

INSERT INTO order_exchange_src VALUES (5, 500);
