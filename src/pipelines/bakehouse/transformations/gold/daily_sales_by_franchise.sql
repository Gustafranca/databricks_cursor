CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${gold_schema}.daily_sales_by_franchise
CLUSTER BY (sales_date, franchise_id)
COMMENT 'Daily sales KPIs by franchise'
AS
SELECT
  transaction_date AS sales_date,
  franchise_id,
  franchise_name,
  franchise_city AS city,
  franchise_country AS country,
  latitude,
  longitude,
  COUNT(DISTINCT transaction_id) AS orders,
  SUM(quantity) AS units_sold,
  SUM(total_price) AS revenue,
  SUM(total_price) / COUNT(DISTINCT transaction_id) AS average_ticket
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY
  transaction_date,
  franchise_id,
  franchise_name,
  franchise_city,
  franchise_country,
  latitude,
  longitude;
