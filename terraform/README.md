# Terraform — Redshift Serverless Infrastructure

Provisions all AWS infrastructure for the analytics platform.

## Resources

| Resource | Details |
|---|---|
| Redshift Serverless Namespace | `analytics`, database `analytics`, admin user `admin` |
| Redshift Serverless Workgroup | `analytics`, 8 RPU, publicly accessible |
| Security Group | Port 5439 restricted to `allowed_cidr_blocks` |
| Redshift Schemas | Driven by `schemas.csv` — created via `aws redshift-data execute-statement` |
| S3 Backend | `redshift-infra-terraform-state-725960` in `eu-west-2` |

## Schema Management

Schemas are defined in `schemas.csv`:

```csv
name,database
staging_tickit,analytics
intermediate,analytics
marts,analytics
snapshots,analytics
```

To add a schema: add a row to `schemas.csv` and run `terraform apply`.
Never hardcode schema names in `.tf` files.

## Files

| File | Purpose |
|---|---|
| `main.tf` | Security group, Redshift namespace and workgroup |
| `schemas.tf` | Reads `schemas.csv` and creates schemas via AWS CLI |
| `schemas.csv` | Source of truth for schema names and databases |
| `variables.tf` | All input variables with descriptions and defaults |
| `terraform.tfvars` | Non-sensitive variable values, including CIDR allowlist |
| `versions.tf` | S3 backend, AWS and null provider version pins |
| `outputs.tf` | Workgroup endpoint and ARN |

## Secrets

- `admin_password` is the only secret — passed via `TF_VAR_admin_password` env var
- Set in `~/.zshrc`: `export TF_VAR_admin_password="..."`
- Never commit passwords to `terraform.tfvars` or any `.tf` file

## Deployment

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars

# Update allowed_cidr_blocks with your public IP/CIDR before apply

# First time
terraform init

# Preview changes
terraform plan

# Apply
terraform apply

# After adding a provider
terraform init -upgrade
```

## Notes

- Keep `allowed_cidr_blocks` narrow. Avoid `0.0.0.0/0` outside short-lived demos.
- Never commit `terraform.tfstate` or `terraform.tfstate.backup` — state is stored in S3
