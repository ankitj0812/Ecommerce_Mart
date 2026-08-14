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

),
actual AS (
    SELECT
        CUSTOMER_ID,
        ROW_ID
    FROM {{ ref('stg_customer_with_row_id') }}
)
SELECT
    actual.CUSTOMER_ID,
    expected.EXPECTED_ROW_ID,
    actual.ROW_ID
FROM actual
JOIN expected
    ON actual.CUSTOMER_ID = expected.CUSTOMER_ID
WHERE actual.ROW_ID <> expected.EXPECTED_ROW_ID