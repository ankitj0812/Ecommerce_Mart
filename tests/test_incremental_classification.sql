WITH source_data AS (

    SELECT
        CUSTOMER_ID,
        CUSTOMER_NAME,
        CITY,
        STATUS,
        EMAIL,

        {{ generate_row_id(
            'source_data',
            column_names=[
                'CUSTOMER_ID',
                'CUSTOMER_NAME',
                'CITY',
                'STATUS',
                'EMAIL'
            ]
        ) }} AS ROW_ID

    FROM {{ ref('stg_customer') }}

),

target_data AS (

    SELECT
        CUSTOMER_ID,
        ROW_ID
    FROM {{ ref('dim_customer') }}

)

SELECT
    s.CUSTOMER_ID,
    s.ROW_ID AS SOURCE_ROW_ID,
    t.ROW_ID AS TARGET_ROW_ID,

    CASE

        WHEN t.CUSTOMER_ID IS NOT NULL
             AND s.ROW_ID = t.ROW_ID
            THEN 'UNCHANGED'

        WHEN t.CUSTOMER_ID IS NOT NULL
             AND s.ROW_ID <> t.ROW_ID
            THEN 'MODIFIED'

        WHEN t.CUSTOMER_ID IS NULL
             AND EXISTS (
                 SELECT 1
                 FROM target_data t2
                 WHERE t2.ROW_ID = s.ROW_ID
             )
            THEN 'NEW_PK_SAME_ROW_ID'

        ELSE 'NEW_RECORD'

    END AS EXPECTED_STATUS

FROM source_data s

LEFT JOIN target_data t
    ON s.CUSTOMER_ID = t.CUSTOMER_ID

WHERE 1 = 0