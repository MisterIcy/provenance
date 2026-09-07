-- version-features.md claims: "System-versioned tables ... WITHOUT OVERLAPS
-- for application-time periods added 10.5" and "WITHOUT OVERLAPS constraint
-- for application-time period tables". Verify a UNIQUE(..., period WITHOUT
-- OVERLAPS) constraint actually rejects an overlapping insert for the same
-- room_id on a 10.5 server (fixture seeds room 101 booked 2026-01-01..10).
INSERT INTO room_bookings (room_id, start_date, end_date)
VALUES (101, '2026-01-05', '2026-01-15');
