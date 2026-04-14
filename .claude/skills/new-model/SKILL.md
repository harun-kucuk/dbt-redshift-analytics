Scaffold a new dbt model for this project.

Arguments: $ARGUMENTS — `<layer> <entity> <description>` e.g. `staging sales Raw sales transactions`
If not provided, ask for layer, entity name, and a brief description.

Follow the layer rules and SQL patterns already in context (`.claude/rules/`). Then:

1. Create `dbt/models/<layer>/<name>.sql` using the correct pattern for the layer
2. Add an entry to the layer's `_models.yml`:
   - Model-level description
   - All output columns with descriptions
   - `not_null` + `unique` on the primary key
   - `is_positive` on any price, amount, or quantity columns
