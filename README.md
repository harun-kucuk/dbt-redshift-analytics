# dbt Redshift Analytics

A portfolio analytics project using **dbt**, **AWS Redshift Serverless**, and **Terraform**. Transforms the Redshift TICKIT sample dataset through a layered data model into analytics-ready tables.

## Stack

| Tool | Purpose |
|---|---|
| AWS Redshift Serverless | Cloud data warehouse |
| dbt-redshift | Data transformation |
| Terraform | Infrastructure as code |
| S3 | Terraform remote state |

## Architecture

```
sample_data_dev.tickit  (Redshift built-in sample)
        │
        ▼
┌─────────────────────┐
│  staging_tickit     │  Views (late-binding) — rename & cast only
│  stg_tickit__*      │
└─────────────────────┘
        │
        ▼
┌─────────────────────┐
│  intermediate       │  Tables — joins & business logic
│  int_*              │
└─────────────────────┘
        │
        ▼
┌─────────────────────┐
│  marts              │  Tables — analytics-ready
│  fct_* dim_* mart_* │
└─────────────────────┘
```

## dbt Models

### Staging (`staging_tickit`)
| Model | Description |
|---|---|
| `stg_tickit__sales` | Ticket sales transactions |
| `stg_tickit__users` | Buyers and sellers |
| `stg_tickit__events` | Events (concerts, sports, shows) |
| `stg_tickit__venues` | Venue details |
| `stg_tickit__listings` | Ticket listings |
| `stg_tickit__categories` | Event categories |
| `stg_tickit__dates` | Date dimension |

### Marts (`marts`)
| Model | Type | Description |
|---|---|---|
| `fct_sales` | Fact | Sales enriched with event, venue, category, date |
| `dim_users` | Dimension | Users with purchase and listing metrics |
| `mart_sales_by_category` | Aggregate | Revenue rollup by category and time |

## Infrastructure

Managed by Terraform in `terraform/`. Schemas are defined in `terraform/schemas.csv`.

```
AWS
├── Redshift Serverless
│   ├── Namespace: analytics
│   └── Workgroup: analytics (8 RPU)
├── Security Group: port 5439
└── S3: terraform remote state
```

## Getting Started

### Prerequisites
- Terraform >= 1.5
- dbt-redshift >= 1.10
- AWS CLI configured

### Deploy Infrastructure

```bash
cd terraform
export TF_VAR_admin_password="<your-password>"
terraform init
terraform apply
```

### Run dbt

```bash
cd dbt
dbt run         # run all models
dbt test        # run tests
dbt docs serve  # browse lineage
```

## Project Structure

```
├── dbt/
│   ├── models/
│   │   ├── staging/    # 1:1 source views
│   │   ├── intermediate/  # business logic
│   │   └── marts/      # analytics tables
│   ├── macros/
│   └── dbt_project.yml
├── terraform/
│   ├── main.tf         # Redshift + security group
│   ├── schemas.tf      # schema provisioning
│   ├── schemas.csv     # schema definitions
│   └── versions.tf     # S3 backend + providers
├── .claude/rules/      # layer-specific coding rules
└── CLAUDE.md           # project guide for Claude Code
```
