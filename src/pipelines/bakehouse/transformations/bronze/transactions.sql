CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${bronze_schema}.transactions
COMMENT 'Raw Bakehouse sales transactions with ingestion metadata'
AS
SELECT
  transactionID,
  customerID,
  franchiseID,
  dateTime,
  product,
  quantity,
  unitPrice,
  totalPrice,
  paymentMethod,
  cardNumber,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_transactions' AS _source_table
FROM samples.bakehouse.sales_transactions;
