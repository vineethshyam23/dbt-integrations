# Business case — resource router + error sink

## Problem

Marketplace / ordering publishers often share one Pub/Sub subscription for
several resource shapes: orders, venues, menus, services. The landing table
is a broker envelope (`message_id`, `publish_time`, JSON `data`). Without a
staging router:

1. **Typed models re-parse `@type`** — each intermediate invents its own
   filter; a publisher rename or new type silently empties one mart while
   another still works.
2. **Bad messages poison marts** — invalid JSON or unknown `@type` values
   either fail a run or land as half-null business rows.
3. **Ops has nowhere to look** — dropping bad rows in a `WHERE` clause hides
   volume and reason codes; support tickets become archaeology on the raw
   landing table.

Pattern 10 (thin CMS envelope parse) promotes a discriminator. This pattern
goes further: **bucket** the message, **quarantine** failures, and prove both
with unit tests.

## Decision

Ship a two-model shape:

1. **`stg_marketplace_events_raw`** (view) — `safe.parse_json`, promote
   `raw_resource` / `resource`, parse flexible timestamps, keep the full
   payload for typed unpack later.
2. **`int_marketplace_events_error`** (incremental merge) — classify
   `invalid_json`, `unsupported_resource`, `invalid_timestamp`; watermark on
   `publish_time` with a short lookback so late duplicates still merge.

Routing rules that matter in production:

- Invalid JSON → `resource = 'error'`
- Null `@type` → default `order` (orders omit the discriminator in this stream)
- Known types → lowercased bucket (`venue`, `menu`, `service`, `disabledservice`)
- Anything else → `error` (do not invent a mart for Coupons on day one)

Typed intermediates filter `where resource = '…'` and never see quarantine
rows. Quarantine is the monitoring surface, not a soft filter inside marts.

## Business impact

- **Reliability:** unknown types and parse failures stop at the sink; marts
  keep a stable grain.
- **Cost:** incremental merge + 1h lookback avoids full scans of the landing
  table on every error-model run; unit tests mock sources so CI does not
  touch streaming partitions.
- **Operability:** `error_reason` is queryable — volume spikes by reason are
  a morning check, not a silent empty dashboard.

## When not to use this shape

- One message type per subscription — prefer the thin envelope parse (pattern
  10); a router is overhead.
- You need SCD history of every envelope — snapshot after staging; do not
  thicken the router select.
- Schema contracts for nested business fields belong in typed intermediates /
  marts, not in the router.
