# ADR 004 — Incremental Strategy for fct_sales

**Date**: 2026-04-10
**Status**: Accepted

## Context

`fct_sales` is the primary fact table, sourced from `int_sales_enriched`. The TICKIT
dataset contains ~172K sale records. Two build strategies were considered:

| Option | Build time | Compute cost | Late-arriving row risk |
|---|---|---|---|
| **Full refresh** | Rebuilds entire table every run | Higher — scans all source rows | None — all rows reprocessed |
| **Incremental** | Processes only new/recent rows | Lower — scans a small window | Possible — rows arriving after the cutoff are skipped |

## Decision

Use **incremental materialization** with a **1-day overlap window**.

On each run, only rows where `sale_at > max(sale_at) - 1 day` are processed.
The 1-day lookback is intentional: it catches rows that arrive late due to source
system delays without requiring a full rebuild.

```sql
{% if is_incremental() %}
where base.sale_at > (
    select dateadd(day, -1, max(sale_at)) from {{ this }}
)
{% endif %}
```

`unique_key = 'sale_id'` ensures that any row reprocessed within the overlap window
is upserted rather than duplicated.

`on_schema_change = 'append_new_columns'` is required because `fct_sales` has a
dbt contract enforced. The stricter `sync_all_columns` option is incompatible with
contracts and raises a validation error at parse time.

## Consequences

- **Positive**: Run time stays constant as the table grows — only the trailing
  1-day window is scanned on each incremental run.
- **Positive**: Late-arriving rows (e.g. delayed source ingestion) are caught
  without manual intervention for delays under 24 hours.
- **Negative**: Source data reloaded for dates older than 1 day requires a
  `--full-refresh` run to propagate changes. This is documented in the runbook.
- **Trade-off**: The overlap window is a heuristic. A longer window (e.g. 7 days)
  would cover more edge cases at the cost of processing more rows per run. 1 day
  is sufficient for the observed source latency in this pipeline.
