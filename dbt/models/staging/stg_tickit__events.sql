with source as (
    select * from {{ source('tickit', 'event') }}
)

-- These are lightweight renames so downstream models can stay warehouse-agnostic.
select
    eventid         as event_id,
    venueid         as venue_id,
    catid           as category_id,
    dateid          as date_id,
    eventname       as event_name,
    starttime       as start_at
from source
