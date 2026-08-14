WITH expected AS (
    SELECT
        CUSTOMER_ID,
        MD5(
            CONCAT_WS(
                '|',
                COALESCE(TO_VARCHAR(CUSTOMER_ID), 'xyz'),
                COALESCE(TO_VARCHAR(CUSTOMER_NAME), 'xyz'),
                COALESCE(TO_VARCHAR(CITY), 'xyz'),
                COALESCE(TO_VARCHAR(STATUS), 'xyz'),
                COALESCE(TO_VARCHAR(EMAIL), 'xyz')
            )
        ) AS EXPECTED_ROW_ID
    FROM {{ ref('stg_customer_with_row_id') }}
)
SELECT
    CUSTOMER_ID,
    EXPECTED_ROW_ID,
    ROW_ID
FROM {{ ref('stg_customer_with_row_id') }}
JOIN expected
    USING (CUSTOMER_ID)
WHERE ROW_ID <> EXPECTED_ROW_ID