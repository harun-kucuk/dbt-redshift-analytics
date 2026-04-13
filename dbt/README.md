# dbt — Redshift Analytics

Transforms the Redshift TICKIT sample dataset through a three-layer data model into analytics-ready tables.

## Layer Architecture

```
sample_data_dev.tickit
        │
        ▼
┌─────────────────────────────┐
│  staging_tickit  (views)    │  Rename & cast — no logic
│  stg_tickit__*              │
└─────────────────────────────┘
        │
        ▼
┌─────────────────────────────┐
│  intermediate  (tables)     │  Joins, business logic, aggregations
│  int_*                      │
└─────────────────────────────┘
        │
        ▼
┌─────────────────────────────┐
│  marts  (tables)            │  Analytics-ready: facts, dims, aggregates
│  fct_*  dim_*  mart_*       │
└─────────────────────────────┘
```

## Models

### Staging (`staging_tickit`)
Late-binding views over `sample_data_dev.tickit`. One model per source table — rename columns and cast types only.

| Model | Source Table | Description |
|---|---|---|
| `stg_tickit__sales` | `sales` | Ticket sale transactions |
| `stg_tickit__users` | `users` | Buyers and sellers with preferences |
| `stg_tickit__events` | `event` | Events (concerts, sports, shows) |
| `stg_tickit__venues` | `venue` | Venue name, city, state, seat count |
| `stg_tickit__listings` | `listing` | Active ticket listings |
| `stg_tickit__categories` | `category` | Event category and group |
| `stg_tickit__dates` | `date` | Date dimension |

### Intermediate (`intermediate`)
Joined and enriched tables shared across multiple mart models.

| Model | Description |
|---|---|
| `int_sales_enriched` | Sales joined with events, categories, venues, dates. Includes `net_revenue` and `commission_rate`. |
| `int_user_stats` | Per-user purchase, sales, and listing aggregations joined with user profile. |

### Marts (`marts`)

**Facts**
| Model | Grain | Description |
|---|---|---|
| `fct_sales` | One row per sale | Enriched sales — primary fact table |

**Dimensions**
| Model | Grain | Description |
|---|---|---|
| `dim_users` | One row per user | Users with lifetime purchase and listing metrics |

**Aggregates**
| Model | Description |
|---|---|
| `mart_sales_by_category` | Revenue rollup by event category and year |
| `mart_top_events` | Events ranked by revenue with revenue-per-ticket |
| `mart_venue_performance` | Venue analysis with total revenue and seat fill rate |
| `mart_user_segments` | Buyer (VIP/Regular/Occasional), seller (Power/Active/New), and interest segments |

## Macros

| Macro | Description |
|---|---|
| `safe_divide(n, d)` | Zero-safe division — returns 0 when denominator is 0 |
| `test_is_positive(col)` | Generic test: asserts column values are > 0 |
| `generate_schema_name` | Overrides dbt default — writes to exact schema names; prefixes `ci_pr_<N>_` in CI |

## Snapshots

| Snapshot | Strategy | Tracked Columns |
|---|---|---|
| `users_snapshot` | `check` | `likes_sports`, `likes_concerts`, `likes_theatre`, `likes_broadway`, `likes_musicals`, `city`, `state` |

Captures SCD Type 2 history of user preference and location changes.

## Tests

**Schema tests** (`_models.yml`) — `unique`, `not_null`, `relationships`, `accepted_values`, `is_positive`

**Singular tests** (`tests/`)
| Test | Asserts |
|---|---|
| `assert_positive_revenue.sql` | No rows with `net_revenue < 0` |
| `assert_commission_less_than_price.sql` | No rows where `commission >= price_paid` |

## Common Commands

```bash
dbt run                            # run all models
dbt run --select staging           # staging layer only
dbt run --select +fct_sales        # fct_sales and all upstream
dbt build                          # run + test all models
dbt test                           # all tests
dbt snapshot                       # run snapshots
dbt docs generate && dbt docs serve
```

## CI Behavior

GitHub Actions uses the latest production `manifest.json` from S3 to keep pull request runs focused and fast.

- CI downloads `s3://<dbt_state_bucket>/artifacts/prod/manifest.json`
- PR runs use `--defer --state state/prod --select @state:modified`
- CI schemas are prefixed as `ci_pr_<N>_...`
- when no prior manifest exists, workflows fall back to a full `dbt build`

Example CI schema names:

```text
ci_pr_9_staging_tickit
ci_pr_9_intermediate
ci_pr_9_marts
```

This approach keeps PR runs isolated while still reusing production refs for unchanged upstream nodes.

## Connection

Defined in `~/.dbt/profiles.yml` (not in repo). Uses `DBT_PASSWORD` env var.

| Target | Database | Use |
|---|---|---|
| `prod` | `analytics` | Production run |
| `ci` | `dev` | GitHub Actions PR checks |
