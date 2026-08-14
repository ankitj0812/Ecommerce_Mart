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

target_by_pk AS (

    SELECT
        CUSTOMER_ID,
        ROW_ID,
        CREATED_DATE,
        MODIFIED_DATE

    FROM {{ this }}

),

source_enriched AS (

    SELECT
        s.*,
        t.ROW_ID AS TARGET_ROW_ID,
        t.CREATED_DATE AS TARGET_CREATED_DATE,
        t.MODIFIED_DATE AS TARGET_MODIFIED_DATE

    FROM source_with_row_id s

    LEFT JOIN target_by_pk t
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

        WHEN TARGET_ROW_ID IS NOT NULL
             AND ROW_ID = TARGET_ROW_ID
            THEN TARGET_CREATED_DATE

        WHEN TARGET_ROW_ID IS NOT NULL
             AND ROW_ID <> TARGET_ROW_ID
            THEN TARGET_CREATED_DATE

        ELSE CURRENT_TIMESTAMP()

    END AS CREATED_DATE,

    CASE

        WHEN TARGET_ROW_ID IS NOT NULL
             AND ROW_ID = TARGET_ROW_ID
            THEN TARGET_MODIFIED_DATE

        ELSE CURRENT_TIMESTAMP()

    END AS MODIFIED_DATE

FROM source_enriched

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