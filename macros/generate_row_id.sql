{% macro generate_row_id(
    relation,
    column_names=[]
) -%}

    {%- set audit_columns = var('audit_columns', []) | map('upper') | list -%}

    {%- if column_names | length > 0 -%}
        {%- set columns = column_names -%}
    {%- else -%}
        {%- set relation_columns = adapter.get_columns_in_relation(relation) -%}
        {%- set columns = [] -%}

        {%- for column in relation_columns -%}
            {%- do columns.append(column.name) -%}
        {%- endfor -%}
    {%- endif -%}

    {%- set hash_columns = [] -%}

    {%- for column in columns -%}
        {%- if column | upper not in audit_columns -%}
            {%- do hash_columns.append(
                "COALESCE(TO_VARCHAR(" ~ adapter.quote(column) ~ "), 'xyz')"
            ) -%}
        {%- endif -%}
    {%- endfor -%}

    MD5(
        CONCAT_WS(
            '|',
            {{ hash_columns | join(',\n            ') }}
        )
    )

{%- endmacro %}
