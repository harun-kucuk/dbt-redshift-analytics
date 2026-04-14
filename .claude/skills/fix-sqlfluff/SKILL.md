Fix all SQLFluff linting violations in this project.

Steps:
1. `cd dbt && python3 -m sqlfluff lint models macros tests --dialect ansi`
2. Fix violations — use `sqlfluff fix` where safe, manually fix the rest
3. Re-run lint to confirm zero violations
4. Do not change SQL logic — formatting only

Style rules (from `.sqlfluff`):
- All keywords, identifiers, functions: **lowercase**
- Indentation: 4 spaces
- Table aliases: implicit — `from sales s`, not `from sales as s`
- Column aliases: explicit — `salesid as sale_id`
- Max line length: 120 characters
