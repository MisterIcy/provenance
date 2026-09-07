-- optimizer-internals.md claims: "SET optimizer_trace='enabled=on'; <run
-- statement>; SELECT * FROM information_schema.OPTIMIZER_TRACE;" surfaces
-- structured JSON explaining plan choices. Verify the round-trip succeeds
-- and the trace output contains recognizable trace JSON. Live-checked:
-- `optimizer_trace` is an unknown system variable against our 10.2/10.3
-- containers (this harness's own images, not necessarily every MariaDB
-- 10.2/10.3 build) and only starts working from 10.4 onward here, so
-- tagged 10.4 rather than left untagged as the reference doc's prose might
-- otherwise suggest.
SET optimizer_trace='enabled=on';
SELECT 1;
SELECT * FROM information_schema.OPTIMIZER_TRACE;
