# Macros

Reusable Jinja/SQL helpers. Prefer small, documented macros over copy-paste SQL.

| Macro | Purpose | Example |
|-------|---------|---------|
| `get_filter_val` | Incremental watermark: `max(date(column))` as a quoted date literal | `examples/01-incremental-filter/` |
| `generate_database_name` | Route BigQuery project by target (prod/dev) | `examples/03-dataset-router-macro/` |
| `set_schema` | Prefix + env-var dataset router; pairs with `generate_schema_name` override | `examples/03-dataset-router-macro/` |
