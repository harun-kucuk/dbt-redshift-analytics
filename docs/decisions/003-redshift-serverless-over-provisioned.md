# ADR 003 — Redshift Serverless over Provisioned Cluster

**Date**: 2026-01-10
**Status**: Accepted

## Context

This is a portfolio/development project with bursty, infrequent workloads — daily
dbt runs, ad-hoc queries, and CI pipeline runs. Two Redshift deployment models
were considered:

| Option | Base cost | Scaling | Ops overhead |
|---|---|---|---|
| **Provisioned cluster** | ~$180/month (dc2.large) always-on | Manual resize or elastic resize | Patch windows, VPC config, snapshot management |
| **Serverless** | $0 when idle; ~$0.36/RPU-hour | Automatic, 0–512 RPU | Minimal — no cluster management |

## Decision

Use **Redshift Serverless** at 8 RPU base capacity.

8 RPU is the minimum configuration and is sufficient for the TICKIT sample
dataset (~10M rows). The workgroup auto-scales during burst queries and
scales to zero between runs, making it cost-effective for non-production
workloads.

```hcl
resource "aws_redshiftserverless_workgroup" "main" {
  workgroup_name = var.workgroup_name
  namespace_name = var.namespace_name
  base_capacity  = 8
  publicly_accessible = true
}
```

## Consequences

- **Positive**: No idle cost between dbt runs. Estimated monthly cost for this
  workload: <$5.
- **Positive**: No cluster management — patching, backups, and scaling are AWS
  managed.
- **Positive**: Publicly accessible endpoint simplifies local development (no
  VPN or bastion required); protected by security group rules.
- **Negative**: Cold-start latency (~5s) on first query after an idle period.
  Acceptable for scheduled batch workloads; not suitable for sub-second BI queries
  without keep-warm strategies.
- **Negative**: Serverless does not support all Redshift features (e.g. some
  `ALTER TABLE` DDL operations, certain WLM configurations). None of the features
  used in this project are affected.
- **Trade-off**: A provisioned cluster would be more appropriate for always-on
  production workloads where consistent latency matters more than idle-time cost.
