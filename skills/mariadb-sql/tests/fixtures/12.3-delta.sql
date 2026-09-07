-- Additive schema for MariaDB 12.3+, applied after 00-baseline-schema.sql
-- (and any earlier deltas). Introduces fixtures for 12.3-only features per
-- references/version-features.md:
--   - IS JSON predicate (SQL-standard JSON validation)
--   - Associative arrays (DECLARE TYPE .. TABLE OF .. INDEX BY, Oracle-mode
--     PL/SQL syntax consolidated at 12.3)

-- Table for exercising IS JSON against stored text: some rows hold valid
-- JSON (object/array), some hold text that is not valid JSON at all.
CREATE TABLE json_documents (
    id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    label   VARCHAR(100) NOT NULL,
    payload LONGTEXT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO json_documents (label, payload) VALUES
    ('valid_object', '{"tags": ["math"], "views": 120}'),
    ('valid_array', '[1, 2, 3]'),
    ('invalid_text', 'not json at all'),
    ('invalid_truncated', '{"a": 1');

-- Associative-array procedure (Oracle-mode PL/SQL syntax): builds a
-- VARCHAR-indexed table of INT and returns the sum of its elements via an
-- OUT parameter. Requires sql_mode=ORACLE to compile (the "TYPE .. IS TABLE
-- OF .. INDEX BY" declaration and "param OUT type" parameter order are both
-- Oracle-mode-only syntax); once created, CALLing it does not require
-- ORACLE mode to be set in the caller's session.
SET sql_mode=ORACLE;

DELIMITER $$
CREATE PROCEDURE assoc_array_total(total OUT INT)
AS
  TYPE score_map IS TABLE OF INT INDEX BY VARCHAR(50);
  scores score_map;
BEGIN
  scores('ada') := 10;
  scores('grace') := 20;
  scores('linus') := 30;
  total := scores('ada') + scores('grace') + scores('linus');
END$$
DELIMITER ;
