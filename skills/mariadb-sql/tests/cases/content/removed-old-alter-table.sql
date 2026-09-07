-- version-features.md claims (11.4): "Removed: engine_condition_pushdown,
-- date_format/datetime_format/time_format/max_tmp_tables, old_alter_table,
-- innodb_defragment, wsrep_causal_reads." Verify old_alter_table no
-- longer exists as a system variable.
SELECT @@old_alter_table;
