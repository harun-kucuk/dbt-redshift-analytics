---
paths: ["dbt/macros/**"]
---

# Macros Rules

Three macros exist — use them; do not duplicate their logic inline.

## `safe_divide(numerator, denominator)`
Zero-safe division. Returns `null` when denominator is 0 or null.
```sql
{{ safe_divide('sum(price_paid)', 'count(sale_id)') }}
```
Use anywhere a ratio could produce a divide-by-zero error.

## `test_is_positive(model, column_name)`
Generic dbt test. Asserts all non-null values in a column are > 0.
```yaml
tests:
  - is_positive
```
Apply to numeric columns that must be strictly positive (e.g. `price_paid`, `quantity`).

## `generate_schema_name(custom_schema_name, node)`
Controls how dbt resolves schema names across targets:
- **prod**: uses the exact `custom_schema_name` from `dbt_project.yml`
- **CI** (`DBT_TARGET_SCHEMA` set to `ci_pr_<N>`): prefixes the schema with `ci_pr_<N>_`
- **dev**: prefixes with the dbt username

Do not change the `ci_pr_` prefix logic — CI schema cleanup (`pr-cleanup` workflow) depends on this exact pattern.

## Adding a New Macro
- One file per macro in `dbt/macros/`
- Name the file and macro identically
- Add to this file if it introduces a usage contract other models must follow
