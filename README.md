# dbt Redshift Analytics

[![dbt-ci](https://github.com/harun-kucuk/dbt-redshift-analytics/actions/workflows/dbt-ci.yml/badge.svg)](https://github.com/harun-kucuk/dbt-redshift-analytics/actions/workflows/dbt-ci.yml)
[![dbt-cd](https://github.com/harun-kucuk/dbt-redshift-analytics/actions/workflows/dbt-cd.yml/badge.svg)](https://github.com/harun-kucuk/dbt-redshift-analytics/actions/workflows/dbt-cd.yml)
[![terraform-ci](https://github.com/harun-kucuk/dbt-redshift-analytics/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/harun-kucuk/dbt-redshift-analytics/actions/workflows/terraform-ci.yml)
[![dbt docs](https://img.shields.io/badge/dbt%20docs-live-brightgreen)](https://harun-kucuk.github.io/dbt-redshift-analytics/)

A portfolio analytics engineering project using **dbt**, **AWS Redshift Serverless**, **Terraform**, and **Apache Airflow**. It transforms the Redshift TICKIT sample dataset into analytics-ready models, provisions infrastructure as code, and demonstrates both batch transformation and event-driven ingestion patterns.

## What This Repo Demonstrates

- a layered dbt project on Redshift Serverless
- Terraform-managed warehouse, security, and S3 infrastructure
- event-driven S3 to Redshift ingestion with `COPY JOB` auto-copy
- state-aware dbt CI/CD using `defer` and `state:modified+1`
- Airflow orchestration with Cosmos and Slack failure notifications
- practical tradeoffs, runbooks, and portfolio-grade documentation

## Stack

| Tool | Purpose |
|---|---|
| AWS Redshift Serverless | Cloud data warehouse (8 RPU, eu-west-2) |
| dbt-redshift 1.10.1 | Data transformation |
| dbt_utils 1.x | Surrogate key generation (`generate_surrogate_key`) |
| Terraform | Infrastructure as code |
| Apache Airflow 2.10 + Cosmos 1.14 | Pipeline orchestration |
| SQLFluff 3.3.1 | SQL linting (jinja templater, ansi dialect) |
| S3 | Terraform remote state, dbt state artifacts, auto-copy landing zone |
| GitHub Actions | CI/CD for dbt and Terraform |

## Architecture

```
sample_data_dev.tickit  (Redshift built-in sample)
        │
        ▼
┌─────────────────────────────┐
│  staging_tickit  (views)    │  Rename & cast — no logic
│  stg_tickit__*              │  Late-binding views (bind: false)
└─────────────────────────────┘
        │
        ▼
┌─────────────────────────────┐
│  intermediate  (tables)     │  Joins, business logic, aggregations
│  int_*                      │
└─────────────────────────────┘
        │
        ▼
┌─────────────────────────────┐
│  marts  (tables)            │  Analytics-ready: facts, dims, aggregates
│  fct_*  dim_*  mart_*       │  Contracts enforced on fct_sales, dim_users
└─────────────────────────────┘
        │
        ▼
┌─────────────────────────────┐
│  S3 landing zone            │  Event-driven ingest for raw CSV files
│  sales-feed/                │
└─────────────────────────────┘
        │
        ▼
┌─────────────────────────────┐
│  Redshift COPY JOB          │  Auto-copy from S3 into raw.sales_feed
│  sales_feed_copy            │
└─────────────────────────────┘
        │
        ▼
┌─────────────────────────────┐
│  raw.sales_feed             │  Operational landing table with loaded_at
└─────────────────────────────┘
        │
        ▼
┌─────────────────────────────┐
│  Airflow + Cosmos           │  Scheduled orchestration (06:00 UTC daily)
│  tickit_dbt_daily           │  Each dbt model = individual Airflow task
│  Slack failure alerts       │  On-failure webhook notification
└─────────────────────────────┘
```

## dbt Models

### Staging (`staging_tickit`)
| Model | Description |
|---|---|
| `stg_tickit__sales` | Ticket sale transactions |
| `stg_tickit__users` | Buyers and sellers with preferences |
| `stg_tickit__events` | Events (concerts, sports, shows) |
| `stg_tickit__venues` | Venue details |
| `stg_tickit__listings` | Active ticket listings |
| `stg_tickit__categories` | Event categories |
| `stg_tickit__dates` | Date dimension |

### Intermediate (`intermediate`)
| Model | Description |
|---|---|
| `int_sales_enriched` | Sales joined with all dimensions; includes `net_revenue`, `commission_rate` |
| `int_user_stats` | Per-user aggregated purchase, sales, and listing metrics |

### Marts (`marts`)
| Model | Type | Notes |
|---|---|---|
| `fct_sales` | Fact | Incremental (1-day overlap), contract enforced, surrogate key via `dbt_utils` |
| `dim_users` | Dimension | Users with lifetime metrics, contract enforced |
| `mart_sales_by_category` | Aggregate | Revenue rollup by category and year |
| `mart_top_events` | Aggregate | Events ranked by revenue with revenue-per-ticket |
| `mart_venue_performance` | Aggregate | Venue revenue and seat fill rate |
| `mart_user_segments` | Aggregate | Buyer, seller, and interest segments |

### Snapshots (`snapshots`)
| Snapshot | Strategy | Description |
|---|---|---|
| `users_snapshot` | `check` (all columns) | SCD Type 2 — tracks changes to user preferences over time |

The full lineage graph, column-level documentation, and test coverage for all 15 models are published as interactive dbt docs at **[harun-kucuk.github.io/dbt-redshift-analytics](https://harun-kucuk.github.io/dbt-redshift-analytics/)**, auto-deployed on every push to `main`.

## Airflow DAGs

| DAG | Schedule | Description |
|---|---|---|
| `tickit_dbt_daily` | 06:00 UTC | Full pipeline |
| `tickit_dbt_staging` | Manual | Staging layer only |
| `tickit_dbt_intermediate` | Manual | Intermediate layer only |
| `tickit_dbt_marts` | Manual | Marts layer only |
| `tickit_dbt_adhoc` | Manual | Free-form `command` + `selector` trigger |

All DAGs send a Slack alert on failure via `SLACK_WEBHOOK_URL` env var (gracefully skipped if not set).

![Airflow DAG](docs/images/airflow_dag.png)

![Airflow task failure](docs/images/airflow_failure.png)

![Airflow Slack alert](docs/images/slack_airflow.png)

## CI/CD

| Workflow | Trigger | Actions |
|---|---|---|
| `dbt-ci` | PR touching `dbt/**` or dbt workflow config | SQLFluff lint → download latest prod `manifest.json` from S3 → `dbt build --defer --state state/prod --select state:modified+1` in PR-isolated schemas |
| `dbt-cd` | Merge to `main` on `dbt/**` or dbt workflow config | Download latest prod manifest → build modified nodes plus the graph context their downstream models need → upload fresh `manifest.json` back to S3 |
| `terraform-ci` | PR touching `terraform/**` | `terraform plan`, posts plan as PR comment |
| `terraform-cd` | Merge to `main` on `terraform/**` | `terraform apply` |
| `pr-cleanup` | PR closed | Drops `ci_pr_<N>_*` schemas from dev DB |

`dbt-cd` and `terraform-cd` post a Slack alert on failure showing the failed step, branch, commit, and a direct link to the run.

### CI Schema Naming

dbt CI runs in isolated schemas shaped like:

```text
ci_pr_<PR_NUMBER>_staging_tickit
ci_pr_<PR_NUMBER>_intermediate
ci_pr_<PR_NUMBER>_marts
```

Example:

```text
ci_pr_9_staging_tickit
```

This keeps PR validation separate from production schemas while still letting CI use the shared `dev` database.

![GitHub Actions Slack alert](docs/images/slack_github.png)

## Infrastructure

Managed by Terraform in `terraform/`. Schemas defined in `terraform/schemas.csv`.

```
AWS
├── Redshift Serverless
│   ├── Namespace: analytics
│   └── Workgroup: analytics (8 RPU, eu-west-2)
├── Security Group: public endpoint with CIDR allowlist
├── S3: terraform remote state
├── S3: dbt state bucket for latest prod manifest
└── S3: raw ingest bucket for Redshift auto-copy
```

See [ADR 003](docs/decisions/003-redshift-serverless-over-provisioned.md) for why Serverless was chosen over a provisioned cluster.

### Event-Driven Ingestion

Terraform provisions a raw ingest bucket and configures a Redshift S3 event integration plus `COPY JOB` so files dropped into:

```text
s3://<raw_ingest_bucket>/sales-feed/
```

are loaded automatically into:

```text
raw.sales_feed
```

The landing table includes a `loaded_at` audit column so ingestion freshness can be queried directly in Redshift.

## Getting Started

### 1. Deploy Infrastructure

```bash
cd terraform
export TF_VAR_admin_password="<password>"

# configure non-sensitive variables
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set allowed_cidr_blocks to your public IP/CIDR

# configure S3 backend (not committed — contains your bucket name)
cp backend.hcl.example backend.hcl
# edit backend.hcl: set bucket, key, region

terraform init -backend-config=backend.hcl
terraform apply
```

### 2. Configure dbt

Add `~/.dbt/profiles.yml` with Redshift credentials (not committed — see `dbt/profiles.yml` for CI template).

### 3. Run dbt

```bash
make deps    # install dbt packages
make build   # dbt run + dbt test
make docs    # generate and serve lineage docs
```

### 4. Start Airflow

```bash
cd airflow
cp .env.example .env       # fill in DBT_PASSWORD and optionally SLACK_WEBHOOK_URL
cd ..
make compile               # generate manifest.json (required by Cosmos)
make airflow-init          # one-time DB migrate + user creation
make airflow-up            # start webserver + scheduler
# open http://localhost:8080  (admin / admin)
```

### 5. Lint SQL

```bash
make lint        # check all models, macros, and tests
make lint-fix    # auto-correct where possible
```

### 6. Test The Auto-Copy Flow

```bash
aws s3 cp terraform/sample_sales_feed.csv \
  s3://<raw_ingest_bucket>/sales-feed/sample_sales_feed.csv
```

Useful verification queries:

```sql
select * from sys_copy_job;
select * from sys_copy_job_detail where job_name = 'sales_feed_copy';
select * from "raw".sales_feed order by loaded_at desc;
```

## Project Structure

```
├── dbt/
│   ├── models/
│   │   ├── staging/         stg_tickit__* renamed source tables
│   │   ├── intermediate/    int_* joined & enriched tables
│   │   └── marts/           fct_* dim_* mart_* analytics tables
│   ├── macros/              safe_divide, test_is_positive, generate_schema_name
│   ├── snapshots/           users_snapshot (SCD Type 2)
│   ├── packages.yml         dbt_utils dependency
│   ├── tests/               singular SQL tests
│   └── dbt_project.yml
├── airflow/
│   ├── dags/                tickit_dbt_*.py cosmos DAGs
│   ├── dags/common.py       shared config + Slack failure callback
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── requirements.txt
├── terraform/
│   ├── main.tf              Redshift + security group
│   ├── schemas.tf           schema provisioning from CSV
│   ├── schemas.csv          schema source of truth
│   └── versions.tf          S3 backend + provider pins
├── docs/
│   ├── decisions/           ADR 001–003
│   └── runbook.md           operational on-call reference
├── .github/workflows/       dbt-ci, dbt-cd, terraform-ci, terraform-cd, pr-cleanup
├── .sqlfluff                SQLFluff config (jinja templater, ansi dialect)
├── .claude/rules/           layer-specific coding rules for Claude Code
├── Makefile                 single entrypoint for all developer operations
└── CLAUDE.md                project guide
```

## Architecture Decision Records

| ADR | Decision |
|---|---|
| [001](docs/decisions/001-late-binding-views-for-staging.md) | Late-binding views for staging layer |
| [002](docs/decisions/002-cosmos-over-bash-operator.md) | Astronomer Cosmos over BashOperator for dbt orchestration |
| [003](docs/decisions/003-redshift-serverless-over-provisioned.md) | Redshift Serverless over provisioned cluster |

## Runbook

See [docs/runbook.md](docs/runbook.md) for:
- Daily DAG failure diagnosis and re-trigger steps
- Backfilling instructions (including `fct_sales` full-refresh)
- Adding new staging, intermediate, and mart models
- Schema change procedures
- Redshift connection troubleshooting
- Useful diagnostic queries
