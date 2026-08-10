CREATE OR REFRESH MATERIALIZED VIEW
  ${medallion_catalog}.${silver_schema}.reviews_sentiment (
    CONSTRAINT review_id_required EXPECT (review_id IS NOT NULL)
      ON VIOLATION FAIL UPDATE,
    CONSTRAINT review_text_required EXPECT (
      review_text IS NOT NULL AND LENGTH(TRIM(review_text)) > 0
    ) ON VIOLATION DROP ROW,
    CONSTRAINT matched_review_franchise EXPECT (franchise_name IS NOT NULL),
    CONSTRAINT valid_sentiment EXPECT (
      sentiment IN ('positive', 'negative', 'neutral', 'mixed')
    )
  )
COMMENT 'Customer reviews enriched with AI-generated sentiment'
AS
SELECT
  CAST(r.new_id AS BIGINT) AS review_id,
  CAST(r.franchiseID AS BIGINT) AS franchise_id,
  f.franchise_name,
  f.city,
  f.country,
  CAST(r.review_date AS TIMESTAMP) AS review_timestamp,
  CAST(r.review_date AS DATE) AS review_date,
  TRIM(r.review) AS review_text,
  LOWER(ai_analyze_sentiment(r.review)) AS sentiment
FROM ${medallion_catalog}.${bronze_schema}.reviews AS r
LEFT JOIN ${medallion_catalog}.${silver_schema}.franchises AS f
  ON r.franchiseID = f.franchise_id;
