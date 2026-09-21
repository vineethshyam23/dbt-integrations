# Data flow — dbt model unit tests

## Build path

1. ERP match logic lands (or is stubbed) as
   `int_payments_erp_terminal_match` — one or more candidate
   merchant/store rows per terminal.
2. Current payments assignment lands as `payments_terminal_data`
   (`terminal_id`, `merchant_id`, `store_id`).
3. `dbt run --select int_payments_terminal_reassign_audit` ranks candidates,
   classifies `feed_status`, drops merchant-already-assigned rows, and sets
   `is_in_feed`.
4. `dbt test --select int_payments_terminal_reassign_audit` runs schema tests
   plus every `unit_tests:` block in `schema.yml`.
5. Downstream feed jobs read `where is_in_feed` — they never re-implement the
   case logic.

## Unit-test execution path

| Step | What happens |
|------|----------------|
| Compile | dbt builds the audit SQL against the project graph |
| Inject | `given` rows replace `ref(...)` relations for that test only |
| Run | Model SQL executes on the fixture tables (warehouse engines vary) |
| Assert | Output rows compared to `expect.rows` (dict format) |

No production ERP or payments tables are scanned during unit tests.

## Grain

| Layer | Grain | Notes |
|-------|-------|-------|
| Match stub | terminal × candidate store | Multiple lots / stores possible |
| Payments stub | terminal_id | Current assignment only |
| Audit | terminal_id (dedupe winner) | Losers never land in the table |

Dedupe order: `store_id` ascending, then newest `lot_create_timestamp`,
then highest `lot_id`.

## Failure modes to watch

| Symptom | Likely cause |
|---------|----------------|
| Unit test expects a row, gets `[]` | `excluded_merchant_assigned` filter too aggressive |
| Extra rows with `dedupe_rank > 1` | Filter dropped; losers leaking into audit |
| `accepted_values` fail on `feed_status` | New status string added in SQL but not YAML |
| Flaky unit test on timestamps | Asserting `evaluated_at` — omit it from expect |
| CI skips unit tests | Older dbt; need dbt-core that supports `unit_tests:` |

## Placeholder mapping

| Concept | Portfolio name |
|---------|----------------|
| Warehouse project | `your-gcp-project` |
| Intermediate dataset | `intermediate` |
| Marts dataset | `marts` |
| ERP side | `erp` |
| Payments provider | `payments` |
| Upstream pattern shape | intermediate reassignment audit + `unit_tests:` YAML |
