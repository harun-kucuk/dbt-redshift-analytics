"""
common.py
---------
Shared cosmos configuration reused across all tickit dbt DAGs.
Import profile_config, execution_config, and operator_args instead of
repeating them in every DAG file.
"""
from __future__ import annotations

from pathlib import Path

from cosmos import ExecutionConfig, ProfileConfig, ProjectConfig
from cosmos.constants import ExecutionMode, InvocationMode
from cosmos.profiles import RedshiftUserPasswordProfileMapping

DBT_PROJECT_PATH = Path("/opt/airflow/dbt")
DBT_VENV_PATH = Path("/opt/airflow/dbt-venv")
DBT_EXECUTABLE_PATH = DBT_VENV_PATH / "bin" / "dbt"
DBT_MANIFEST_PATH = DBT_PROJECT_PATH / "target" / "manifest.json"

profile_config = ProfileConfig(
    profile_name="analytics",
    target_name="prod",
    profile_mapping=RedshiftUserPasswordProfileMapping(
        conn_id="redshift_default",
        profile_args={
            "dbname": "analytics",
            "schema": "public",
            "threads": 4,
            "sslmode": "require",
            "connect_timeout": 30,
        },
    ),
)

execution_config = ExecutionConfig(
    execution_mode=ExecutionMode.LOCAL,
    dbt_executable_path=DBT_EXECUTABLE_PATH,
    invocation_mode=InvocationMode.SUBPROCESS,
)

operator_args = {
    "install_deps": True,
}

default_args = {
    "owner": "data-engineering",
    "retries": 2,
    "retry_delay_seconds": 30,
    "email_on_failure": False,
}

project_config = ProjectConfig(
    dbt_project_path=DBT_PROJECT_PATH,
    manifest_path=DBT_MANIFEST_PATH,
)
