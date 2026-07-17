# dbt Patterns Backlog

Tracks pattern candidates for `vineethshyam23/dbt-integrations`.  
Source: `hospitality-digital/datalogue/dwh/dbt` (read-only, GitLab).

---

## Status key

| Symbol | Meaning |
|--------|---------|
| `[ ]` | Candidate — not started |
| `[~]` | In progress |
| `[x]` | Done — shipped |
| `[-]` | Skipped / deferred |

---

## Done

(none)

---

## Candidates

### 01 — Incremental filter macro

**Branch target:** `feature/dbt-01-incremental-filter`  
**Folder:** `macros/` + `examples/01-incremental-filter/`  
**Description:** Reusable Jinja macro that generates the incremental `WHERE` clause (watermark filter + partition pruning). Keeps incremental logic DRY across many models.  
**Status:** `[ ]`

---

### 02 — Staging model + tests YAML

**Branch target:** `feature/dbt-02-staging-with-tests`  
**Folder:** `examples/02-staging-with-tests/`  
**Description:** Full staging layer example — source YAML, model SQL, and schema YAML with `not_null`, `unique`, `accepted_values`, and source freshness tests.  
**Status:** `[ ]`

---

### 03 — Dataset / materialization router macro

**Branch target:** `feature/dbt-03-dataset-router-macro`  
**Folder:** `macros/` + `examples/03-dataset-router-macro/`  
**Description:** Macro that routes model output to the correct BigQuery dataset (e.g. dev/staging/prod) and sets materialization config based on environment + model tier.  
**Status:** `[ ]`

---

### 04 — Intermediate enrichment join

**Branch target:** `feature/dbt-04-intermediate-enrichment`  
**Folder:** `examples/04-intermediate-enrichment/`  
**Description:** Intermediate model that joins two staging sources (e.g. orders + customers), applies coalesce/nullif cleanup, and passes a clean, joined grain to a downstream mart.  
**Status:** `[ ]`

---

### 05 — Mart with model contract

**Branch target:** `feature/dbt-05-mart-with-contract`  
**Folder:** `examples/05-mart-with-contract/`  
**Description:** Consumer-facing mart with explicit `contract:` block in schema YAML (column types, constraints). Shows how to pin public API for downstream consumers.  
**Status:** `[ ]`

---

## Run log

| Date | Pattern shipped | Branch | PR | Notes |
|------|----------------|--------|-----|-------|
| 2026-07-17 | None | — | — | GitLab token scoped to `airflow2` project only; `dwh/dbt` returns 404. Auth failure — stop condition triggered. Backlog created. |
