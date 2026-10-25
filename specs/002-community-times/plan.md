# Implementation Plan: Community Times (user-submitted dataset)

**Branch**: no feature branch. Spec-kit resolves the feature as `002-community-times` from `.specify/feature.json`. Git is on `devdata-dataset`.
**Date**: 2026-10-25
**Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-community-times/spec.md` (4 clarifications, session 2026-10-25).

## Summary

An opt-in **Share my times** switch sends the times a user actually developed with, anonymously and automatically, to a community source. Everyone then sees those times, labelled as community times with an install count, but only once two or more installs agree.

**Technical approach:**

- **One small interface, two source types.** The app talks to every source through `CommunitySource`. A `StaticFeedSource` reads a JSON file (read-only). A `SupabaseSource` reads the same JSON shape from a database function and also accepts submissions. Adding a third kind later touches only the data layer.
- **All the rules that can be pure Dart are pure Dart.** Eligibility (what may be submitted), the submission payload, queueing, feed validation, merging for display and preselection live in `lib/domain/community/`, with unit tests on Linux.
- **Supabase is reached with plain HTTP.** No Supabase SDK. The `http` package is already a dependency. The public key can only call two database functions; it has no table access.
- **Confirmation is computed on the server, in one place.** The database function groups times for a combination into buckets of similar times and returns only buckets with two or more distinct installs. That is the only way a lone submission can stay hidden from every reader (FR-019a).
- **Community data is stored apart.** New local tables for the source list, the cached feed and the send queue. Nothing touches `resources/devdata`, recipes, or the exchange format.

## Technical Context

**Language/Version**: Dart 3.13.3, Flutter 3.47.4 stable (existing project). No Kotlin or Swift changes.

**Primary Dependencies**: no new packages. Uses existing `http`, `drift`, `flutter_riverpod`, `go_router`, `uuid` (contribution ID, version 4), `json_schema` (dev, feed schema tests).

**Backend (project source)**: Supabase free-tier Postgres. Tables are private. Two functions are exposed to the public key (`submit_time`, `community_feed`). SQL lives in `supabase/` and is exercised in CI against a throwaway Postgres container.

**Storage**: drift schema version 1 → 2 (adds `community_sources`, `community_entries`, `share_queue`; adds `share_times`, `contribution_id`, `shared_up_to` columns to the settings row). Details in [data-model.md](data-model.md).

**Testing**: `flutter test` (pure-Dart domain tests, drift in-memory repository tests, fake `CommunitySource`, feed schema test). SQL tests with `psql` in CI. Device-only checks are in [quickstart.md](quickstart.md).

**Target Platform**: iOS (first release) and Android, as in the constitution.

**Project Type**: mobile app (Flutter). Plus a small `supabase/` folder and one GitHub Actions workflow.

**Performance Goals**: a feed refresh never blocks a session or a lookup. Reads come from the on-device cache; the network only refreshes it.

**Constraints**: offline-capable; zero recurring cost (free tier); no personal data; the payload equals the FR-004 fields exactly.

**Scale/Scope**: designed for hundreds to low thousands of installs. Whole-feed download is accepted at this size (see research.md R4). The `CommunitySource` interface is the exit if it outgrows that.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Licence-clean data | **Pass** | Community entries are stored in their own tables, shown in their own labelled group, never written to `resources/devdata`, and never counted by the dataset validator or gate. Only the user's own recipes are submitted (FR-005), so no received or datasheet content is re-released. Feed entries pass a validator before display (FR-016). |
| II. Privacy by default | **Exception, needs amendment** | Principle II forbids identifiers in network requests and lists the manifest check as the only request. This feature adds a read request and a submission request, and one device-only random contribution ID (owner decision A). Sharing is off by default and consented in plain text. See Complexity Tracking, rows 1 and 2. |
| III. Darkroom-first | **Pass** | No session UI changes. The community label is text plus grouping, never hue alone. |
| IV. Timing derived | **Pass / not affected** | No timing changes. Submissions use the session's recorded `devTimeS`. |
| V. Testable core | **Pass** | Eligibility, payload, queue logic, feed validation, merge and preselection are pure Dart. The HTTP clients sit behind `CommunitySource` with test fakes. The only SQL rule (bucketing) has CI tests. Device-only behaviour has manual checks in the quickstart. |
| VI. Open, store-safe, simple | **Exception, justified** | "No server, accounts or paid third-party service unless a spec justifies it." Spec section "Constitution impact" justifies one free hosted database. No accounts, no paid service. See Complexity Tracking, row 3. |
| Hosting: static only | **Exception, justified** | The default source is not static. The static feed type is supported, and a scheduled export from the database to static hosting is the documented scale-out path. Row 3. |
| Costs | **Pass** | Free tier, no recurring spend. The pause risk is mitigated by the weekly keep-alive (FR-022). |
| CI gates | **Pass** | Adds one CI job (SQL tests). `flutter analyze`, `flutter test` and the dataset validator stay as they are. |

**Gate result**: passes **with three recorded exceptions**, as the constitution allows ("or record a justified exception"). The constitution amendment (Principle II, spec 001 FR-072, Principle VI wording) must be committed by the owner **before tasks are generated**. This plan does not edit the constitution.

## Network requests (FR-023)

Every request this feature adds. None is made while the app has no source configured.

| # | When | Request | Sent | Not sent |
|---|---|---|---|---|
| 1 | At most once per 24 h, when the app opens, and when a combination page is opened if the cache is older than 24 h; per configured source | `GET <feed url>` for a static feed, or `POST <project>/rest/v1/rpc/community_feed` with an empty body for a Supabase source | the public key header (Supabase only) | contribution ID, any user data |
| 2 | After a session completes with sharing on; once for each backfill item when sharing is switched on; retried while the queue is non-empty | `POST <project>/rest/v1/rpc/submit_time` | FR-004 fields (catalog film id, catalog developer id, dilution, ISO, temperature in whole °C, time in seconds) and the contribution ID | name, notes, device model, locale, app version, any timestamp |
| 3 | Weekly (not the app) | GitHub Actions calls `community_feed` | the public key | n/a |

The network itself reveals the device's IP address to the source host. This is inherent to any request and goes in the release privacy review (FR-024).

## Project Structure

### Documentation (this feature)

```text
specs/002-community-times/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── community-feed.schema.json   # the feed shape both source types return
│   └── supabase-source.md           # tables, functions, grants, limits
├── checklists/requirements.md
└── tasks.md                         # /speckit-tasks, not created here
```

### Source Code (repository root)

```text
lib/
├── domain/community/
│   ├── submission.dart        # Submission payload (exactly the FR-004 fields) + plausibility
│   ├── eligibility.dart       # session + recipe + catalog → Submission? (FR-005, FR-006, FR-009)
│   ├── share_queue.dart       # dedupe, ordering, retry bookkeeping (pure)
│   ├── community_feed.dart    # feed model + validation against the catalog (FR-016)
│   └── community_merge.dart   # per-source grouping, preselection candidate (FR-017, FR-019b)
├── domain/preselect.dart      # extended: `community` branch as last fallback
├── data/community/
│   ├── community_source.dart       # interface: fetchFeed(), submit() ; capabilities
│   ├── static_feed_source.dart     # GET + parse
│   ├── supabase_source.dart        # RPC calls over http
│   ├── community_repository.dart   # sources, cache, queue, backfill (drift)
│   └── community_sync.dart         # refresh scheduler + queue flush, silent on failure
├── data/db/database.dart      # schema v2 + migration
├── data/repositories/settings_repository.dart   # shareTimes, contributionId, sharedUpTo
├── features/settings/         # Share my times row, Reset ID, link to sources
├── features/community_sources/  # list / add / remove, per-source "share to" toggle
└── features/combination/      # "Community" group under datasheet times
supabase/
├── schema.sql                 # tables, grants, RLS, functions (see contracts/supabase-source.md)
└── tests/                     # psql tests: bucketing, hiding, replace, caps
.github/workflows/
├── ci.yml                     # + `sql` job (postgres service container)
└── community-keepalive.yml    # weekly read-only ping
test/
├── domain/community/
├── data/community/
└── features/settings/ (+ combination)
```

**Structure Decision**: extend the existing `lib/{domain,data,features}` layout. The pure rules sit in `domain`, the sources and storage in `data`, screens in `features`. The `supabase/` folder holds the only server-side artefact so it is reviewable in the same repository.

## Complexity Tracking

| Exception | Why needed | Simpler alternative rejected because |
|---|---|---|
| 1. Principle II: a device-only contribution ID is sent with submissions (owner decision, spec clarification A) | Without it the pool cannot count each install once or let a repeat submission replace the earlier one (FR-007). | No ID plus a local "sent" record lets a reinstall inflate counts; no automatic confirmation removes the trust signal the owner wants. Both rejected by the owner. |
| 2. Principle II / spec 001 FR-072: new requests beyond the manifest check | Sharing and reading community times need a read and a submit request. | A read-only static feed would work without any submission request, but then nothing could be contributed without a GitHub account, which the owner ruled out. |
| 3. Principle VI and "static only" hosting: one free hosted database | A static host cannot receive writes. A write-only public key on a free database is the lightest option that needs no accounts and no server of the owner's own. | GitHub issues need user accounts. A token embedded in the app is extractable. A self-run server breaks "no server". Firebase was weighed against Supabase: it lacks the one-line aggregation the confirmation rule needs and its free tier is capped per day (research R1). |
