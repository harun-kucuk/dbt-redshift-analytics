# dbt Redshift Analytics

A portfolio analytics project using **dbt**, **AWS Redshift Serverless**, **Terraform**, and **Apache Airflow**. Transforms the Redshift TICKIT sample dataset through a layered data model into analytics-ready tables, orchestrated with Cosmos DAGs.

## Stack

| Tool | Purpose |
|---|---|
| AWS Redshift Serverless | Cloud data warehouse (8 RPU, eu-west-2) |
| dbt-redshift 1.10 | Data transformation |
| Terraform | Infrastructure as code |
| Apache Airflow 2.10 + Cosmos | Pipeline orchestration |
| S3 | Terraform remote state |
| GitHub Actions | CI/CD for dbt and Terraform |

## Architecture

```
sample_data_dev.tickit  (Redshift built-in sample)
        │
        ▼
┌─────────────────────────────┐
│  staging_tickit  (views)    │  Rename & cast — no logic
│  stg_tickit__*              │
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
│  fct_*  dim_*  mart_*       │
└─────────────────────────────┘
        │
        ▼
┌─────────────────────────────┐
│  Airflow + Cosmos           │  Scheduled orchestration (06:00 UTC daily)
│  tickit_dbt_daily           │  Each dbt model = individual Airflow task
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
| Model | Type | Description |
|---|---|---|
| `fct_sales` | Fact | Enriched sales — primary fact table |
| `dim_users` | Dimension | Users with lifetime metrics |
| `mart_sales_by_category` | Aggregate | Revenue rollup by category and year |
| `mart_top_events` | Aggregate | Events ranked by revenue with revenue-per-ticket |
| `mart_venue_performance` | Aggregate | Venue revenue and seat fill rate |
| `mart_user_segments` | Aggregate | Buyer, seller, and interest segments |

## Airflow DAGs

| DAG | Schedule | Description |
|---|---|---|
| `tickit_dbt_daily` | 06:00 UTC | Full pipeline |
| `tickit_dbt_staging` | Manual | Staging layer only |
| `tickit_dbt_intermediate` | Manual | Intermediate layer only |
| `tickit_dbt_marts` | Manual | Marts layer only |
| `tickit_dbt_adhoc` | Manual | Free-form `command` + `selector` trigger |

## Infrastructure

Managed by Terraform in `terraform/`. Schemas defined in `terraform/schemas.csv`.

```
AWS
├── Redshift Serverless
│   ├── Namespace: analytics
│   └── Workgroup: analytics (8 RPU, eu-west-2)
├── Security Group: port 5439
└── S3: terraform remote state
```

## Getting Started

### 1. Deploy Infrastructure

```bash
cd terraform
export TF_VAR_admin_password="<password>"
terraform init
terraform apply
```

### 2. Run dbt

```bash
cd dbt
export DBT_PASSWORD="<password>"
dbt run
dbt test
```

### 3. Start Airflow

```bash
cd airflow
cp .env.example .env       # fill in credentials
cd ../dbt && dbt compile   # generate manifest.json
cd ../airflow
docker compose up airflow-init
docker compose up -d airflow-webserver airflow-scheduler
# open http://localhost:8080  (admin / admin)
```

## Project Structure

```
├── dbt/
│   ├── models/
│   │   ├── staging/         stg_tickit__* late-binding views
│   │   ├── intermediate/    int_* joined & enriched tables
│   │   └── marts/           fct_* dim_* mart_* analytics tables
│   ├── macros/              safe_divide, test_is_positive, generate_schema_name
│   ├── snapshots/           users_snapshot (SCD Type 2)
│   ├── tests/               singular SQL tests
│   └── dbt_project.yml
├── airflow/
│   ├── dags/                tickit_dbt_*.py cosmos DAGs
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── requirements.txt
├── terraform/
│   ├── main.tf              Redshift + security group
│   ├── schemas.tf           schema provisioning from CSV
│   ├── schemas.csv          schema source of truth
│   └── versions.tf          S3 backend + provider pins
├── .github/workflows/       dbt-ci, dbt-cd, terraform-ci, terraform-cd, pr-cleanup
├── .claude/rules/           layer-specific coding rules for Claude Code
└── CLAUDE.md                project guide
```
