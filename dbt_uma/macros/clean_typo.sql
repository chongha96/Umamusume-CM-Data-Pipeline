{% macro clean_uma_name(column_name) %}
    case
        when {{ column_name }} = 'Tamamo Corss' then 'Tamamo Cross'
        when {{ column_name }} = 'TM Opera O' then 'T.M. Opera O'
        when {{ column_name }} = 'Miho Bourbon (Valentine)' then 'Mihono Bourbon (Valentine)'
        else {{ column_name }}
    end
{% endmacro %}