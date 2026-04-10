# Airflow — dbt Orchestration

Orchestrates the dbt pipeline using [Astronomer Cosmos](https://astronomer.github.io/astronomer-cosmos/), which renders each dbt model as an individual Airflow task.

## Stack

| Component | Version |
|---|---|
| Apache Airflow | 2.10.4 |
| astronomer-cosmos | 1.14.0 |
| dbt-redshift | 1.10.0 (isolated virtualenv) |
| Metadata DB | PostgreSQL 15 |

## DAGs

| DAG | Schedule | Selector | Purpose |
|---|---|---|---|
| `tickit_dbt_daily` | `0 6 * * *` | All models | Full pipeline — runs every day at 06:00 UTC |
| `tickit_dbt_staging` | Manual | `path:models/staging` | Refresh staging views only |
| `tickit_dbt_intermediate` | Manual | `path:models/intermediate` | Refresh intermediate tables only |
| `tickit_dbt_marts` | Manual | `path:models/marts` | Refresh mart tables only |
| `tickit_dbt_adhoc` | Manual | Free-form param | Run any dbt command + selector on demand |

All DAGs use `LoadMode.DBT_MANIFEST` — cosmos reads `dbt/target/manifest.json` to build the task graph without parsing dbt at scheduler startup.

## Setup

### 1. Configure credentials

```bash
cp .env.example .env
# Fill in: REDSHIFT_HOST, REDSHIFT_USER, DBT_PASSWORD, AIRFLOW__CORE__FERNET_KEY

# Generate fernet key if needed:
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

### 2. Generate dbt manifest

Cosmos needs `dbt/target/manifest.json` to render the task graph.

```bash
cd ../dbt
DBT_PASSWORD="..." dbt compile --target prod
```

### 3. Initialise and start

```bash
cd airflow

# One-time: migrate DB, create admin user, register Redshift connection
docker compose up airflow-init

# Start webserver + scheduler
docker compose up -d airflow-webserver airflow-scheduler
```

Open `http://localhost:8080` — login: `admin` / `admin`

## Triggering DAGs

From the UI: unpause a DAG and click **Trigger DAG**.

From the CLI:
```bash
# Full pipeline
docker compose exec airflow-scheduler \
  airflow dags trigger tickit_dbt_daily

# Ad-hoc — run a specific model and all downstream
docker compose exec airflow-scheduler \
  airflow dags trigger tickit_dbt_adhoc \
  --conf '{"command": "run", "selector": "fct_sales+"}'

# Ad-hoc — build (run + test) an entire layer
docker compose exec airflow-scheduler \
  airflow dags trigger tickit_dbt_adhoc \
  --conf '{"command": "build", "selector": "path:models/marts"}'
```

## Architecture

```
docker-compose.yml
├── postgres          — Airflow metadata DB
├── airflow-webserver — UI on :8080
├── airflow-scheduler — DAG scheduling + task execution
└── airflow-init      — One-time: DB migrate, user, connection

Dockerfile
├── apache/airflow:2.10.4-python3.11  (base)
├── astronomer-cosmos 1.14.0          (Airflow Python env)
└── dbt-redshift 1.10.0               (isolated /opt/airflow/dbt-venv)

Volumes
└── ../dbt  →  /opt/airflow/dbt       (live mount — manifest + models)
```

## File Structure

```
airflow/
├── Dockerfile            # Image build
├── docker-compose.yml    # Services
├── requirements.txt      # Airflow Python env deps (cosmos)
├── .env.example          # Credential template
└── dags/
    ├── common.py                    # Shared ProfileConfig, ExecutionConfig
    ├── tickit_dbt.py                # Full pipeline DAG
    ├── tickit_dbt_staging.py        # Staging subset DAG
    ├── tickit_dbt_intermediate.py   # Intermediate subset DAG
    ├── tickit_dbt_marts.py          # Marts subset DAG
    └── tickit_dbt_adhoc.py          # Ad-hoc trigger DAG
```
