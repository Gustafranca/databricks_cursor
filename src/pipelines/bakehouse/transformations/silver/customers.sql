CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${silver_schema}.customers (
    CONSTRAINT customer_id_required EXPECT (customer_id IS NOT NULL)
      ON VIOLATION FAIL UPDATE,
    CONSTRAINT valid_email EXPECT (email_address LIKE '%@%'),
    CONSTRAINT country_required EXPECT (country IS NOT NULL)
      ON VIOLATION DROP ROW
  )
COMMENT 'Cleaned and conformed Bakehouse customers'
AS
SELECT
  CAST(customerID AS BIGINT) AS customer_id,
  INITCAP(TRIM(first_name)) AS first_name,
  INITCAP(TRIM(last_name)) AS last_name,
  CONCAT(INITCAP(TRIM(first_name)), ' ', INITCAP(TRIM(last_name))) AS customer_name,
  LOWER(TRIM(email_address)) AS email_address,
  TRIM(phone_number) AS phone_number,
  TRIM(address) AS address,
  INITCAP(TRIM(city)) AS city,
  INITCAP(TRIM(state)) AS state,
  CASE
    WHEN UPPER(TRIM(country)) IN ('US', 'USA') THEN 'United States'
    ELSE INITCAP(TRIM(country))
  END AS country,
  INITCAP(TRIM(continent)) AS continent,
  CAST(postal_zip_code AS STRING) AS postal_code,
  LOWER(TRIM(gender)) AS gender
FROM ${medallion_catalog}.${bronze_schema}.customers;
