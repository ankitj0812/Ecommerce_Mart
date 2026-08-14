SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    STATUS,
    EMAIL,

    {{ generate_row_id(
        ref('stg_customers'),
        exclude_columns=[
            'STG_CREATED_DATE',
            'STG_UPDATED_DATE'
        ]
    ) }} AS ROW_ID,

    STG_CREATED_DATE,
    STG_UPDATED_DATE

FROM {{ ref('stg_customers') }}