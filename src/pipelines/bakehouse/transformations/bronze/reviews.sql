CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${bronze_schema}.reviews
COMMENT 'Raw Bakehouse customer reviews with ingestion metadata'
AS
SELECT
  review,
  franchiseID,
  review_date,
  new_id,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.media_customer_reviews' AS _source_table
FROM samples.bakehouse.media_customer_reviews;
