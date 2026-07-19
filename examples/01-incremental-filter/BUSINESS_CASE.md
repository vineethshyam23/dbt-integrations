# Business case — incremental watermark macro

## Problem

Incremental models on SCD / CRM-style feeds often need “only rows changed since
the last successful merge.” Teams copy the same `max(_updated_at)` subquery into
dozens of models. Over time those copies diverge: missing defaults, timestamp vs
date comparisons, and inconsistent lookbacks. That shows up as flaky first runs
after a full refresh and as harder code review.

## Decision

Centralize the watermark as a small Jinja macro (`get_filter_val`) that:

1. Queries `max(date(<column>))` from the target relation.
2. Coalesces to `1970-01-01` when the table is empty or the query cannot run at
   parse time.
3. Returns a quoted date literal so the model SQL stays simple.

## Business impact

- **Cost:** Incremental merges stay bounded to recent change days instead of
  full-history scans on every run. On large CRM snapshots that is the difference
  between a cheap merge and a repeated full rewrite.
- **Reliability:** Empty / newly created targets do not fail the watermark
  subquery; the default date forces a one-time historical load.
- **Maintainability:** Reviewers check one macro instead of N near-identical
  filters when changing defaults or quoting rules.

## When not to use this

- High-volume event facts where you want a fixed lookback (`interval N day`)
  rather than “since last max.”
- Tables without a trustworthy update column.
- Cases where you must filter on a timestamp with sub-day precision — extend
  the macro deliberately rather than casting everything to `date`.
