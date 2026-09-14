# Business case — text-clean / email normalize macros

## Problem

Free-text and email columns are the quiet failure mode in CRM pipelines:

- Support notes land with mixed `\r\n` / `\n` / padded `<br />` from UI export
- Downstream joins on "cleaned" status codes fail because one model trimmed
  and another did not
- Analysts ask for email domain rollups while security forbids raw addresses
  in intermediate / marts
- Hardcoded MD5 salts in macros leak through every PR and every laptop clone

Teams that inline the transforms end up with three slightly different
`regexp_replace` stacks and an email hash that cannot be rotated without a
warehouse rewrite.

## Decision

Ship a small macro family and a two-model teaching path:

1. **`preserve_linebreaks`** in staging — keep notes human-readable for ops
   tools that expect HTML breaks.
2. **`normalize_text`** in intermediate — strip control newlines and edge
   `<br />` while leaving intentional mid-string breaks alone.
3. **`email_hash_if_present` + `email_domain`** — publish hash + domain only;
   salt comes from `var('email_hash_salt')`.

## Business impact

- **Join reliability:** status / title / note comparisons stop depending on
  which model author remembered to trim export artifacts.
- **Privacy posture:** raw email never appears in the intermediate select list;
  domain-level reporting still works.
- **Secret hygiene:** rotating the salt is a CI var update. Committing a
  production salt into git is treated as an incident, not a style nit.
- **Cost:** applying normalize only on the columns that need it keeps slot
  usage predictable; blanket application on wide facts is the anti-pattern.

## When not to use this

- Binary / JSON payloads — use typed parsers, not string scrubbers.
- Already-clean API feeds with no linebreak artifacts — skip the staging
  preserve step; keep hash/domain if privacy still requires it.
- Regulatory hashing that mandates a specific KDF — swap the body of
  `email_hash`, keep the call sites.
