# Macros

Reusable Jinja/SQL helpers. Prefer small, documented macros over copy-paste SQL.

| Macro | Purpose | Example |
|-------|---------|---------|
| `get_filter_val` | Incremental watermark: `max(date(column))` as a quoted date literal | `examples/01-incremental-filter/` |
| `generate_database_name` | Route BigQuery project by target (prod/dev) | `examples/03-dataset-router-macro/` |
| `set_schema` | Prefix + env-var dataset router; pairs with `generate_schema_name` override | `examples/03-dataset-router-macro/` |
| `normalize_text` (+ linebreak / email helpers) | Staging linebreak preserve, intermediate text normalize, salted email hash + domain | `examples/07-text-clean-macro/` |
| `composite_match_key` | Null-safe MD5 hex key for a pair of source ids (snapshot unique_key / joins) | `examples/09-composite-key-macro/` |
