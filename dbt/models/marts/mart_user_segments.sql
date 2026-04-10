select
    user_id,
    username,
    city,
    state,
    total_purchases,
    total_spent,
    avg_order_value,
    total_sales,
    total_earned,
    total_listings,
    case
        when total_spent >= 500             then 'VIP'
        when total_spent >= 200             then 'Regular'
        when total_spent > 0               then 'Occasional'
        else                                    'Inactive'
    end                                     as buyer_segment,
    case
        when total_listings >= 5            then 'Power Seller'
        when total_listings >= 2            then 'Active Seller'
        when total_listings = 1             then 'New Seller'
        else                                    'Buyer Only'
    end                                     as seller_segment,
    case
        when likes_sports                   then 'Sports'
        when likes_concerts                 then 'Concerts'
        when likes_theatre or likes_broadway or likes_musicals then 'Shows'
        else                                    'General'
    end                                     as interest_segment
from {{ ref('int_user_stats') }}
