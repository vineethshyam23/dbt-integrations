# Business case — intermediate enrichment join

## Problem

CRM activity extracts rarely carry the external account key that ERP and
downstream marts need. Related ids point at CRM-internal objects; the useful
uid lives on the account (or on a person-account reached through a task). If
every consumer re-implements those joins, you get divergent coalesce orders,
duplicate rows from fan-out, and accidental pulls of mailbox PII into analytic
tables.

## Decision

Keep a dedicated **intermediate enrichment** model that:

1. Starts from a thin staging activity view (ids + flags, no body / addresses).
2. Left-joins account, user, and task dimensions so missing dims never drop
   the fact row.
3. Publishes one coalesced `external_id` with a documented fallback order.

Materialize as a **table** when this relation feeds a sync or a mart that is
read more often than rebuilt — you pay once for the join, not on every
downstream query.

## Business impact

- **Reliability:** one place owns attribution logic; sync jobs stop guessing
  which CRM id is the “real” account.
- **Cost:** join work is bounded to the intermediate rebuild, not repeated in
  every BI extract that needs the same key.
- **Privacy / blast radius:** mailbox fields stay out of the enrichment path;
  fewer columns means fewer accidental exposures in shared datasets.

## When not to use this

- Pure staging renames with no dimension lookup — keep those as views.
- High-volume event streams where you should denormalize at ingest time
  instead of re-joining nightly.
- Cases where a missing account must fail hard — switch left joins to inner
  joins only after you have measured orphan rates.
