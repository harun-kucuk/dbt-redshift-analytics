---
paths: ["terraform/**"]
---

# Terraform Rules

## Secrets
- Non-sensitive variables live in `terraform.tfvars` (committed)
- `admin_password` is the only secret — passed via `TF_VAR_admin_password` env var, set in `~/.zshrc`
- Never put passwords, access keys, or tokens in `terraform.tfvars` or any `.tf` file
- `~/.dbt/profiles.yml` holds DB credentials — it lives outside the repo intentionally

## State
- Backend: S3 bucket `redshift-infra-terraform-state-725960`, key `redshift-serverless/terraform.tfstate`, region `eu-west-2`
- Never commit `terraform.tfstate` or `terraform.tfstate.backup` locally

## Schemas
- Schema list lives in `terraform/schemas.csv` (columns: `name`, `database`)
- To add/remove a schema: edit `schemas.csv` and run `terraform apply`
- Never hardcode schema names in `schemas.tf` — always read from the CSV

## Security Group
- The security group uses `lifecycle { ignore_changes = [ingress] }` — do not remove this
- Ingress rules for laptop IPs are added manually via CLI and must not be managed by Terraform

## Variables
- All configurable values go in `variables.tf` with descriptions and defaults
- Secrets (e.g. `admin_password`) must be `sensitive = true`
- Never hardcode secrets in `.tf` files — use `terraform.tfvars` (not committed)

## Naming
- Resource names use `var.workgroup_name` or `var.namespace_name` as prefix
- Tags always include `Project = "dbt-redshift-analytics"`

## Providers
- AWS provider version pinned to `~> 5.0`
- Null provider version pinned to `~> 3.0`
- Run `terraform init -upgrade` after adding a new provider
