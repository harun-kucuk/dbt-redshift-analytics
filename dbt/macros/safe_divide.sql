{% macro safe_divide(numerator, denominator) %}
    case when {{ denominator }} = 0 then 0
         else {{ numerator }} / {{ denominator }}
    end
{% endmacro %}
