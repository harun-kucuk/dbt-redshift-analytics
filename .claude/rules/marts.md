---
paths: ["dbt/models/marts/**"]
---

# Marts Layer Rules

Schema: `marts`
Materialization: `table`
Naming:
- Facts: `fct_<entity>` (e.g. `fct_sales`)
- Dimensions: `dim_<entity>` (e.g. `dim_users`)
- Aggregates: `mart_<topic>` (e.g. `mart_sales_by_category`)

## Allowed
- Joining intermediate or staging models via `{{ ref() }}`
- Final aggregations and rollups
- Presentation-ready column names and types
- Derived metrics (e.g. `net_revenue`, `conversion_rate`)

## Not Allowed
- Referencing `{{ source() }}` directly
- Complex business logic that should live in intermediate
- Creating models that are only used by other mart models — use intermediate for that

## Facts (`fct_`)
Represent business events or transactions. Grain is one row per event.
```sql
-- One row per sale, enriched with dimensions
select
    s.sale_id,
    e.event_name,
    c.category_name,
    d.year,
    s.price_paid,
    s.price_paid - s.commission as net_revenue
from {{ ref('stg_tickit__sales') }} s
left join {{ ref('stg_tickit__events') }} e on s.event_id = e.event_id
...
```

## Dimensions (`dim_`)
Represent business entities. Grain is one row per entity.
```sql
-- One row per user with aggregated metrics
select
    u.user_id,
    u.first_name,
    count(s.sale_id)    as total_purchases,
    sum(s.price_paid)   as total_spent
from {{ ref('stg_tickit__users') }} u
left join {{ ref('fct_sales') }} s on u.user_id = s.buyer_id
group by 1, 2
```

## Aggregates (`mart_`)
Pre-aggregated rollups for reporting.
```sql
-- Aggregated by a business dimension
select
    year, category_name,
    count(*)        as total_sales,
    sum(net_revenue) as net_revenue
from {{ ref('fct_sales') }}
group by 1, 2
```
