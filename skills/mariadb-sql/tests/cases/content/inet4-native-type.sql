-- version-features.md, 10.11 section: consolidates 10.10's "new INET4 data
-- type (native IPv4 storage, pairs with 10.5's INET6)" into the LTS train.
-- Verify a value round-trips through the fixtures/10.11-delta.sql
-- `login_attempts.client_ip` INET4 column on a live server.
SELECT client_ip FROM login_attempts WHERE author_id = 1;
