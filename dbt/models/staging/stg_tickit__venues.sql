with source as (
    select * from {{ source('tickit', 'venue') }}
)

-- Preserve venue grain and expose consistent column names for marts.
select
    venueid         as venue_id,
    venuename       as venue_name,
    venuecity       as city,
    venuestate      as state,
    venueseats      as seats
from source
