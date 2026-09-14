# Data flow — text-clean / normalize

## Build path

1. Land contacts in `raw_crm.contacts` (or your equivalent).
2. `stg_crm_contacts`
   - cast keys / timestamps
   - `lower(trim(email))`
   - `preserve_linebreaks(note)` → CR/LF become `<br />`
3. `int_crm_contacts`
   - `normalize_text` on `status` and `note`
   - `email_hash_if_present(email)` + `email_domain(email)`
   - raw `email` column is not selected
4. Downstream marts / joins consume `contact_id`, `email_hashed`,
   `email_domain`, cleaned `note`.

## Grain

| Model | Grain | Uniqueness |
|-------|-------|------------|
| `stg_crm_contacts` | one row per `contact_id` | unique + not_null on `contact_id` |
| `int_crm_contacts` | one row per `contact_id` | unique + not_null on `contact_id` |

## Transform table

| Input symptom | Staging (`preserve_linebreaks`) | Intermediate (`normalize_text`) |
|---------------|----------------------------------|----------------------------------|
| `hello\r\nworld` | `hello<br />world` | `helloworld` if no br left; mid-br kept if present |
| `<br />hello<br />` | unchanged (already br) | `hello` |
| `hello<br />world` | unchanged | `hello<br />world` (mid kept) |
| email `NULL` / `''` | empty string after cast/trim | `email_hashed=''`, `email_domain=''` |
| email `A@Example.com` | `a@example.com` | hash(salt + `a@example.com`), domain `example.com` |

## Failure modes to watch

| Symptom | Likely cause |
|---------|----------------|
| All hashes identical across environments | Forgot to set `email_hash_salt` per env; still on default placeholder |
| Joins on note / status miss rows | One side still has edge `<br />` or CR/LF — apply `normalize_text` on both |
| Raw email appears in intermediate | Select list still includes `email`; drop it and keep hash/domain only |
| Slot time spikes on a wide table | Applied `normalize_text` to every string column; scope to free-text fields |

## Placeholder mapping

| Concept | Portfolio name |
|---------|----------------|
| GCP project | `your-gcp-project` |
| Landing dataset | `raw_crm` |
| Staging / intermediate | `staging` / `intermediate` |
| Source system | CRM contacts |
| Hash salt | `var('email_hash_salt')` — never commit real value |
