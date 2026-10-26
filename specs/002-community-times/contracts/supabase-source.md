# Contract: Supabase community source

Everything the project's source exposes. This file is the contract; the implementation is `supabase/schema.sql`. The key is the project's public (anon) key, which ships in the app and is not a secret.

## Table `submissions` (private)

| Column | Type | Rule |
|---|---|---|
| `contribution_id` | uuid | Never returned by any function. |
| `film_id`, `developer_id` | text | `^[a-z0-9][a-z0-9-]{0,79}$` |
| `dilution` | text | the dilution pattern from `CombinationKey` |
| `ei` | int | 1–25600 |
| `temp_c` | int | 10–45 |
| `time_s` | int | 30–10800 |
| `updated_at` | timestamptz | server-set; used for `last_confirmed` |

Primary key: (`contribution_id`, `film_id`, `developer_id`, `dilution`, `ei`, `temp_c`). A repeat upserts `time_s`.

Row-level security is on with **no policies** for the public role, and **all table privileges are revoked** from `anon` and `authenticated`. The public key therefore cannot select, insert, update or delete rows directly (FR-021).

## Function `submit_time(contribution_id, film_id, developer_id, dilution, ei, temp_c, time_s)`

- `SECURITY DEFINER`, executable by `anon`.
- Rejects any value outside the ranges above with an error (the app treats any non-2xx as "retry later" and drops a 4xx as invalid).
- Upserts on the primary key, so a repeat replaces the earlier time.
- Refuses an ID that has made more than 200 submissions in the last 24 h.
- Returns nothing.

## Function `community_feed()`

- `SECURITY DEFINER`, executable by `anon`, read-only.
- For each combination, buckets times by `floor(ln(time_s) / ln(1.08))` (the single similarity window, FR-020).
- Returns only buckets with at least two distinct `contribution_id`s, as one JSON document matching [community-feed.schema.json](community-feed.schema.json): `time_s` is the bucket median, `installs` the distinct count, `last_confirmed` the newest `updated_at`.
- Never returns a contribution ID.

## Maintainer operations (FR-025)

Run in the Supabase SQL editor with the project owner's login:

- Remove one bad combination: `delete from submissions where film_id = '…' and developer_id = '…' and dilution = '…' and ei = … and temp_c = …;`
- Remove everything from one ID: `delete from submissions where contribution_id = '…';`

The next `community_feed()` call no longer includes them.

## Keep-alive

`.github/workflows/community-keepalive.yml` calls `community_feed()` weekly with the public key stored as a repository variable. A failed call shows as a failed workflow run.
