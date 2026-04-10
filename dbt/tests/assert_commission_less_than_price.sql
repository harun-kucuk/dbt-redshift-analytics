-- Singular test: commission must always be less than price paid
select *
from {{ ref('fct_sales') }}
where commission >= price_paid
