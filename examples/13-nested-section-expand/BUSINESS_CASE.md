# Business case — nested section expand

## Problem

Marketplace menu messages carry a nested section tree. Analysts and
downstream SCD tables need **one row per section** with a stable parent
link — not a JSON blob and not a STRUCT that every Looker explore must
UNNEST differently.

Copy-pasting recursive UNNEST SQL into each model fails in practice:

- Root vs descendant emission rules drift between staging and marts
- Parent id resolution (`@id` vs `id`) gets reimplemented with subtle bugs
- Republished menus create duplicate section rows unless the merge key
  includes emission ordinal, not just section id

On a high-volume subscription that tax shows up as broken menu trees in
BI and as full-refresh fire drills when someone "fixes" UNNEST in one
place and not another.

## Decision

Keep projection (pattern 12) and add an **expand** step in front of it:

1. Staging keeps menu messages only.
2. `menu_section_expansion_ctes` walks `hasMenuSection`, omits roots,
   emits descendants with parent id + sort key + emission ordinal.
3. Enrich the section JSON with menu envelope fields, then
   `project_nested_json` through a small section schema-spec.
4. Merge on a hash of message + section + parent + ordinal.

## Business impact

- **Correctness:** warehouse grain matches the streaming unnest contract;
  parent pointers are testable with fixtures.
- **Maintainability:** depth and field names live in macros; models stay
  short SELECT wrappers.
- **Cost:** incremental watermark on `publish_time` (with lookback) avoids
  re-expanding the whole history; cluster by `menu_id` / `section_id` for
  common filters.
- **Privacy:** teaching specs omit item-level contact or free-text dumps;
  keep production PII out of portfolio copies.

## When not to use this

- Menus are flat (one level of sections) — a single UNNEST in the mart is
  enough.
- You only expose the nested STRUCT to a single internal API — flattening
  adds storage without consumers.
- Depth regularly exceeds what you are willing to compile (`max_depth`);
  fix the publisher or move expansion to the stream processor and land
  flat sections already.
