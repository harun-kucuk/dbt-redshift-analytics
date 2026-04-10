---
paths: ["dbt/models/intermediate/**"]
---

# Intermediate Layer Rules

Schema: `intermediate`
Materialization: `table`
Naming: `int_<entity>_<verb>` (e.g. `int_sales_enriched`, `int_users_aggregated`)

## Allowed
- Joins between staging models
- Business logic and calculations
- Aggregations that feed into multiple marts
- Filtering and deduplication
- Window functions

## Not Allowed
- Referencing `{{ source() }}` directly — always ref staging via `{{ ref() }}`
- Referencing mart models (no downstream deps)
- Final presentation logic (that belongs in marts)

## Pattern
```sql
with <entity> as (
    select * from {{ ref('stg_<source>__<table>') }}
),

<other_entity> as (
    select * from {{ ref('stg_<source>__<other>') }}
)

select
    ...
from <entity>
join <other_entity> on ...
```

## Example
```sql
with sales as (
    select * from {{ ref('stg_tickit__sales') }}
),

events as (
    select * from {{ ref('stg_tickit__events') }}
)

select
    s.sale_id,
    s.price_paid,
    e.event_name,
    s.price_paid - s.commission as net_revenue
from sales s
join events e on s.event_id = e.event_id
```
