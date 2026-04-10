.DEFAULT_GOAL := help

# ── Variables ─────────────────────────────────────────────────────────────────
DBT_TARGET   ?= prod
DBT_DIR       = dbt
TF_DIR        = terraform
AIRFLOW_DIR   = airflow

# ── Help ──────────────────────────────────────────────────────────────────────
.PHONY: help
help:
	@echo ""
	@echo "dbt-redshift-analytics"
	@echo ""
	@echo "  dbt"
	@echo "    make deps          Install dbt packages"
	@echo "    make run           dbt run (all models)"
	@echo "    make test          dbt test (all tests)"
	@echo "    make build         dbt build (run + test)"
	@echo "    make snapshot      dbt snapshot"
	@echo "    make compile       dbt compile (regenerates manifest.json)"
	@echo "    make lint          SQLFluff lint"
	@echo "    make lint-fix      SQLFluff fix (auto-correct where possible)"
	@echo "    make docs          Generate and serve dbt docs"
	@echo "    make full-refresh  dbt run --full-refresh"
	@echo ""
	@echo "  Airflow"
	@echo "    make airflow-init  One-time init (DB migrate, user, connection)"
	@echo "    make airflow-up    Start webserver + scheduler"
	@echo "    make airflow-down  Stop all services"
	@echo "    make airflow-logs  Tail scheduler logs"
	@echo ""
	@echo "  Terraform"
	@echo "    make tf-init       terraform init"
	@echo "    make tf-plan       terraform plan"
	@echo "    make tf-apply      terraform apply"
	@echo ""
	@echo "  Utilities"
	@echo "    make clean         Remove dbt target/ and logs/"
	@echo "    make pre-commit    Run pre-commit hooks on all files"
	@echo ""

# ── dbt ───────────────────────────────────────────────────────────────────────
.PHONY: deps
deps:
	cd $(DBT_DIR) && dbt deps

.PHONY: run
run: deps
	cd $(DBT_DIR) && dbt run --target $(DBT_TARGET)

.PHONY: test
test:
	cd $(DBT_DIR) && dbt test --target $(DBT_TARGET)

.PHONY: build
build: deps
	cd $(DBT_DIR) && dbt build --target $(DBT_TARGET)

.PHONY: snapshot
snapshot:
	cd $(DBT_DIR) && dbt snapshot --target $(DBT_TARGET)

.PHONY: compile
compile: deps
	cd $(DBT_DIR) && dbt compile --target $(DBT_TARGET)

.PHONY: full-refresh
full-refresh: deps
	cd $(DBT_DIR) && dbt run --full-refresh --target $(DBT_TARGET)

.PHONY: lint
lint:
	sqlfluff lint $(DBT_DIR)/models $(DBT_DIR)/macros $(DBT_DIR)/tests --dialect ansi

.PHONY: lint-fix
lint-fix:
	sqlfluff fix $(DBT_DIR)/models $(DBT_DIR)/macros $(DBT_DIR)/tests --dialect ansi

.PHONY: docs
docs: compile
	cd $(DBT_DIR) && dbt docs generate --target $(DBT_TARGET) && dbt docs serve

.PHONY: clean
clean:
	rm -rf $(DBT_DIR)/target $(DBT_DIR)/logs $(DBT_DIR)/dbt_packages

# ── Airflow ───────────────────────────────────────────────────────────────────
.PHONY: airflow-init
airflow-init:
	cd $(AIRFLOW_DIR) && docker compose up airflow-init

.PHONY: airflow-up
airflow-up: compile
	cd $(AIRFLOW_DIR) && docker compose up -d airflow-webserver airflow-scheduler
	@echo "Airflow UI: http://localhost:8080  (admin / admin)"

.PHONY: airflow-down
airflow-down:
	cd $(AIRFLOW_DIR) && docker compose down

.PHONY: airflow-logs
airflow-logs:
	cd $(AIRFLOW_DIR) && docker compose logs -f airflow-scheduler

# ── Terraform ─────────────────────────────────────────────────────────────────
.PHONY: tf-init
tf-init:
	cd $(TF_DIR) && terraform init

.PHONY: tf-plan
tf-plan:
	cd $(TF_DIR) && terraform plan

.PHONY: tf-apply
tf-apply:
	cd $(TF_DIR) && terraform apply

# ── Utilities ─────────────────────────────────────────────────────────────────
.PHONY: pre-commit
pre-commit:
	pre-commit run --all-files
