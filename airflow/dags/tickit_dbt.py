"""
tickit_dbt.py — Full pipeline DAG
Runs all models daily at 06:00 UTC.
Graph: stg_tickit__* → int_* → fct_sales / dim_users / mart_*
"""
from __future__ import annotations

from datetime import datetime

from cosmos import DbtDag, RenderConfig
from cosmos.constants import LoadMode

from common import default_args, execution_config, operator_args, profile_config, project_config

tickit_dbt_dag = DbtDag(
    dag_id="tickit_dbt_daily",
    schedule="0 6 * * *",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    default_args=default_args,
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    render_config=RenderConfig(load_method=LoadMode.DBT_MANIFEST),
    operator_args=operator_args,
    tags=["dbt", "redshift", "daily"],
)
