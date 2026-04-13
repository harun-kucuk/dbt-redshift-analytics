with source as (
    select * from {{ source('tickit', 'sales') }}
)

select
    salesid         as sale_id,
    listid          as listing_id,
    sellerid        as seller_id,
    buyerid         as buyer_id,
    eventid         as event_id,
    dateid          as date_id,
    qtysold         as quantity_sold,
    pricepaid       as price_paid,
    commission,
    saletime        as sale_at
from source
