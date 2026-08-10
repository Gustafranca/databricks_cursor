CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${gold_schema}.franchise_performance
COMMENT 'All-time performance and geolocation by franchise'
AS
SELECT
  franchise_id,
  franchise_name,
  franchise_city AS city,
  franchise_country AS country,
  latitude,
  longitude,
  COUNT(DISTINCT transaction_id) AS orders,
  SUM(quantity) AS units_sold,
  SUM(total_price) AS revenue,
  SUM(total_price) / COUNT(DISTINCT transaction_id) AS average_ticket,
  MIN(transaction_date) AS first_sale_date,
  MAX(transaction_date) AS last_sale_date
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY
  franchise_id,
  franchise_name,
  franchise_city,
  franchise_country,
  latitude,
  longitude;
