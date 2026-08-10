CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${bronze_schema}.franchises
COMMENT 'Raw Bakehouse franchise master data with ingestion metadata'
AS
SELECT
  franchiseID,
  name,
  city,
  district,
  zipcode,
  country,
  size,
  longitude,
  latitude,
  supplierID,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_franchises' AS _source_table
FROM samples.bakehouse.sales_franchises;
