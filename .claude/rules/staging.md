---
paths: ["dbt/models/staging/**"]
---

# Staging Layer Rules

Schema: `staging_tickit`
Materialization: `view` with `bind: false` — set in `dbt/dbt_project.yml`, not in the SQL file
Naming: `stg_<source>__<table>`

## Allowed
- Rename columns to consistent snake_case names
- Cast data types (e.g. `::date`, `::numeric`)
- Simple `coalesce` for null handling
- Select all columns from a single source table

## Not Allowed
- Joins between tables
- Aggregations (`group by`, `sum`, `count`)
- Business logic or calculations
- Referencing other dbt models via `{{ ref() }}`
- Using `{{ source() }}` for anything other than the direct source table

## Pattern
```sql
with source as (
    select * from {{ source('tickit', '<table>') }}
)

select
    <original_col>  as <renamed_col>,
    ...
from source
```

## Example
```sql
with source as (
    select * from {{ source('tickit', 'sales') }}
)

select
    salesid     as sale_id,
    pricepaid   as price_paid,
    commission,
    saletime    as sale_at
from source
```
