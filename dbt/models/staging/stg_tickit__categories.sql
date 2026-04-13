with source as (
    select * from {{ source('tickit', 'category') }}
)

-- Keep the staging model close to the source while standardizing names.
select
    catid           as category_id,
    catgroup        as category_group,
    catname         as category_name,
    catdesc         as category_description
from source
