-- optimizer-internals.md claims: "index_merge_sort_intersection -- off by
-- default (5.3+; the added sort step usually isn't worth it)". Verify the
-- flag reports =off in optimizer_switch (applies across the whole 10.2+
-- matrix).
SELECT @@optimizer_switch;
