# ADR 001 — Late-Binding Views for Staging Models

**Date**: 2026-01-15
**Status**: Accepted

## Context

The source data (`sample_data_dev.tickit`) lives in a different database from the
analytics schemas (`analytics`). Redshift cross-database references are read-only and
do not support standard view creation — a view in `analytics` cannot `SELECT FROM`
a table in `sample_data_dev` using the normal view DDL.

Two options were evaluated:

| Option | Pros | Cons |
|---|---|---|
| **Table materialisation** | Simple; no Redshift-specific config | Full copy of source data on every run; higher storage cost and run time |
| **Late-binding view** (`bind: false`) | No data duplication; always reads live source | Redshift-only feature; breaks if source schema changes without a `dbt run` |

## Decision

Use late-binding views (`+bind: false`) for all staging models.

Redshift late-binding views defer schema resolution to query time rather than view
creation time. This allows the view to reference a table in a different database
without holding a compile-time lock on it.

```yaml
# dbt_project.yml
models:
  analytics:
    staging:
      +materialized: view
      +bind: false
```

## Consequences

- **Positive**: Staging layer adds zero storage overhead — queries always read the
  live source row.
- **Positive**: View DDL succeeds even during cross-database migrations where the
  source is temporarily unavailable.
- **Negative**: If the source table drops a column that the staging view selects,
  the view silently returns `NULL` rather than erroring at creation time. Mitigated
  by `not_null` tests on critical columns.
- **Negative**: `bind: false` is a Redshift-specific config. Switching warehouses
  would require replacing this with table materialisation or a different strategy.
