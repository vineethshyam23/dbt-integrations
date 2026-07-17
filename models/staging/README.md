# Staging models

Source-aligned models. Prefer `source()` for upstream tables and keep transformations light (rename, cast, filter deleted rows).

## Planned examples

- Staging from a CRM source with freshness tests
- Staging from an ERP source with not_null / unique tests on business keys
