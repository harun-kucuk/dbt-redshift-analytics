with source as (
    select * from {{ source('tickit', 'date') }}
)

select
    dateid          as date_id,
    caldate         as date,
    day,
    week,
    month,
    qtr             as quarter,
    year,
    holiday         as is_holiday
from source
