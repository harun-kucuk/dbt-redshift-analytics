with source as (
    select * from {{ source('tickit', 'category') }}
)

select
    catid           as category_id,
    catgroup        as category_group,
    catname         as category_name,
    catdesc         as category_description
from source
