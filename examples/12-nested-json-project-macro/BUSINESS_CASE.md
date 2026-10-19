# Business case — nested JSON project / schema-spec

## Problem

Marketplace (and similar) streams land as nested JSON. Typed warehouse tables
are what analysts and contracts need. The naive path — paste `json_value`
trees into each intermediate — fails in three predictable ways:

- Publisher renames `@id` → `id` (or sends both); half the models miss it
- Nested address / geo / menu-link shapes diverge across copy-pasted SQL
- Adding one field means touching every resource model and hoping CI catches
  the typo in a JSON path string

On a multi-resource subscription this becomes a weekly tax: broken joins,
null-filled marts, and PRs that are 90% path noise.

## Decision

Separate **shape** from **routing**:

1. Shared staging routes and quarantines (pattern 11).
2. A **schema-spec** macro per resource lists name, type, mode, optional
   aliases / path overrides, and nested `fields`.
3. **`project_nested_json`** expands the spec into SAFE JSON extracts, casts,
   STRUCT / ARRAY construction, and alias COALESCE.

Typed intermediates become: filter watermark → `project_nested_json(payload,
resource_schema())` → broker keys.

## Business impact

- **Maintainability:** field adds are a spec change, not an N-model SQL edit.
- **Correctness:** aliases and nested types are defined once; unit tests pin
  the projector without scanning the streaming table.
- **Cost:** incremental merge on `message_id` with a publish_time watermark
  (plus a short lookback) keeps slot usage tied to new messages, not full
  re-projection of history on every run.
- **Privacy:** portfolio / shared specs omit PII columns so teaching copies
  never become a contact dump.

## When not to use this

- Flat, stable APIs with five columns — write the SELECT; the macro is
  overhead.
- Schemas that change every deploy without a generation step — you will
  fight the spec. Automate export → macro, or use a different contract layer.
- Need for open-ended JSON passthrough in marts — keep a `payload` column;
  do not force every key through the projector.
