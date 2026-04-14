Scaffold a new dbt model for this project.

Arguments: $ARGUMENTS — `<layer> <entity> <description>` e.g. `staging sales Raw sales transactions`
If not provided, ask for layer, entity name, and a brief description.

Rules by layer:

**staging** → `dbt/models/staging/stg_tickit__<entity>.sql`, schema `staging_tickit`, one source table only
```sql
with source as (
    select * from {{ source('tickit', '<entity>') }}
)
select
    <col> as <renamed>,
    ...
from source
```

**intermediate** → `dbt/models/intermediate/int_<entity>_<verb>.sql`, schema `intermediate`, joins allowed
```sql
with <a> as (select * from {{ ref('stg_tickit__<a>') }}),
     <b> as (select * from {{ ref('stg_tickit__<b>') }})
select ... from <a> join <b> on ...
```

**fact** → `dbt/models/marts/fct_<entity>.sql`, schema `marts`, one row per event
**dimension** → `dbt/models/marts/dim_<entity>.sql`, schema `marts`, one row per entity
**aggregate** → `dbt/models/marts/mart_<topic>.sql`, schema `marts`, pre-aggregated rollup

After creating the SQL file, add an entry to the layer's `_models.yml` with:
- Model-level description
- All output columns with descriptions
- `not_null` + `unique` on the primary key
- `is_positive` on any price, amount, or quantity columns
- `{{ safe_divide() }}` macro for any ratio calculations
