# dbt Redshift Analytics — Project Guide

## Stack
- **Warehouse**: AWS Redshift Serverless (workgroup: `analytics`, database: `analytics`, region: `eu-west-2`)
- **Transform**: dbt-redshift 1.10, project root at `dbt/`
- **Orchestration**: Apache Airflow 2.10 + Cosmos 1.14, project root at `airflow/`
- **Infra**: Terraform in `terraform/`, schemas driven by `terraform/schemas.csv`
- **Source data**: `sample_data_dev.tickit` (Redshift built-in sample — ticketing domain)

## Layer Rules

@.claude/rules/staging.md
@.claude/rules/intermediate.md
@.claude/rules/marts.md
@.claude/rules/macros.md
@.claude/rules/airflow.md
@.claude/rules/terraform.md
@.claude/rules/cicd.md

## Schema Management
Schemas are defined in `terraform/schemas.csv` (columns: `name`, `database`).
To add a schema: add a row and run `terraform apply` from `terraform/`.

## dbt Commands
```bash
dbt run                              # run all models
dbt run --select staging             # staging layer only
dbt run --select +fct_sales          # fct_sales and all upstream
dbt run --full-refresh               # rebuild all tables from scratch
dbt build                            # run + test all models
dbt test                             # all tests
dbt snapshot                         # run snapshots
dbt compile                          # compile without running (regenerates manifest.json)
dbt docs generate && dbt docs serve  # browse lineage locally
```

## Airflow Commands
```bash
cd airflow
docker compose up airflow-init                  # one-time setup
docker compose up -d airflow-webserver airflow-scheduler
docker compose exec airflow-scheduler airflow dags list
docker compose exec airflow-scheduler airflow dags trigger tickit_dbt_daily
docker compose down                             # stop all services
```

## Git Workflow

Never commit directly to `main`. Always work on a `feature/<name>` branch and use `/pr` to open pull requests.

## Claude Skills

| Skill | What it does |
|---|---|
| `/new-model [layer entity description]` | Scaffold a new dbt model + YAML tests |
| `/pr` | Commit, push, and open a PR |
| `/fix-sqlfluff` | Fix all SQLFluff linting violations |

## Key Files
- `dbt/dbt_project.yml` — layer materializations and schema assignments
- `dbt/macros/generate_schema_name.sql` — exact schema names, `pr_<N>_` prefix in CI
- `dbt/macros/safe_divide.sql` — zero-safe division utility
- `dbt/macros/test_is_positive.sql` — generic positive value test
- `dbt/profiles.yml` — CI profile; prod credentials live in `~/.dbt/profiles.yml`
- `dbt/snapshots/users_snapshot.sql` — SCD Type 2 on user preferences
- `airflow/dags/common.py` — shared Cosmos config (profile, execution, project)
- `airflow/docker-compose.yml` — Airflow service definitions
- `terraform/schemas.csv` — source of truth for schema names
- `.github/workflows/` — dbt-ci, dbt-cd, dbt-docs, pr-cleanup (terraform-ci and terraform-cd are disabled; trigger manually via `workflow_dispatch` if needed)
