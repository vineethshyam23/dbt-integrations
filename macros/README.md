# Macros

Reusable Jinja/SQL helpers. Prefer small, documented macros over copy-paste SQL.

| Macro | Purpose | Example |
|-------|---------|---------|
| `get_filter_val` | Incremental watermark: `max(date(column))` as a quoted date literal | `examples/01-incremental-filter/` |
| `generate_database_name` | Route BigQuery project by target (prod/dev) | `examples/03-dataset-router-macro/` |
| `set_schema` | Prefix + env-var dataset router; pairs with `generate_schema_name` override | `examples/03-dataset-router-macro/` |
| `normalize_text` (+ linebreak / email helpers) | Staging linebreak preserve, intermediate text normalize, salted email hash + domain | `examples/07-text-clean-macro/` |
| `composite_match_key` | Null-safe MD5 hex key for a pair of source ids (snapshot unique_key / joins) | `examples/09-composite-key-macro/` |
| `parse_flexible_timestamp` | Safe cast string / RFC3339 / epoch-millis timestamps; nulls out-of-range epochs | `examples/11-resource-router-error-sink/` |
| `project_nested_json` (+ path / cast helpers) | Schema-spec driven JSON → typed columns (STRUCT / ARRAY / aliases) | `examples/12-nested-json-project-macro/` |
| `marketplace_venue_schema` | Teaching venue schema-spec for `project_nested_json` | `examples/12-nested-json-project-macro/` |
| `expand_nested_sections` (`menu_section_expansion_ctes`, helpers) | Flatten nested `hasMenuSection` trees to descendant section grain | `examples/13-nested-section-expand/` |
| `marketplace_menu_section_schema` | Teaching menu-section schema-spec after expand + enrich | `examples/13-nested-section-expand/` |
