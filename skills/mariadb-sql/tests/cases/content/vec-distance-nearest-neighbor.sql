-- version-features.md claims 11.8 finalizes the vector-search surface with
-- VEC_FromText/VEC_ToText/VEC_DISTANCE_COSINE/VEC_DISTANCE_EUCLIDEAN/
-- VEC_DISTANCE. Verify VEC_DISTANCE(), used against an indexed VECTOR
-- column, actually returns the nearest row (the exact-match vector at
-- distance 0) rather than erroring or returning a nonsense value.
SELECT label, VEC_DISTANCE(v, VEC_FromText('[1,0,0,0]')) AS d
FROM embeddings
ORDER BY d
LIMIT 1;
