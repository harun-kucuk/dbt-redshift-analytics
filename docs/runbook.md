# Runbook — dbt Redshift Analytics

Operational reference for on-call and day-to-day pipeline work.

---

## Daily DAG Failure

**DAG**: `tickit_dbt_daily` — scheduled 06:00 UTC

### 1. Find the failed task

```bash
# From repo root
cd airflow
docker compose exec airflow-scheduler \
  airflow dags list-runs -d tickit_dbt_daily | head -5
```

Click the run in the Airflow UI (`http://localhost:8080`) and look for red tasks.

### 2. Read the logs

In the UI: click the failed task → **Log** tab.

Or from the CLI:
```bash
docker compose exec airflow-scheduler \
  airflow tasks logs tickit_dbt_daily <task_id> <execution_date>
```

### 3. Common failures and fixes

| Symptom | Likely cause | Fix |
|---|---|---|
| `password authentication failed` | Redshift password rotated | Update `DBT_PASSWORD` in `airflow/.env` and restart |
| `relation does not exist` | Schema missing | Run `terraform apply` from `terraform/` |
| `dbt found N packages specified but 0 installed` | Packages not installed | `make deps` then re-trigger |
| `manifest.json not found` | Manifest stale/missing | `make compile` then re-trigger |
| `timeout` / `connection refused` | Redshift cold start | Wait 30s and re-trigger the failed task |
| Test failure (red `.test` task) | Data quality issue | Investigate with the query in `dbt/target/compiled/` |

### 4. Re-trigger a single failed task

```bash
docker compose exec airflow-scheduler \
  airflow tasks clear tickit_dbt_daily -t "<task_id>" -s <YYYY-MM-DD> --yes
```

---

## Backfilling

Use when historical data was reloaded or a model logic changed.

```bash
# Full refresh — rebuilds all tables from scratch
make full-refresh

# Or re-trigger the daily DAG for a specific date
docker compose exec airflow-scheduler \
  airflow dags backfill tickit_dbt_daily \
  --start-date 2026-01-01 --end-date 2026-01-31
```

For incremental models (`fct_sales`), a full refresh is required when:
- Source data was reloaded for past dates
- The model SQL logic changed
- Columns were added/removed

```bash
cd dbt && DBT_PASSWORD="..." dbt run --select fct_sales --full-refresh --target prod
```

---

## Adding a New Model

### Staging model
1. Add a row to `dbt/models/staging/_sources.yml` if the source table is new
2. Create `dbt/models/staging/stg_tickit__<table>.sql` — rename and cast only
3. Add column tests to `dbt/models/staging/_models.yml`
4. Run `make build` to verify

### Intermediate model
1. Create `dbt/models/intermediate/int_<entity>_<verb>.sql`
2. Reference only staging models via `{{ ref('stg_tickit__...') }}`
3. Add to `dbt/models/intermediate/_models.yml`

### Mart model
1. Create the model in `dbt/models/marts/`
2. Add tests and (for key models) a contract in `_models.yml`
3. Add to `dbt/models/marts/_exposures.yml` if it feeds a downstream consumer
4. Run `make compile` to regenerate `manifest.json` for Airflow

---

## Schema Changes

### Add a new schema

1. Add a row to `terraform/schemas.csv`
2. Run `make tf-apply`
3. Add the schema to `dbt_project.yml` if it needs a new dbt layer

### Column added to a source table

Staging models use `select *` from source CTEs — the new column flows through
automatically. Add it to `_models.yml` tests if it needs coverage.

### Column removed from a source table

Late-binding views return `NULL` silently for dropped columns. The `not_null`
test on that column will catch this on the next run. Drop the column reference
from the staging model and downstream models.

---

## Redshift Connection Issues

### Test connectivity
```bash
cd dbt && DBT_PASSWORD="..." dbt debug --target prod
```

### Password reset

```bash
aws redshift-serverless update-namespace \
  --namespace-name analytics \
  --admin-username admin \
  --admin-user-password "<new-password>" \
  --region eu-west-2
```

Then update `DBT_PASSWORD` in:
- `~/.zshrc` (as `TF_VAR_admin_password`)
- `airflow/.env`
- GitHub secret `DBT_PASSWORD`

### Security group — allow a new IP

```bash
cd terraform
# add your new IP/CIDR to allowed_cidr_blocks in terraform.tfvars
terraform apply
```

Prefer Terraform-managed changes so the allowlist stays auditable and reproducible.

---

## CI/CD

| Workflow | Trigger | Does |
|---|---|---|
| `dbt-ci` | PR touching `dbt/**` | SQLFluff lint → `dbt run` + `dbt test` on `dev` DB with PR-isolated schemas |
| `dbt-cd` | Merge to `main` on `dbt/**` | `dbt run` + `dbt test` on `analytics` (prod) |
| `terraform-ci` | PR touching `terraform/**` | `terraform plan`, posts plan as PR comment |
| `terraform-cd` | Merge to `main` on `terraform/**` | `terraform apply` |
| `pr-cleanup` | PR closed | Drops `pr_<N>_*` schemas from `dev` DB |

### Re-run a failed CI job

Go to the PR → **Checks** tab → click the failed check → **Re-run jobs**.

---

## Useful Queries

```sql
-- Recent query history
select query_id, status, start_time,
       round(elapsed_time/1000000.0, 2) as elapsed_sec,
       left(query_text, 200) as query_text
from sys_query_history
where user_id > 1
order by start_time desc
limit 50;

-- Active sessions
select pid, user_name, query, starttime
from stv_sessions
where user_name != 'rdsdb';

-- Table sizes
select trim(pgn.nspname)      as schema,
       trim(pgc.relname)      as table,
       sum(b.mbytes)          as mb
from (select tbl, count(*) as mbytes
      from stv_blocklist group by tbl) b
join pg_class pgc on pgc.oid = b.tbl
join pg_namespace pgn on pgn.oid = pgc.relnamespace
group by 1, 2
order by 3 desc;
```
