CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${gold_schema}.sales_by_product
CLUSTER BY (sales_date, product)
COMMENT 'Daily product and payment-method sales mix'
AS
SELECT
  transaction_date AS sales_date,
  product,
  payment_method,
  COUNT(DISTINCT transaction_id) AS orders,
  SUM(quantity) AS units_sold,
  SUM(total_price) AS revenue,
  SUM(total_price) / COUNT(DISTINCT transaction_id) AS average_ticket
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY transaction_date, product, payment_method;
