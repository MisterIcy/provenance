-- version-features.md claims (11.4): "EXCHANGE PARTITION/CONVERT TABLE
-- gain WITH VALIDATION/WITHOUT VALIDATION." Verify the WITH VALIDATION
-- clause is accepted and the exchange actually moves the source table's
-- row into the target partition.
ALTER TABLE partitioned_orders
    EXCHANGE PARTITION p0 WITH TABLE order_exchange_src WITH VALIDATION;

SELECT * FROM partitioned_orders;
