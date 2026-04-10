# dbt Redshift Analytics — Project Guide

## Stack
- **Warehouse**: AWS Redshift Serverless (workgroup: `analytics`, database: `analytics`, region: `eu-west-2`)
- **Transform**: dbt-redshift 1.10, project root at `dbt/`
- **Infra**: Terraform in `terraform/`, schemas driven by `terraform/schemas.csv`
- **Source data**: `sample_data_dev.tickit` (Redshift built-in sample — ticketing domain)

## dbt Layer Rules

@.claude/rules/staging.md
@.claude/rules/intermediate.md
@.claude/rules/marts.md
@.claude/rules/terraform.md

## Naming Conventions
| Layer | Pattern | Example |
|---|---|---|
| Staging | `stg_<source>__<table>` | `stg_tickit__sales` |
| Intermediate | `int_<entity>_<verb>` | `int_sales_enriched` |
| Fact | `fct_<entity>` | `fct_sales` |
| Dimension | `dim_<entity>` | `dim_users` |
| Aggregate mart | `mart_<topic>` | `mart_sales_by_category` |

## Schema Management
Schemas are defined in `terraform/schemas.csv` (columns: `name`, `database`).
To add a schema: add a row and run `terraform apply` from `terraform/`.

## Common Commands
```bash
dbt run                          # run all models
dbt run --select staging         # run staging layer only
dbt run --select marts           # run marts layer only
dbt run --select +fct_sales      # run fct_sales and all upstream deps
dbt run --full-refresh           # rebuild all tables from scratch
dbt test                         # run all tests
dbt docs generate && dbt docs serve  # browse lineage locally
```

## Key Files
- `dbt/dbt_project.yml` — layer materializations and schema assignments
- `dbt/macros/generate_schema_name.sql` — overrides dbt default to write to exact schema names (no `dev_` prefix)
- `~/.dbt/profiles.yml` — connection credentials (not in repo)
- `terraform/schemas.csv` — source of truth for schema names
