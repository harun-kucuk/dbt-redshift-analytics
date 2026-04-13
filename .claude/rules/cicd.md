# CI/CD Rules

## Active Workflows
| Workflow | Trigger | Purpose |
|---|---|---|
| `dbt-ci` | PR touching `dbt/**` | SQLFluff lint → defer build in PR-isolated schemas |
| `dbt-cd` | Push to `main` touching `dbt/**` | State-aware prod build → upload manifest to S3 |
| `dbt-docs` | Push to `main` touching `dbt/**` | Generate and publish dbt docs to GitHub Pages |
| `pr-cleanup` | PR closed | Drop `ci_pr_<N>_*` schemas from dev DB |

## Disabled Workflows (manual only)
- `terraform-ci` — disabled (trigger: `workflow_dispatch`)
- `terraform-cd` — disabled (trigger: `workflow_dispatch`)

To run Terraform in CI manually: GitHub Actions → terraform-ci / terraform-cd → "Run workflow".

## dbt CI Schema Pattern
CI builds run in isolated schemas named `ci_pr_<PR_NUMBER>_<layer>`:
```
ci_pr_9_staging_tickit
ci_pr_9_intermediate
ci_pr_9_marts
```
Driven by `dbt/macros/generate_schema_name.sql` — do not change the `ci_pr_` prefix logic.

## Secrets Required
| Secret | Used by |
|---|---|
| `DBT_HOST` | dbt-ci, dbt-cd, dbt-docs |
| `DBT_PASSWORD` | dbt-ci, dbt-cd, dbt-docs |
| `AWS_ACCESS_KEY_ID` | dbt-ci, dbt-cd (S3 manifest), terraform-ci, terraform-cd |
| `AWS_SECRET_ACCESS_KEY` | same as above |
| `SLACK_WEBHOOK_URL` | dbt-cd, terraform-cd failure alerts |
| `TF_VAR_ADMIN_PASSWORD` | terraform-ci, terraform-cd |

## Allowed
- Adding new workflow triggers (e.g. `schedule`) to existing dbt workflows
- Adding new `env:` vars to workflow steps that call dbt
- Re-enabling terraform workflows by restoring the original `on: push/pull_request` triggers

## Not Allowed
- Adding hardcoded secrets, credentials, or account IDs to workflow files
- Skipping the `state:modified+1` defer pattern in dbt-ci (defeats the purpose of CI)
- Using `--no-verify` to bypass pre-commit checks
