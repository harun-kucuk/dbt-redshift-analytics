with source as (
    select * from {{ source('tickit', 'users') }}
)

select
    userid          as user_id,
    username,
    firstname       as first_name,
    lastname        as last_name,
    city,
    state,
    email,
    phone,
    likesports      as likes_sports,
    liketheatre     as likes_theatre,
    likeconcerts    as likes_concerts,
    likejazz        as likes_jazz,
    likeclassical   as likes_classical,
    likeopera       as likes_opera,
    likerock        as likes_rock,
    likevegas       as likes_vegas,
    likebroadway    as likes_broadway,
    likemusicals    as likes_musicals
from source
