# Business case — dbt model unit tests

## Problem

Branchy intermediate models — include vs skip, status codes, dedupe winners —
break quietly when someone tweaks a `case` expression. Schema tests
(`not_null`, `unique`, `accepted_values`) only see the output after a full
warehouse build. By then you have already paid for:

1. **Scan cost** on every upstream table the model touches.
2. **Flaky debugging** — you cannot tell whether the bug is data or logic.
3. **Late feedback** — CI that only runs `dbt test` against prod-shaped
   extracts will miss edge cases that never appear in today's sample.

Reassignment / feed-eligibility logic is the classic failure mode: five
branches, two joins, one `row_number`. A wrong `when` order ships terminals
that should have been skipped (or drops ones that should have been assigned).

## Decision

Use **dbt `unit_tests:`** next to the model YAML:

- Mock `ref()` inputs with a handful of synthetic rows.
- Assert exact `feed_status` / `is_in_feed` / dedupe outcomes.
- Cover include, exclude, and empty-result cases in the same file as the
  model contract — not in a separate Python suite nobody runs.

Keep warehouse tests for grain and freshness. Unit tests own the branching
logic.

## Business impact

- **Reliability:** classification rules fail in `dbt test --select unit_test`
  before an orchestrator consumes the feed.
- **Cost:** unit fixtures are tiny; you do not re-scan payments + ERP tables
  to prove a `case` change.
- **Change velocity:** reviewers can read the expected dict rows and argue
  about product rules without spinning BigQuery.

## When not to use this

- Pure pass-through staging with no transforms — freshness + `not_null` is
  enough.
- Tests that need real SCD history volume — use integration tests or a
  curated sample dataset instead of inventing fifty fixture rows.
- Assertions on non-deterministic columns (`current_timestamp()`, random
  UUIDs) — omit them from `expect.rows` or the unit test will flake.
