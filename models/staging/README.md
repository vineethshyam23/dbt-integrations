# Staging models

Source-aligned models. Prefer `source()` for upstream tables and keep transformations light (rename, cast, filter deleted rows).

## Examples

| Pattern | Location |
|---------|----------|
| CRM staging + freshness / unique / not_null | [`examples/02-staging-with-tests/`](../../examples/02-staging-with-tests/) |

Production-style tip: put enrichment joins in intermediate, not here.
