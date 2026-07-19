# Data flow — incremental filter

## First run (full load)

1. `is_incremental()` is false.
2. Model selects all current SCD rows (`dbt_valid_to is null`) from the snapshot ref.
3. Table is created / replaced with the full current set. No watermark query runs.

## Subsequent runs (incremental merge)

1. dbt enters the `{% if is_incremental() %}` block.
2. `get_filter_val(this, '_updated_at')` issues a short metadata query against the
   existing target: `max(date(_updated_at))`, coalesced to `1970-01-01`.
3. The model filters snapshot rows to `date(_updated_at) >= '<watermark>'`.
4. Merge applies on `(country_code, account_id)` with `on_schema_change =
   sync_all_columns`.

## Same-day churn

Because the comparison uses **date** (not timestamp), any update on the watermark
day is re-read. That is intentional for CRM SCD merges: a little overlap is
cheaper than missing late same-day updates. If cost becomes an issue, switch to a
timestamp watermark or add a small lookback buffer explicitly.

## Failure modes to watch

| Symptom | Likely cause |
|---------|----------------|
| First incremental after truncate reloads everything | Expected — max is null → default date |
| Compiled SQL always shows `1970-01-01` | Looking at parse-time render; check `execute` path / run logs |
| Merge volume stays huge | Watermark column not advancing, or upstream snapshot not updating `_updated_at` |
| Duplicate key errors | Unique key does not match grain of the select |

## Placeholder mapping

| Concept | Portfolio name |
|---------|----------------|
| Warehouse project | `your-gcp-project` |
| Intermediate dataset | `intermediate` |
| Source system | `crm` |
| Snapshot feed | `crm_account_snapshot` |
