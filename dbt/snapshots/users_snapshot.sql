{% snapshot users_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='user_id',
        strategy='check',
        check_cols=['likes_sports', 'likes_concerts', 'likes_theatre', 'likes_broadway', 'likes_musicals', 'city', 'state']
    )
}}

select * from {{ ref('stg_tickit__users') }}

{% endsnapshot %}
