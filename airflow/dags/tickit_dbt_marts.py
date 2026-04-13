"""
tickit_dbt_marts.py — Marts DAG (full upstream chain)
Selector: +fct_sales +dim_users +mart_top_events +mart_venue_performance +mart_user_segments
Use case: guarantee fully fresh marts by rebuilding entire upstream graph.
"""
from __future__ import annotations

from datetime import datetime

from cosmos import DbtDag, RenderConfig
from cosmos.constants import LoadMode

from common import default_args, execution_config, operator_args, profile_config, project_config

tickit_dbt_marts_dag = DbtDag(
    dag_id="tickit_dbt_marts",
    schedule=None,
    start_date=datetime(2025, 1, 1),
    catchup=False,
    default_args=default_args,
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    render_config=RenderConfig(
        load_method=LoadMode.DBT_MANIFEST,
        select=["path:models/marts"],
    ),
    operator_args=operator_args,
    tags=["dbt", "redshift", "marts", "subset"],
)
