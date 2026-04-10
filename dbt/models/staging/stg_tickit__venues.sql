with source as (
    select * from {{ source('tickit', 'venue') }}
)

select
    venueid         as venue_id,
    venuename       as venue_name,
    venuecity       as city,
    venuestate      as state,
    venueseats      as seats
from source
