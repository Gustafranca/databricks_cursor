CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${bronze_schema}.suppliers
COMMENT 'Raw Bakehouse supplier master data with ingestion metadata'
AS
SELECT
  supplierID,
  name,
  ingredient,
  continent,
  city,
  district,
  size,
  longitude,
  latitude,
  approved,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_suppliers' AS _source_table
FROM samples.bakehouse.sales_suppliers;
