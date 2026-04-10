"""
common.py
---------
Shared cosmos configuration reused across all tickit dbt DAGs.
Import profile_config, execution_config, and operator_args instead of
repeating them in every DAG file.
"""
from __future__ import annotations

import os
from pathlib import Path

from airflow.hooks.base import BaseHook
from airflow.operators.bash import BashOperator  # noqa: F401 — re-exported for adhoc DAG
from cosmos import ExecutionConfig, ProfileConfig, ProjectConfig
from cosmos.constants import ExecutionMode, InvocationMode
from cosmos.profiles import RedshiftUserPasswordProfileMapping

DBT_PROJECT_PATH = Path("/opt/airflow/dbt")
DBT_VENV_PATH = Path("/opt/airflow/dbt-venv")
DBT_EXECUTABLE_PATH = DBT_VENV_PATH / "bin" / "dbt"
DBT_MANIFEST_PATH = DBT_PROJECT_PATH / "target" / "manifest.json"


def slack_failure_callback(context: dict) -> None:
    """Post a failure notification to Slack.

    Reads SLACK_WEBHOOK_URL from the environment (or an Airflow Variable).
    Silently skips if the variable is not configured so local/dev runs
    don't require a Slack workspace.
    """
    import urllib.request
    import json

    webhook_url = os.environ.get("SLACK_WEBHOOK_URL", "")
    if not webhook_url:
        print("SLACK_WEBHOOK_URL not set — skipping failure notification")
        return

    dag_id = context["dag"].dag_id
    task_id = context["task_instance"].task_id
    run_id = context["run_id"]
    log_url = context["task_instance"].log_url
    owner = context["dag"].owner

    payload = {
        "attachments": [{
            "color": "danger",
            "title": ":x: dbt task failed",
            "fields": [
                {"title": "DAG",          "value": dag_id,  "short": True},
                {"title": "Failed task",  "value": task_id, "short": True},
                {"title": "Owner",        "value": owner,   "short": True},
                {"title": "Run ID",       "value": run_id,  "short": True},
            ],
            "actions": [{"type": "button", "text": "View logs", "url": log_url}],
        }]
    }

    req = urllib.request.Request(
        webhook_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    urllib.request.urlopen(req, timeout=10)


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
    "on_failure_callback": slack_failure_callback,
}

project_config = ProjectConfig(
    dbt_project_path=DBT_PROJECT_PATH,
    manifest_path=DBT_MANIFEST_PATH,
)
