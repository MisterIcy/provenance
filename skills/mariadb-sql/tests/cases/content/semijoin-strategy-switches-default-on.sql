-- optimizer-internals.md claims: "Governed by the top-level optimizer_switch
-- flag semijoin (on since 5.3)" and that firstmatch, loosescan, and
-- materialization are semi-join strategies the optimizer picks among.
-- Verify all four flags report =on in optimizer_switch (applies across the
-- whole 10.2+ matrix).
SELECT @@optimizer_switch;
