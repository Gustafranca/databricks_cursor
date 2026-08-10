CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${gold_schema}.sales_by_country
CLUSTER BY (sales_date, country)
COMMENT 'Daily sales KPIs by country'
AS
SELECT
  transaction_date AS sales_date,
  franchise_country AS country,
  COUNT(DISTINCT transaction_id) AS orders,
  COUNT(DISTINCT franchise_id) AS active_franchises,
  SUM(quantity) AS units_sold,
  SUM(total_price) AS revenue,
  SUM(total_price) / COUNT(DISTINCT transaction_id) AS average_ticket
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY transaction_date, franchise_country;
