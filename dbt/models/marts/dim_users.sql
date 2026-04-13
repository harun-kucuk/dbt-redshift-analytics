with base as (
    select * from {{ ref('int_user_stats') }}
)

select
    user_id,
    first_name,
    last_name,
    city,
    likes_sports,
    likes_concerts,
    likes_theatre,
    likes_broadway,
    likes_musicals,
    total_purchases,
    total_spent,
    avg_order_value,
    first_purchase_at,
    last_purchase_at,
    total_sales,
    total_earned,
    total_listings,
    total_listed_value,
    avg_ticket_price
from base
