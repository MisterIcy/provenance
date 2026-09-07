-- Additive schema for MariaDB 10.5+, applied after 00-baseline-schema.sql
-- (and any 10.3/10.4 deltas). Introduces fixtures for 10.5-only features
-- per references/version-features.md:
--   - RETURNING clause on INSERT/REPLACE (10.5)
--   - CYCLE clause for recursive-CTE cycle detection (10.5)
--   - WITHOUT OVERLAPS constraint for application-time period tables (10.5)

-- Table for exercising INSERT ... RETURNING.
CREATE TABLE tags (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name        VARCHAR(100) NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_tags_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table for exercising a recursive CTE with a CYCLE clause. A simple
-- employee/manager graph where a cycle is possible if the data is corrupt.
CREATE TABLE org_chart (
    id          INT UNSIGNED NOT NULL,
    manager_id  INT UNSIGNED NULL,
    name        VARCHAR(100) NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO org_chart (id, manager_id, name) VALUES
    (1, NULL, 'Ada'),
    (2, 1, 'Grace'),
    (3, 2, 'Linus'),
    (4, 3, 'Margaret');

-- Table for exercising WITHOUT OVERLAPS: an application-time period table
-- where (room_id, valid_period) must not overlap for the same room.
CREATE TABLE room_bookings (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    room_id     INT UNSIGNED NOT NULL,
    start_date  DATE NOT NULL,
    end_date    DATE NOT NULL,
    PRIMARY KEY (id),
    PERIOD FOR valid_period (start_date, end_date),
    UNIQUE KEY uq_room_bookings_no_overlap (room_id, valid_period WITHOUT OVERLAPS)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO room_bookings (room_id, start_date, end_date) VALUES
    (101, '2026-01-01', '2026-01-10');
