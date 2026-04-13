-- Singular test: net_revenue must never be negative in fct_sales
select *
from {{ ref('fct_sales') }}
where net_revenue < 0
