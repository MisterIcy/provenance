-- version-features.md claims: "Vector data type / vector indexing | 11.6
-- (type), 11.7 (Vector Search), 11.8 (VEC_DISTANCE_* functions,
-- LTS-stable)". Verify the `embeddings` table (fixtures/11.8-delta.sql)
-- actually got a VECTOR column plus a VECTOR INDEX on a live 11.8 server.
SHOW CREATE TABLE embeddings\G
