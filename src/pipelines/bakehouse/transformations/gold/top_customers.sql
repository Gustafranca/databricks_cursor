CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${gold_schema}.top_customers
COMMENT 'Customer lifetime sales ranking'
AS
SELECT
  customer_id,
  customer_name,
  customer_country AS country,
  COUNT(DISTINCT transaction_id) AS orders,
  SUM(quantity) AS units_purchased,
  SUM(total_price) AS revenue,
  SUM(total_price) / COUNT(DISTINCT transaction_id) AS average_ticket,
  MIN(transaction_date) AS first_purchase_date,
  MAX(transaction_date) AS last_purchase_date
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY customer_id, customer_name, customer_country;
