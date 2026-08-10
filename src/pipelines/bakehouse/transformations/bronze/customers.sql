CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${bronze_schema}.customers
COMMENT 'Raw Bakehouse customer master data with ingestion metadata'
AS
SELECT
  customerID,
  first_name,
  last_name,
  email_address,
  phone_number,
  address,
  city,
  state,
  country,
  continent,
  postal_zip_code,
  gender,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_customers' AS _source_table
FROM samples.bakehouse.sales_customers;
