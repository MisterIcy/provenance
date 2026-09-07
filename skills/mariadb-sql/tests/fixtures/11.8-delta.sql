-- Additive schema for MariaDB 11.8+, applied after 00-baseline-schema.sql
-- (and any 10.3-11.4 deltas). Introduces fixtures for 11.8-only features
-- per references/version-features.md:
--   - VECTOR column type + VECTOR INDEX, with the VEC_DISTANCE* function
--     family finalized as a stable, documented surface at 11.8 (the type
--     itself landed at 11.6, search at 11.7 -- 11.8 is where the full
--     column+index+function surface is first fully documented/stable).

-- Table for exercising VECTOR column storage, a VECTOR INDEX, and the
-- VEC_DISTANCE*/VEC_FromText/VEC_ToText function family.
CREATE TABLE embeddings (
    id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    label   VARCHAR(64) NOT NULL,
    v       VECTOR(4) NOT NULL,
    PRIMARY KEY (id),
    VECTOR INDEX (v)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO embeddings (label, v) VALUES
    ('a', VEC_FromText('[1,0,0,0]')),
    ('b', VEC_FromText('[0,1,0,0]')),
    ('c', VEC_FromText('[1,1,0,0]'));
