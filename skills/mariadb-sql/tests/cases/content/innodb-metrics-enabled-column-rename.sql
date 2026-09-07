-- query-profiling.md claims: "Note the STATUS column was renamed ENABLED
-- (varchar -> int) at 10.4." Live-checked against this harness's own
-- images: the ENABLED column is unrecognized on 10.4 (10.4.34-MariaDB,
-- "Unknown column 'ENABLED' in 'field list'") and only starts working
-- from 10.5 onward here, so tagged 10.5 rather than 10.4 as the reference
-- doc's prose claims. Per harness convention we only assert
-- forward-availability of the new column name from its actual minimum
-- version onward -- not that the old name errors before it.
SELECT ENABLED FROM information_schema.INNODB_METRICS LIMIT 1;
