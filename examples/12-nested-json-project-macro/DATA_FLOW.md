# Data flow — nested JSON project / schema-spec

## Happy path

1. Landing table receives Pub/Sub rows (`message_id`, `publish_time`, `data`).
2. `stg_marketplace_venues` parses `data` → JSON, keeps rows where `@type`
   is `venue` (standalone teaching filter; production may `ref` the shared
   router from pattern 11).
3. `int_marketplace_venues` on incremental runs applies a publish_time
   watermark with a one-hour lookback (late / redelivered messages).
4. `project_nested_json('payload', marketplace_venue_schema())` expands into
   typed columns: scalars, `address` / `geo` STRUCTs, `serves_cuisine` and
   `menu_refs` arrays.
5. Merge on `message_id`. Cluster by `venue_id`, `publish_time`, `message_id`
   for common consumer filters.

## Failure modes

| Symptom | Likely cause | What to check |
|---------|--------------|---------------|
| `venue_id` null | Publisher omitted both `@id` and `id` | Quarantine upstream; do not invent ids |
| Nested STRUCT all-null | Parent JSON key missing | Spec `path` vs actual key; null STRUCT is intentional |
| TIMESTAMP null | Unparseable string / out-of-range epoch | `parse_flexible_timestamp` guards; fix publisher |
| Compile error unsupported type | Spec uses a type the cast macro rejects | Extend `cast_nested_json_scalar` or fix the export |
| Unit test misses nested fields | Fixture JSON keys ≠ spec paths / aliases | Align fixture to the teaching schema |

## Watermark note

The one-hour lookback is a pragmatic default for streaming redelivery, not a
universal SLA. Tighten if duplicates are cheap to merge; widen if publishers
backfill older `publish_time` values into the same subscription.

## Relation to adjacent patterns

| Pattern | Boundary |
|---------|----------|
| 10 Staging envelope parse | Discriminator + thin columns; no nested projector |
| 11 Resource router + error sink | Routes / quarantines; does not type nested structs |
| **12 Nested JSON project** | Schema-spec → typed intermediate columns |
