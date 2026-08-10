CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${gold_schema}.sentiment_by_franchise
CLUSTER BY (review_date, franchise_id)
COMMENT 'Daily customer-review sentiment by franchise'
AS
SELECT
  review_date,
  franchise_id,
  franchise_name,
  city,
  country,
  sentiment,
  COUNT(*) AS review_count
FROM ${medallion_catalog}.${silver_schema}.reviews_sentiment
GROUP BY
  review_date,
  franchise_id,
  franchise_name,
  city,
  country,
  sentiment;
