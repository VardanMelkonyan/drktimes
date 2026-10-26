# Research: Community Times

All decisions here resolve the unknowns left by the spec ("left for planning": similarity window, payload, insert-only enforcement, keep-alive, moderation). Facts about Supabase and GitHub limits are from memory and **must be re-checked against the current docs at implementation time** (task T-first).

## R1. Backend

- **Decision**: Supabase free-tier Postgres, called through its REST interface with plain `http`. The public (anon) key has no table privileges. It may only execute two functions.
- **Rationale**: the owner approved Supabase and wants no server of their own. SQL gives the confirmation count in one grouped query. No SDK keeps the dependency list unchanged and the calls auditable.
- **Alternatives considered**: Firebase (no pause on idle, but daily read/write caps and no aggregation without paid functions); a Cloudflare Worker relay (rejected by the owner in favour of Supabase); GitHub issues (needs accounts).

## R2. Insert-only access that still lets a repeat replace the earlier one

- **Problem**: FR-021 says the public key cannot change or delete entries, yet FR-007 says a repeat from the same install replaces its earlier time. A plain "insert only" row rule cannot do both.
- **Decision**: no table privilege for the public key. `submit_time(...)` is a `SECURITY DEFINER` function that validates the fields and does an upsert on (contribution ID, combination). The key can call only that function, so it can touch only a row whose contribution ID it already knows.
- **Rationale**: the ID is a random version-4 UUID that is never returned by any read, so nobody can overwrite another install's row.
- **Alternatives**: separate insert rows with "latest wins" (grows without bound, harder to count); letting the key update rows (breaks FR-021).

## R3. Similarity window and the bucketing rule

- **Decision**: group times for one combination into buckets of equal ratio, `floor(ln(time_s) / ln(1.08))`. A bucket's displayed time is the median of its members. A bucket is returned only when it has **two or more distinct contribution IDs**. The ratio 1.08 is a constant defined once in `submit_time`/`community_feed` (FR-020) and mirrored in the contract and in a Dart constant used only for tests.
- **Rationale**: about ±4 % around the displayed time (a 10:00 time and a 10:20 time agree; 10:00 and 12:00 do not). It is deterministic, set-based and cheap in SQL.
- **Known limit (shortcut)**: two similar times that fall on either side of a bucket edge do not confirm each other until a third one lands in one bucket. Upgrade when real data shows split pairs: switch to a gap-based clustering in a scheduled job.
- **Alternatives**: percentage of the median with chaining (clusters can drift, needs recursion); fixed seconds (unfair at long and short times).
- **Open to tune**: 1.08 is a first guess, to be checked against the first real submissions, not against any copied compilation (constitution Principle I).

## R4. Reading

- **Decision**: `community_feed()` returns the whole visible feed as one JSON document in the shape of `contracts/community-feed.schema.json`. The app caches it per source and refreshes it at most once per 24 h.
- **Rationale**: one request, offline-friendly, identical to a static source so the two share a parser.
- **Known limit**: payload grows with the data. Upgrade path: a scheduled GitHub Action writes the same JSON to static hosting and the default source becomes a `StaticFeedSource` for reading, keeping `submit_time` for writing. No app change beyond the source config.

## R5. Validation of what the app shows (FR-016)

- **Decision**: the feed passes the JSON schema, then each entry is checked against the app's catalog: film and developer ids must exist, dilution must match the dilution pattern, ISO 1–25600, temperature 10–45 °C, time within limits, `installs` ≥ 2. Failing entries are dropped, not repaired. Entries for catalog ids the app does not know yet stay in the cache and appear after a dataset update.
- **Rationale**: the server cannot know the catalog, so the client is the only place that can reject junk ids. It reuses `CombinationKey`'s own range checks.

## R6. Plausible-value limits

- **Decision**: time 30–10,800 s, temperature 10–45 °C (already in `CombinationKey`), ISO 1–25,600 (same). Enforced on the device before queueing (FR-009) and again, identically, by the server function.
- **Rationale**: covers stand development up to 3 hours; rejects typos like 0 or 99,999.

## R7. Abuse and moderation

- **Decision**: per-ID cap of 200 submissions per day inside `submit_time`; maintainer removal by a documented SQL statement run in the Supabase dashboard (FR-025), described in `contracts/supabase-source.md`.
- **Known limit**: nothing stops one person generating many IDs to fake two installs. Accepted for launch; the mitigation is that a fake entry needs another install to land within ±4 %, and the maintainer can delete it. Upgrade when abuse is seen: per-IP limit from the request headers, or minimum age on entries.

## R8. Keep-alive

- **Decision**: a weekly scheduled GitHub Action calls `community_feed` with the public key.
- **Re-checked 2026-10-25 (T002)**: Supabase docs say free projects with low activity over a 7-day period are paused (a few user requests a day keep one alive; 90 days to restore). One weekly ping is borderline, so the workflow runs **daily**. GitHub still disables scheduled workflows in public repos after 60 days without repository activity.
- **Known limit**: GitHub disables scheduled workflows after about 60 days without repository activity, and Supabase pauses a free project after about a week without traffic. The workflow will keep running while the repo gets commits; add a calendar reminder otherwise. The app's own refresh traffic also counts as activity.

## R9. Contribution ID

- **Decision**: UUID v4 from the existing `uuid` package, generated the first time sharing is switched on, stored in the settings row, never in backups, never in exports, never shown except as "Reset". Resetting deletes it; the next submission generates a new one (FR-007a).
- **Rationale**: random, derived from nothing about the user or device (FR-007).

## R10. Backfill

- **Decision**: when the switch goes on, a one-off scan of completed sessions finds eligible ones and queues them (deduplicated by combination and time). `shared_up_to` records the finish time of the newest session already handled so a later off/on does not re-scan more than needed. Repeat submissions are harmless because the server replaces.
- **Rationale**: matches clarification: past sessions are included, once per combination and time.

## R11. Eligibility from existing data

- **Decision**: a session qualifies when `status = completed`, its `time_source.kind = recipe`, the recipe it names exists with `ownership = own`, the session's key has catalog film and developer refs, and the time passes plausibility. The submitted time is the session's recorded `devTimeS`, not the recipe's current time, so edits made after the run do not change what was used.
- **Rationale**: reuses existing columns and `recipeSource`. A manual start (`kind = manual`) is not submitted: nothing says whose time it was.

## R12. Privacy review items (not decisions)

- The Apple privacy answers for an opt-in random ID plus IP-level exposure to the source host may change the "Data Not Collected" label. Decide at the release gate (FR-024), do not assume.
- Add the consent text and what is sent to the in-app privacy text. Wording to be reviewed by the owner.
