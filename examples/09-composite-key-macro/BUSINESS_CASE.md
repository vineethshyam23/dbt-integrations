# Business case — composite match-key macro

## Problem

Cross-system matching is worthless if you cannot say "this CRM account and
this ERP partner are the same pair we saw last week." Teams that build the
pair key ad hoc in SQL hit the same failures:

- Null on one side → `concat` returns null → snapshot unique_key collapses
- Integer vs string casting drifts between staging and snapshot
- Separators that allow `"12"||"3"` vs `"1"||"23"` collisions
- Copy-pasted coalesce logic that drifts when someone "simplifies" one model

When the key drifts, SCD history forks: the same real-world pair gets a new
surrogate every reload, and match-quality trends become noise.

## Decision

Ship a two-argument macro and use it at staging:

```sql
{{ composite_match_key("id_source_1", "id_source_2") }} as composite_key
```

Contract:

1. Cast both sides to string before hashing.
2. Coalesce nulls to the literal `'null'` so missing sides are stable.
3. Join with `'||'` so digit boundaries do not collide.
4. Hash with MD5 and expose lowercase hex via `to_hex`.

Snapshots put `composite_key` in `unique_key` alongside country / source
labels — not the two raw id columns alone.

## Business impact

- **Match history stays coherent** across weekly reloads of the same pair.
- **Ops can debug** with one hex column instead of reconstructing coalesce
  rules from four models.
- **Downstream joins** (enrichment, exclusion sets) share the same pair
  identity without re-implementing null handling.
- **Cost** is one MD5 per staging row — cheap relative to fuzzy scoring
  upstream; do not re-hash in every intermediate select.

## When not to use this

- Single-system surrogate keys — use the natural id, no composite needed.
- Keys that must be reversible / human-readable — keep a structured struct
  or two columns and a separate display label.
- Cryptographic identity or PII redaction — this is a warehouse join key,
  not a privacy control (use salted hashing patterns for that).
