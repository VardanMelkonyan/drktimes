# Data Model: Community Times

## On-device (drift, schema version 1 → 2)

Community data is stored apart from datasheet data, recipes and sessions (FR-012). None of these tables is part of backup, the exchange format or the dataset.

### Settings row (existing `SettingsRows`, new columns)

| Column | Type | Notes |
|---|---|---|
| `share_times` | bool, default false | The "Share my times" switch (FR-001). |
| `contribution_id` | text, nullable | Random UUID v4, created the first time sharing is switched on, cleared by Reset (FR-007, FR-007a). Never backed up or exported. |
| `shared_up_to` | datetime, nullable | Finish time of the newest completed session already considered for backfill (R10). |

### `community_sources`

| Column | Type | Notes |
|---|---|---|
| `id` | text PK | UUID. The default project source has a fixed id. |
| `name` | text, 1–60 | Shown on every entry from this source (FR-011, FR-017). |
| `kind` | text | `static` or `supabase`. |
| `url` | text | Feed address, or project address. |
| `public_key` | text, nullable | Only for `supabase`. Public by design. |
| `share_to` | bool | Whether submissions go here (default true for the project source, false for others). Only meaningful for `supabase`. |
| `position` | int | Display order. |

### `community_entries` (cache)

| Column | Type | Notes |
|---|---|---|
| `source_id` | text FK → `community_sources` | |
| `key_canonical` | text | `CombinationKey.canonical` of the entry. |
| `time_s` | int | The bucket's displayed (median) time. |
| `installs` | int ≥ 2 | Distinct installs behind it (FR-019a). |
| `last_confirmed` | datetime | Used only to break preselection ties (FR-019b). |

Primary key: (`source_id`, `key_canonical`, `time_s`). Replaced as a whole set per source on each successful refresh. Removing a source deletes its rows. A `fetched_at` per source is held on the source row's cache metadata (`community_fetches`: `source_id`, `fetched_at`).

### `share_queue`

| Column | Type | Notes |
|---|---|---|
| `id` | text PK | UUID. |
| `source_id` | text FK | Which source this submission goes to. |
| `key_canonical` | text | |
| `time_s` | int | |
| `created_at` | datetime | |
| `attempts` | int | Retry bookkeeping; never sent. |

Unique on (`source_id`, `key_canonical`, `time_s`) so a combination and time is queued once (FR-003a). Cleared entirely when sharing is switched off (FR-008, spec edge case).

## Domain types (pure Dart)

- **Submission**: `filmId`, `developerId`, `dilution`, `ei`, `tempC`, `timeS`, plus the contribution ID added at send time. Exactly the FR-004 fields; a unit test asserts the serialised map has no other keys (SC-005).
- **CommunityEntry**: `CombinationKey`, `timeS`, `installs`, `lastConfirmed`, `sourceId`. Always `installs ≥ 2` once validated.
- **CommunitySource** (interface): `id`, `name`, `Future<CommunityFeed> fetchFeed()`, `bool canSubmit`, `Future<void> submit(Submission, String contributionId)`.
- **Preselect** gains a `community` branch after `receivedRecipe`. It never outranks `lastUsed`, `datasheet`, `ownRecipe` or `receivedRecipe` (FR-019b). The recorded `time_source` for a session started from one is `{kind: community, source_id}`.

## Server side (Supabase)

Described in [contracts/supabase-source.md](contracts/supabase-source.md): table `submissions` (private), functions `submit_time` and `community_feed`.

## State and lifecycle

- **Switch off → on**: create the contribution ID if absent; backfill eligible history into `share_queue` for each `share_to` source; flush when online.
- **Session completes (switch on)**: eligibility check; queue one row per `share_to` source; flush.
- **Switch on → off**: delete the whole queue. Nothing already sent is recalled.
- **Reset ID**: clear `contribution_id`. A new one is created at the next submission.
- **Refresh**: at most once per 24 h per source. Success replaces the source's cached rows. Failure keeps the old ones, silently.
