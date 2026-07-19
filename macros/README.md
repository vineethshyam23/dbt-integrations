# Macros

Reusable Jinja/SQL helpers. Prefer small, documented macros over copy-paste SQL.

| Macro | Purpose | Example |
|-------|---------|---------|
| `get_filter_val` | Incremental watermark: `max(date(column))` as a quoted date literal | `examples/01-incremental-filter/` |
