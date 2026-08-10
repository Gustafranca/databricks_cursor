CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${silver_schema}.transactions (
    CONSTRAINT transaction_id_required EXPECT (transaction_id IS NOT NULL)
      ON VIOLATION FAIL UPDATE,
    CONSTRAINT valid_quantity EXPECT (quantity > 0)
      ON VIOLATION DROP ROW,
    CONSTRAINT valid_prices EXPECT (
      unit_price >= 0
      AND total_price >= 0
      AND total_price = quantity * unit_price
    ) ON VIOLATION DROP ROW,
    CONSTRAINT valid_transaction_date EXPECT (
      transaction_date IS NOT NULL
      AND transaction_date <= current_date()
    ) ON VIOLATION DROP ROW,
    CONSTRAINT matched_franchise EXPECT (franchise_name IS NOT NULL),
    CONSTRAINT matched_customer EXPECT (customer_name IS NOT NULL)
  )
CLUSTER BY (transaction_date, franchise_id)
COMMENT 'Conformed transactions enriched with franchise and customer dimensions'
AS
SELECT
  CAST(t.transactionID AS BIGINT) AS transaction_id,
  CAST(t.customerID AS BIGINT) AS customer_id,
  c.customer_name,
  c.country AS customer_country,
  CAST(t.franchiseID AS BIGINT) AS franchise_id,
  f.franchise_name,
  f.city AS franchise_city,
  f.country AS franchise_country,
  f.latitude,
  f.longitude,
  CAST(t.dateTime AS TIMESTAMP) AS transaction_timestamp,
  CAST(t.dateTime AS DATE) AS transaction_date,
  CAST(DATE_TRUNC('MONTH', t.dateTime) AS DATE) AS transaction_month,
  TRIM(t.product) AS product,
  CAST(t.quantity AS BIGINT) AS quantity,
  CAST(t.unitPrice AS DECIMAL(18, 2)) AS unit_price,
  CAST(t.totalPrice AS DECIMAL(18, 2)) AS total_price,
  LOWER(TRIM(t.paymentMethod)) AS payment_method
FROM ${medallion_catalog}.${bronze_schema}.transactions AS t
LEFT JOIN ${medallion_catalog}.${silver_schema}.franchises AS f
  ON t.franchiseID = f.franchise_id
LEFT JOIN ${medallion_catalog}.${silver_schema}.customers AS c
  ON t.customerID = c.customer_id;
