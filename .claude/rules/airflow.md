---
paths: ["airflow/**"]
---

# Airflow Rules

## Stack
- Airflow 2.10.4, Cosmos 1.14.0, dbt-redshift in isolated virtualenv at `/opt/airflow/dbt-venv`
- All DAGs use `LoadMode.DBT_MANIFEST` — never switch to `LoadMode.DBT_LS` or `CUSTOM`
- Credentials come from the `redshift_default` Airflow connection, not environment variables

## DAG Naming
- Full pipeline: `tickit_dbt_daily`
- Layer subsets: `tickit_dbt_<layer>` (staging, intermediate, marts)
- Ad-hoc: `tickit_dbt_adhoc`

## Shared Config
All DAGs import from `dags/common.py`:
- `profile_config` — `RedshiftUserPasswordProfileMapping` against `redshift_default`
- `execution_config` — `ExecutionMode.LOCAL`, `InvocationMode.SUBPROCESS`
- `project_config` — manifest path at `DBT_PROJECT_PATH / "target" / "manifest.json"`
- `default_args` — owner, retries, retry_delay_seconds
- `operator_args` — `install_deps: True`

Never duplicate these in individual DAG files.

## Allowed
- Adding new subset DAGs using `RenderConfig(select=[...])` for new model groups
- Using `RenderConfig(exclude=[...])` to skip specific models
- Extending `operator_args` for task-level overrides (e.g. `full_refresh`)

## Not Allowed
- Hardcoding Redshift credentials in DAG files — use `BaseHook.get_connection("redshift_default")`
- Installing dbt packages in the Airflow Python env — dbt-redshift must stay in `/opt/airflow/dbt-venv`
- Using `schedule_interval` (deprecated) — use `schedule`
- Creating DAGs without `catchup=False`

## Pattern — New subset DAG
```python
from cosmos import DbtDag, RenderConfig
from cosmos.constants import LoadMode
from common import default_args, execution_config, operator_args, profile_config, project_config

my_dag = DbtDag(
    dag_id="tickit_dbt_<name>",
    schedule=None,
    start_date=datetime(2025, 1, 1),
    catchup=False,
    default_args=default_args,
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    render_config=RenderConfig(
        load_method=LoadMode.DBT_MANIFEST,
        select=["path:models/<layer>"],
    ),
    operator_args=operator_args,
    tags=["dbt", "redshift", "<name>", "subset"],
)
```

## Manifest
`dbt/target/manifest.json` is volume-mounted into containers at `/opt/airflow/dbt`.
After any model or schema change, regenerate it locally before the next DAG run:
```bash
cd dbt && DBT_PASSWORD="..." dbt compile --target prod
```
