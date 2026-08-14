{% macro generate_row_id(relation, exclude_columns=[]) %}
    {% set columns = adapter.get_columns_in_relation(relation) %}
    {% set excluded = exclude_columns | map('upper') | list %}
    {% set hash_columns = [] %}
    {% for column in columns %}
        {% if column.name | upper not in excluded %}
            {% do hash_columns.append(
                "COALESCE(TO_VARCHAR(" ~ adapter.quote(column.name) ~ "), 'xyz')"
            ) %}
        {% endif %}
    {% endfor%}

    MD5(CONCAT_WS('|', {{ hash_columns | join(',\n            ') }}))

{% endmacro %}