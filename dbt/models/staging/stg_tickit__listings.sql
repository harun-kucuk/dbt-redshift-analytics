with source as (
    select * from {{ source('tickit', 'listing') }}
)

select
    listid              as listing_id,
    sellerid            as seller_id,
    eventid             as event_id,
    dateid              as date_id,
    numtickets          as num_tickets,
    priceperticket      as price_per_ticket,
    totalprice          as total_price,
    listtime            as listed_at
from source
