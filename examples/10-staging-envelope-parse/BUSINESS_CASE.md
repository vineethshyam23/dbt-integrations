# Business case — staging envelope parse with unit test

## Problem

Streaming CMS / listing systems land into BigQuery via Pub/Sub subscriptions.
The landing table is a broker envelope: `message_id`, `publish_time`, and a
JSON `data` blob. Downstream models that unpack every field in the first
staging view become brittle:

1. **Parse regressions** — a renamed envelope key (`type` vs `@type`) silently
   nulls out filters; typed intermediate models process zero rows.
2. **Expensive CI** — validating parse logic against the full landing table
   scans days of partitions for a few string extractions.
3. **Mixed message types** — Event, BusinessUnit, and IdMapping share one
   subscription; without a promoted discriminator, every consumer re-parses
   the same JSON path.

Schema tests alone do not prove `json_value` paths. You need a fixture that
feeds a known envelope and asserts the extracted columns.

## Decision

Keep a **thin envelope staging view** plus a **dbt unit test** on the parse:

- Promote only the fields every consumer needs: `msg_type`, `operation`,
  `envelope_ts`, and the nested `payload` as a JSON string.
- Preserve `message_id` / `publish_time` for incremental anti-joins and
  watermarks downstream (do not drop broker metadata).
- Add one `unit_tests:` block that mocks `source(...)` with a minimal Event
  fixture and asserts the extracted columns — no warehouse scan.
- Soft-warn on unexpected `msg_type` values so new envelope types surface in
  CI without hard-blocking the pipeline on day one.

Typed unpack of `payload` (review replies, business-unit attrs, etc.) stays
in intermediate models that filter on `msg_type`. Staging stays boring on
purpose.

## Business impact

- **Reliability:** parse breaks fail in `dbt test` with a fixture, not in a
  Monday dashboard that silently dropped Events.
- **Cost:** unit tests compile against mocked rows; CI does not scan the
  streaming landing table to prove `json_value` paths.
- **Maintainability:** one place documents the envelope contract; typed
  models stop re-implementing the same JSON paths.

## When not to use this shape

- Envelope schemas differ wildly per message and need heavy branching — use
  a resource-router staging model (separate pattern) instead of a single
  thin parse.
- You need SCD history of envelopes — snapshot or incremental sink after
  this view, do not thicken the staging select.
- Payload-level business rules do not belong here; keep them behind
  `msg_type` filters in intermediate models.
