CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${silver_schema}.franchises (
    CONSTRAINT franchise_id_required EXPECT (franchise_id IS NOT NULL)
      ON VIOLATION FAIL UPDATE,
    CONSTRAINT valid_coordinates EXPECT (
      latitude BETWEEN -90 AND 90
      AND longitude BETWEEN -180 AND 180
    ) ON VIOLATION DROP ROW,
    CONSTRAINT country_required EXPECT (country IS NOT NULL)
      ON VIOLATION DROP ROW
  )
COMMENT 'Cleaned and conformed Bakehouse franchises'
AS
SELECT
  CAST(franchiseID AS BIGINT) AS franchise_id,
  TRIM(name) AS franchise_name,
  INITCAP(TRIM(city)) AS city,
  INITCAP(TRIM(district)) AS district,
  TRIM(zipcode) AS postal_code,
  CASE
    WHEN UPPER(TRIM(country)) IN ('US', 'USA') THEN 'United States'
    ELSE INITCAP(TRIM(country))
  END AS country,
  UPPER(TRIM(size)) AS franchise_size,
  CAST(longitude AS DOUBLE) AS longitude,
  CAST(latitude AS DOUBLE) AS latitude,
  CAST(supplierID AS BIGINT) AS supplier_id
FROM ${medallion_catalog}.${bronze_schema}.franchises;
