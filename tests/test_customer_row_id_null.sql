SELECT
    CUSTOMER_ID,
    ROW_ID
FROM {{ ref('stg_customer_with_row_id') }}
WHERE ROW_ID IS NULL