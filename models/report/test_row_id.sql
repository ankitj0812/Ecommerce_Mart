select
    {{ generate_row_id(ref('dim_customers')) }} as row_id
from {{ ref('dim_customers') }}