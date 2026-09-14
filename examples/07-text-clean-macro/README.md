# Text-clean / normalize macros

Reusable helpers for free-text and email fields that cross staging →
intermediate. Staging often keeps line breaks as HTML-ish placeholders;
intermediate strips control characters and edge `<br />` so joins and exports
stay consistent. Email is hashed with a project-var salt — never a hardcoded
production secret in git.

## Why it exists

CRM / CMS extracts dump messy strings: Windows CR/LF, export-padded `<br />`,
mixed case emails. Copy-pasting the same nested `replace` / `regexp_replace`
into fifty models drifts within a week. Worse: hardcoding an MD5 salt in a
macro means every fork and every PR leaks a durable hashing key.

Central macros fix both problems:

| Macro | Layer | Job |
|-------|-------|-----|
| `preserve_linebreaks` | staging | CR/LF → `<br />` so ops UIs can re-render notes |
| `normalize_text` | intermediate | strip CR/LF + leading/trailing `<br />`; keep mid-string breaks |
| `email_domain` | intermediate | split after `@` |
| `email_hash` / `email_hash_if_present` | intermediate | salted MD5 hex; empty when null/blank |

## File index

| Path | Role |
|------|------|
| `../../macros/normalize_text.sql` | Project macros (source of truth) |
| `models/_crm_contacts__sources.yml` | Placeholder CRM contacts source |
| `models/stg_crm_contacts.sql` | Staging with `preserve_linebreaks` on notes |
| `models/int_crm_contacts.sql` | Intermediate with `normalize_text` + email helpers |
| `models/schema.yml` | Grain tests + column docs |
| `BUSINESS_CASE.md` | Reliability / privacy rationale |
| `ARCHITECTURE.md` | Mermaid component diagram |
| `DATA_FLOW.md` | Staging → intermediate transform path |

## How to run (conceptually)

1. Drop `normalize_text.sql` under your project's `macros/`.
2. Set the salt in `dbt_project.yml` (or CI env → `vars`):

   ```yaml
   vars:
     email_hash_salt: "your-long-random-secret"
   ```

3. Point `_crm_contacts__sources.yml` at a real contacts table.
4. `dbt run --select stg_crm_contacts int_crm_contacts`
5. `dbt test --select stg_crm_contacts int_crm_contacts`

Do not commit a real salt to this portfolio repo.

## Sanitization notes

- GCP project / datasets → `your-gcp-project`, `raw_crm`, `staging`,
  `intermediate`.
- Source system renamed to generic `crm` contacts (not a company product name).
- Production MD5 salt removed; macros read `var('email_hash_salt')`.
- Raw first/last name / phone fields not reproduced; email only as hash + domain.
- Macro logic matches internal staging linebreak preservation + intermediate
  string normalize / email helpers, without legacy surrogate-key or job-metadata
  wrappers.

## Tradeoffs

**Pros:** one place to tighten text rules; staging and intermediate stay
symmetric; salt rotation is a var change, not a 40-file search.

**Cons:** `normalize_text` is regex-heavy — fine for contact notes, expensive if
you apply it to every wide string column on a multi-TB fact. MD5 is adequate
for stable join keys / analytics de-ID, not a password store; upgrade the hash
if your threat model needs it.
