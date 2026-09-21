# Tests

This portfolio keeps **singular SQL tests** (assert-style) and documents
**dbt native `unit_tests:`** next to the models they cover.

| Kind | Where | When to use |
|------|-------|-------------|
| Schema / data tests | model YAML (`data_tests`) | Grain, nulls, accepted values on real builds |
| Unit tests | model YAML (`unit_tests:`) | Branchy transform logic with mocked `ref()` / `source()` rows |
| Singular SQL | `tests/*.sql` | Cross-model invariants that do not fit one YAML block |

## Pattern reference

See [`examples/08-model-unit-tests/`](../examples/08-model-unit-tests/) for a
full payments-terminal reassignment audit with five unit fixtures
(include / exclude / empty / dedupe).

Singular SQL assert examples can land here in a later run when a
cross-model invariant is worth teaching on its own.
