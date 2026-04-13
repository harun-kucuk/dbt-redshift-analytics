"""
tickit_dbt_adhoc.py
-------------------
Ad-hoc DAG that accepts a dbt command and selector as trigger-time parameters.
Credentials are pulled from the redshift_default Airflow Connection — no
dependency on profiles.yml or environment variables.

Trigger from the UI (Trigger DAG w/ config) or CLI:

  # Run a model and all downstream
  airflow dags trigger tickit_dbt_adhoc --conf '{"command": "run", "selector": "fct_sales+"}'

  # Test a specific intermediate model
  airflow dags trigger tickit_dbt_adhoc --conf '{"command": "test", "selector": "int_sales_enriched"}'

  # Build (run + test) a whole layer
  airflow dags trigger tickit_dbt_adhoc --conf '{"command": "build", "selector": "path:models/marts"}'

Supported commands: run, test, build
"""
from __future__ import annotations

from datetime import datetime
from pathlib import Path

from airflow import DAG
from airflow.hooks.base import BaseHook
from airflow.models.param import Param
from airflow.operators.bash import BashOperator

DBT = Path("/opt/airflow/dbt-venv/bin/dbt")
DBT_PROJECT_DIR = Path("/opt/airflow/dbt")


def _redshift_env() -> dict[str, str]:
    """Pull credentials from the redshift_default Airflow Connection."""
    conn = BaseHook.get_connection("redshift_default")
    return {
        "DBT_PASSWORD": conn.password,
    }


with DAG(
    dag_id="tickit_dbt_adhoc",
    schedule=None,               # manual trigger only
    start_date=datetime(2025, 1, 1),
    catchup=False,
    default_args={
        "owner": "data-engineering",
        "retries": 0,
        "email_on_failure": False,
    },
    params={
        "command": Param(
            default="build",
            type="string",
            enum=["run", "test", "build"],
            description="dbt command to execute",
        ),
        "selector": Param(
            default="fct_sales+",
            type="string",
            description='dbt node selector, e.g. "fct_sales+", "int_sales_enriched", "path:models/marts"',
        ),
    },
    tags=["dbt", "redshift", "adhoc"],
) as dag:

    dbt_adhoc = BashOperator(
        task_id="dbt_adhoc",
        bash_command=(
            f"{DBT} deps "
            f"--project-dir {DBT_PROJECT_DIR} "
            f"--profiles-dir {DBT_PROJECT_DIR} "
            f"--target prod "
            f"&& "
            f"{DBT} {{{{ params.command }}}} "
            f"--select {{{{ params.selector }}}} "
            f"--project-dir {DBT_PROJECT_DIR} "
            f"--profiles-dir {DBT_PROJECT_DIR} "
            f"--target prod"
        ),
        env=_redshift_env(),
    )
