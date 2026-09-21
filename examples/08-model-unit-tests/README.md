# Model unit tests (payments terminal reassignment audit)

dbt `unit_tests:` for a branchy intermediate that decides which terminals
belong in a reassignment feed. Schema tests catch grain problems; unit
tests catch the `case` logic with mocked `ref()` fixtures — no warehouse
scan of ERP or payments tables.

## Why it exists

Reassignment eligibility is easy to break and expensive to debug in CI that
only runs against yesterday's extract. Five status branches and a
`row_number` dedupe need explicit fixtures: include when store is null,
include on merchant mismatch, exclude when already assigned, exclude when
the terminal is missing upstream, and keep only the dedupe winner.

## File index

| Path | Role |
|------|------|
| `models/int_payments_erp_terminal_match.sql` | Stub match grain (`where false`) |
| `models/payments_terminal_data.sql` | Stub current payments assignment |
| `models/int_payments_terminal_reassign_audit.sql` | Rank → classify → filter |
| `models/schema.yml` | Column tests + five `unit_tests:` blocks |
| `BUSINESS_CASE.md` | Cost / reliability rationale |
| `ARCHITECTURE.md` | Mermaid component + branch diagrams |
| `DATA_FLOW.md` | Build path and unit-test execution |

Also see [`../../tests/README.md`](../../tests/README.md) for where unit
tests live in this repo vs singular SQL tests.

## How to run (conceptually)

1. Copy the three models + `schema.yml` into your project (or adapt the
   audit SQL onto your real match / terminal refs).
2. Replace stubs with production models that expose the same column names.
3. `dbt run --select int_payments_terminal_reassign_audit`
4. `dbt test --select int_payments_terminal_reassign_audit`
   (runs schema + unit tests together on current dbt-core)
5. Optionally: `dbt test --select "test_type:unit"` to run only unit tests

Requires a dbt-core version that supports native `unit_tests:` in YAML.

## Sanitization notes

- GCP project / datasets → `your-gcp-project`, `intermediate`, `marts`.
- Payments provider and ERP product names replaced with generic
  `payments` / `erp`.
- Company / merchant / terminal identifiers replaced with demo placeholders
  (`DemoCorp`, `merchant_demo_est_001`, `TERM-DEMO-001`).
- Orchestrator / feed-consumer product names removed; docs say "feed reader".
- Upstream match SQL (license filters, product SKUs, serial formatting)
  not reproduced — only the audit classification + unit fixtures.
- Provider-specific exclude status strings renamed to
  `excluded_terminal_not_in_payments`.

## Tradeoffs

**Pros:** fast feedback on branching logic; fixtures document the product
rules for reviewers; empty expect rows prove exclusions.

**Cons:** unit tests do not catch join-key type mismatches against real
tables; you still need schema / integration tests. Fixture YAML grows
noisy if you assert every output column — keep expects lean.
