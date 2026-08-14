{{ config(
    materialized='incremental',
    schema='REPORT',
    unique_key='CUSTOMER_ID',
    incremental_strategy='merge'
) }}

WITH source_data AS (

    SELECT
        CUSTOMER_ID,
        CUSTOMER_NAME,
        CITY,
        STATUS,
        EMAIL

    FROM {{ ref('stg_customers') }}

),

source_with_row_id AS (

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

    FROM source_data

)

{% if is_incremental() %}

,

target_data AS (

    SELECT
        CUSTOMER_ID,
        ROW_ID,
        CREATED_DATE,
        MODIFIED_DATE

    FROM {{ this }}

),

classified AS (

    SELECT
        s.*,

        t.CUSTOMER_ID AS TARGET_CUSTOMER_ID,
        t.ROW_ID AS TARGET_ROW_ID,
        t.CREATED_DATE AS TARGET_CREATED_DATE,
        t.MODIFIED_DATE AS TARGET_MODIFIED_DATE,

        CASE

            /* PK exists and business data has not changed */
            WHEN t.CUSTOMER_ID IS NOT NULL
                 AND s.ROW_ID = t.ROW_ID
            THEN 'UNCHANGED'

            /* PK exists but business data has changed */
            WHEN t.CUSTOMER_ID IS NOT NULL
                 AND s.ROW_ID <> t.ROW_ID
            THEN 'MODIFIED'

            /* PK is new but the same business state exists */
            WHEN t.CUSTOMER_ID IS NULL
                 AND EXISTS (
                     SELECT 1
                     FROM target_data t2
                     WHERE t2.ROW_ID = s.ROW_ID
                 )
            THEN 'NEW_PK_SAME_ROW_ID'

            /* Completely new record */
            ELSE 'NEW_RECORD'

        END AS RECORD_STATUS

    FROM source_with_row_id s

    LEFT JOIN target_data t
        ON s.CUSTOMER_ID = t.CUSTOMER_ID

)

SELECT

    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    STATUS,
    EMAIL,
    ROW_ID,

    CASE

        WHEN RECORD_STATUS = 'UNCHANGED'
            THEN TARGET_CREATED_DATE

        WHEN RECORD_STATUS = 'MODIFIED'
            THEN TARGET_CREATED_DATE

        ELSE CURRENT_TIMESTAMP()

    END AS CREATED_DATE,

    CASE

        WHEN RECORD_STATUS = 'UNCHANGED'
            THEN TARGET_MODIFIED_DATE

        ELSE CURRENT_TIMESTAMP()

    END AS MODIFIED_DATE

FROM classified

{% else %}

SELECT

    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    STATUS,
    EMAIL,
    ROW_ID,

    CURRENT_TIMESTAMP() AS CREATED_DATE,

    CURRENT_TIMESTAMP() AS MODIFIED_DATE

FROM source_with_row_id

{% endif %}