# Data flow — composite match-key

## Build path

1. Matching job lands candidates in `raw_match.entity_match_results`.
2. `stg_entity_match_results`
   - cast ids / scores / timestamps
   - `composite_match_key(id_source_1, id_source_2)` → `composite_key`
3. `entity_match_results_snapshot`
   - QUALIFY latest row per
     `(country_code, source_1, source_2, composite_key, match_type)`
   - timestamp SCD on `source_create_ts`
4. Intermediate / marts join or filter on `composite_key` (and country /
   source labels as needed).

## Grain

| Layer | Grain | Notes |
|-------|-------|-------|
| Landing | one row per match-job emission | may replay the same pair |
| Staging | same as landing + `composite_key` | no uniqueness tests |
| Snapshot current | one open row per unique_key | SCD Type 2 history retained |

## Null / separator behavior

| id_source_1 | id_source_2 | Concat payload | Notes |
|-------------|-------------|----------------|-------|
| `42` | `99` | `42\|\|99` | happy path |
| `NULL` | `99` | `null\|\|99` | null sentinel |
| `12` | `3` | `12\|\|3` | ≠ `1\|\|23` |
| `null` (string) | `99` | `null\|\|99` | same as SQL NULL by design |

## Failure modes to watch

| Symptom | Likely cause |
|---------|----------------|
| Snapshot opens a new version every run for the "same" pair | One model still builds the key with a different separator / null token |
| Unexpected key collisions | Changed cast rules (e.g. float `12.0` vs int `12`) before the macro |
| Duplicate current snapshot rows | Forgot QUALIFY before snapshot; batch reloaded identical pairs |
| Historical keys stop matching after a macro edit | Separator or sentinel changed — treat as breaking; backfill |

## Placeholder mapping

| Concept | Portfolio name |
|---------|----------------|
| GCP project | `your-gcp-project` |
| Landing dataset | `raw_match` |
| Staging | `staging` |
| Left / right systems | `crm` / `erp` (via `source_1` / `source_2` values) |
| Production macro name | `matching_engine_id_composite_key` → `composite_match_key` |
