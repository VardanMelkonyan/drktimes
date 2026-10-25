---

description: "Task list for Community Times (user-submitted dataset)"
---

# Tasks: Community Times (user-submitted dataset)

**Input**: Design documents from `/specs/002-community-times/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included. The constitution (Principle V) requires logic changes to ship with tests that fail without them.

**Organization**: Grouped by user story. Paths follow the existing `lib/{domain,data,features}` layout.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: US1 share, US2 see, US3 confirmation, US4 sources, US5 keep-alive

## Phase 1: Setup

**Purpose**: governance and scaffolding.

- [X] T001 OWNER: amend `.specify/memory/constitution.md` in one commit with a Sync Impact Report and a version bump: Principle II (allow the device-only random contribution ID, list the community read and submit requests), Principle VI and the "Hosting: static only" line (one free hosted database, justified in `specs/002-community-times/spec.md`), and `specs/001-film-develop-timer/spec.md` FR-072 (list the new requests). Plan's Constitution Check does not pass until this is done.
- [X] T002 Re-verify the Supabase free-tier limits (idle pause, request caps, anon-key RPC behaviour) and GitHub's scheduled-workflow inactivity rule against current docs; correct `specs/002-community-times/research.md` R1 and R8 where they differ.
- [X] T003 [P] Create empty directories and a placeholder README for `supabase/` and `supabase/tests/`, and `lib/domain/community/`, `lib/data/community/`, `lib/features/community_sources/`.

---

## Phase 2: Foundational (blocks every story)

**Purpose**: storage, the source interface, and the server schema that every story relies on.

- [X] T004 Add drift schema v2 in `lib/data/db/database.dart` per `data-model.md`: tables `community_sources` (`name` 1–60 characters, `kind` in `static`/`supabase`), `community_entries` (`installs` ≥ 2, primary key `source_id`+`key_canonical`+`time_s`), `community_fetches`, `share_queue` (unique `source_id`+`key_canonical`+`time_s`); settings columns `share_times` (default false), `contribution_id` (nullable), `shared_up_to` (nullable). Bump `schemaVersion` to 2 with an `onUpgrade` step from 1, and regenerate `database.g.dart` (`dart run build_runner build --delete-conflicting-outputs`).
- [X] T005 Extend `lib/data/repositories/settings_repository.dart` (`Settings`, `get`, `update`) with `shareTimes`, `contributionId`, `sharedUpTo`. Keep `restore` and the backup path ignoring all three (they are never backed up or exported).
- [X] T006 [P] Write the migration test in `test/data/db/community_migration_test.dart`: a v1 database upgrades to v2 with existing sessions, recipes and settings intact, and the new settings default to off/null.
- [X] T007 [P] Define `Submission` in `lib/domain/community/submission.dart`: exactly `filmId`, `developerId`, `dilution`, `ei`, `tempC`, `timeS`; plausibility check `timeS` 30–10800 plus the existing `CombinationKey` ranges; `toJson` emits only the FR-004 fields (the contribution ID is added by the source at send time). Test in `test/domain/community/submission_test.dart`, including that the map has no other keys (SC-005).
- [X] T008 [P] Define `CommunityFeed`, `CommunityEntry` and validation in `lib/domain/community/community_feed.dart`: parse per `contracts/community-feed.schema.json`, drop entries that fail the dilution pattern, ISO 1–25600, temperature 10–45, time 30–10800, `installs` ≥ 2, or whose film or developer id is not in the supplied catalog id sets; ignore unknown fields. Test in `test/domain/community/community_feed_test.dart` using `json_schema` against the contract file.
- [X] T009 Define the `CommunitySource` interface in `lib/data/community/community_source.dart`: `id`, `name`, `fetchFeed()`, `canSubmit`, `submit(Submission, String contributionId)`. Add a fake in `test/data/community/fake_community_source.dart`.
- [X] T010 [P] Write `supabase/schema.sql` per `contracts/supabase-source.md`: private `submissions` table with its CHECKs and primary key, all table privileges revoked from `anon`/`authenticated`, row-level security on with no policies, `submit_time(...)` (`SECURITY DEFINER`, range checks, upsert, 200/day cap per ID) and `community_feed()` (bucket `floor(ln(time_s)/ln(1.08))`, at least two distinct IDs, median time, JSON per the feed schema). The 1.08 ratio is a single named constant.
- [X] T011 Add the `sql` job to `.github/workflows/ci.yml`: a Postgres 15 service container, then `psql -v ON_ERROR_STOP=1 -f supabase/schema.sql -f supabase/tests/run.sql`.
- [X] T012 Create `lib/data/community/community_repository.dart` over the new tables: list/add/remove sources (removing deletes the source's cached entries and queue rows), replace a source's cached entries atomically, read cached entries for a combination key, queue/dequeue/clear, and read/write `community_fetches`. Test in `test/data/repositories/community_repository_test.dart` with an in-memory database.
- [X] T013 Seed the default project source (fixed id, name, `supabase` kind, url and public key as build-time constants in `lib/data/community/default_source.dart`) on first run of schema v2. The key is filled in when the Supabase project exists; until then the default source is absent and the app is purely standalone.

**Checkpoint**: storage migrates, feed parsing and the server schema exist; nothing is user-visible yet.

---

## Phase 3: User Story 1 - Share my times without effort (P1) 🎯 MVP

**Goal**: with the switch on, eligible times are sent automatically; with it off, nothing is sent.

**Independent Test**: with a fake source, turn the switch on, complete a session on an own recipe, and assert exactly one submission with only the FR-004 fields; with the switch off, assert zero calls.

### Tests for User Story 1

- [X] T014 [P] [US1] Eligibility tests in `test/domain/community/eligibility_test.dart`: accepted only for completed session + `time_source.kind = recipe` + recipe `ownership = own` + catalog film and developer refs + plausible time (FR-005, FR-006, FR-009); rejected for aborted, manual, datasheet, received-recipe, user-added film or developer, and implausible time. The submitted time is the session's `devTimeS`, not the recipe's current time.
- [X] T015 [P] [US1] Queue tests in `test/domain/community/share_queue_test.dart`: dedupe by combination and time, discard on switch-off, retry ordering (FR-003a, FR-008).
- [X] T016 [P] [US1] Sync tests in `test/data/community/community_sync_test.dart` with the fake source: switch off makes zero submit calls (SC-002); switch on queues and sends; offline failure keeps the queue and a later flush sends it (SC-007); backfill on switch-on sends each eligible past session once per combination and time; the contribution ID is created on first use and reused; Reset clears it and the next submission gets a new one (FR-007, FR-007a).

### Implementation for User Story 1

- [X] T017 [P] [US1] Implement `eligibility.dart` in `lib/domain/community/eligibility.dart` (session row + recipe + catalog id sets → `Submission?`).
- [X] T018 [P] [US1] Implement queue logic in `lib/domain/community/share_queue.dart` (pure; the repository from T012 persists it).
- [X] T019 [US1] Implement `SupabaseSource.submit` in `lib/data/community/supabase_source.dart`: `POST <url>/rest/v1/rpc/submit_time` with the `apikey` header and the Submission fields plus the contribution ID using `package:http`. Treat 2xx as sent, 4xx as invalid (drop), anything else as retry. No other fields, headers or identifiers.
- [X] T020 [US1] Implement `lib/data/community/community_sync.dart`: `onSessionCompleted(sessionId)`, `onShareSwitchedOn()` (create the contribution ID if absent, backfill from completed sessions newer than `shared_up_to`, queue per `share_to` source), `onShareSwitchedOff()` (clear the queue), `flush()` (silent on failure). Wire it in `lib/app/providers.dart` as a Riverpod provider.
- [X] T021 [US1] Call `onSessionCompleted` from the session completion path in `lib/features/session/session_controller.dart` after the session row is saved as completed; it must not delay or fail the Done screen.
- [X] T022 [US1] Add the **Share my times** switch and **Reset contribution ID** row to `lib/features/settings/settings_screen.dart`. Consent text per FR-001 and US1 scenario 2 (CC0, anonymous, includes eligible past sessions, can be turned off, already-shared times cannot be recalled). Off by default. Widget test in `test/features/settings/settings_screen_test.dart`.

**Checkpoint**: US1 works end to end against the fake source. MVP of the contribution side.

---

## Phase 4: User Story 2 - See and trust community times (P1)

**Goal**: community times appear, labelled and counted, under datasheet times; Start can preselect the best-backed one as a last fallback.

**Independent Test**: seed a source's cache with entries and open the combination page; entries show label, source name and count, datasheet first.

### Tests for User Story 2

- [X] T023 [P] [US2] Merge/display tests in `test/domain/community/community_merge_test.dart`: grouped per source and never merged across sources (FR-017); each entry keeps source name and `installs`; entries with `installs` < 2 are never exposed (FR-019a).
- [X] T024 [P] [US2] Extend `test/domain/preselect_test.dart`: the new `community` branch is chosen only when there is no last-used time, no datasheet time, no own recipe and no received recipe; picks the highest `installs`, ties broken by newest `last_confirmed` (FR-019b).
- [X] T025 [P] [US2] Widget test in `test/features/combination/combination_screen_test.dart`: datasheet group first, then a "Community" group; the label is text plus grouping, not colour alone; a community time can be saved as an own recipe (US2 scenario 5) and that recipe is not re-shared unless it later completes a session (FR-005).

### Implementation for User Story 2

- [X] T026 [P] [US2] Implement `lib/domain/community/community_merge.dart` (entries for a `CombinationKey`, grouped by source, ordered by `installs` then `last_confirmed`).
- [X] T027 [US2] Extend `lib/domain/preselect.dart` with `PreselectBranch.community` as the last fallback and a `community_source` time-source map `{kind: community, source_id}`; update every `switch` over the enum that the analyzer flags.
- [X] T028 [US2] Implement `StaticFeedSource` in `lib/data/community/static_feed_source.dart` (GET, parse with T008 validation, never throws) and `SupabaseSource.fetchFeed` in `supabase_source.dart` (`POST <url>/rest/v1/rpc/community_feed`, same parser).
- [X] T029 [US2] Add the refresh scheduler to `community_sync.dart`: refresh each source at most once per 24 h, on app open and when a combination page is opened with a stale cache; success replaces the cache, failure keeps it; never blocks a session or a lookup (FR-018). Test in `test/data/community/community_sync_test.dart`.
- [X] T030 [US2] Show the community group in `lib/features/combination/combination_screen.dart` below datasheet times: "Community" label, source name, "N installs" (N ≥ 2), selectable for Start; wire the preselect from T027. Make sure Recent, the summary screen and any exchange or backup code tolerate `time_source.kind = community` (grep `time_source` in `lib/domain/summary.dart`, `lib/domain/exchange/codec.dart`, `lib/data/repositories/backup_service.dart`) and show the source label.
- [X] T031 [US2] Add a dataset-gate regression test in `test/devdata/dataset_test.dart` (or a new file beside it) asserting `resources/devdata` and `assets/devdata.json` are untouched by the community feature: no community code path writes to them (SC-009).

**Checkpoint**: US1 + US2 together deliver the full loop against a fake or real source.

---

## Phase 5: User Story 3 - Automatic confirmation (P2)

**Goal**: the server counts independent installs, counts each install once, and keeps lone submissions hidden.

**Independent Test**: run the SQL tests against a throwaway Postgres.

- [X] T032 [P] [US3] Write `supabase/tests/run.sql` covering: the `anon` role cannot select, insert, update or delete `submissions` directly (FR-021); a lone submission is absent from `community_feed()` (US3 scenario 4); two distinct IDs within the window appear with `installs = 2` and a median `time_s`; a repeat from one ID replaces the earlier time and changes no count (SC-006); a far-off time forms its own hidden bucket (US3 scenario 3); out-of-range values and the 201st submission in 24 h from one ID are rejected; the feed never contains a contribution ID.
- [X] T033 [US3] Fix whatever T032 exposes in `supabase/schema.sql`, and document the bucket-edge limitation in a comment on the bucketing line: `shortcut: bucket edges split near-equal times, switch to gap clustering when real data shows it`.
- [X] T034 [P] [US3] Add a Dart mirror constant test `test/domain/community/similarity_window_test.dart` asserting the documented ratio (1.08) matches the value in `supabase/schema.sql` (read the file in the test), so FR-020's "defined once" cannot drift silently.

**Checkpoint**: confirmation behaviour is proven in CI.

---

## Phase 6: User Story 4 - Add or remove sources (P2)

**Goal**: users manage sources; entries stay labelled by source; the app still works with none.

**Independent Test**: add a static feed, see its entries under its name, remove it, see them gone; remove all sources and run the US1 of spec 001 unchanged.

- [X] T035 [P] [US4] Repository/sync tests in `test/data/community/community_sources_test.dart`: add and remove a source; removal deletes its cache and queue; a malformed or unreachable source keeps old cache and shows no error (US4 scenario 4); with no sources, no network call is made (FR-015).
- [X] T036 [US4] Build `lib/features/community_sources/community_sources_screen.dart`: list, add by address (a feed URL, or a Supabase project URL plus public key), name, remove, and the per-source "share to" toggle for submit-capable sources. Link it from `settings_screen.dart` and register the route in `lib/app/router.dart`. Widget test in `test/features/settings/community_sources_screen_test.dart`.
- [X] T037 [US4] Validate a new source before saving: reachable, returns a document passing the feed schema; otherwise show a one-line reason and do not save. The default project source can be removed (FR-014).

**Checkpoint**: sources are configurable; the standalone case is tested.

---

## Phase 7: User Story 5 - Keep the source alive (P3)

- [X] T038 [US5] Add `.github/workflows/community-keepalive.yml`: weekly `schedule` plus `workflow_dispatch`, one `curl -fsS` POST to `community_feed` using repository variables for the project URL and public key; a failed call fails the run.
- [X] T039 [US5] Document the 60-day scheduled-workflow inactivity rule and the manual re-enable step in `supabase/README.md`, next to the moderation SQL from `contracts/supabase-source.md` (FR-025).

---

## Phase 8: Polish & Cross-Cutting

- [X] T040 [P] Write the in-app privacy text for sharing and reading, and list both requests in the app's privacy documentation under `site/` or `docs/` wherever spec 001 documented the manifest check.
- [ ] T041 Release gate: review the Apple App Store privacy answers and the Play Data safety form for the opt-in ID and IP exposure (FR-024); record the decision in `specs/002-community-times/research.md` R12.
- [X] T042 Run `flutter analyze`, `flutter test`, `dart run tool/validate_devdata.dart`, and the SQL tests; fix everything.
- [ ] T043 Run the manual checks in `specs/002-community-times/quickstart.md` on an Android device, then on iOS via TestFlight; record results at the foot of that file.

---

## Dependencies & Execution Order

- **Phase 1** first. T001 (the amendment) blocks starting implementation in practice, since the plan's gate fails without it.
- **Phase 2** blocks every story. Inside it: T004 → T005, T006, T012; T007, T008, T010 are independent; T009 needs T007 and T008; T011 needs T010; T013 needs T012.
- **US1 (Phase 3)** needs Phase 2. **US2 (Phase 4)** needs Phase 2 and can proceed in parallel with US1; it shares `community_sync.dart` (T020, T029), so those two edits are sequential.
- **US3 (Phase 5)** needs only T010 and T011, so it can start right after the schema exists and run alongside US1 and US2.
- **US4 (Phase 6)** needs US2's sync and cache (T029). **US5 (Phase 7)** needs only the deployed project.
- **Polish** last.

### Parallel Opportunities

- Phase 2: T006, T007, T008, T010 together.
- US1 tests T014, T015, T016 together; T017 and T018 together.
- US2 tests T023, T024, T025 together.
- US3 can run in a separate session from US1/US2 from the moment T010 is done.

## Implementation Strategy

### MVP First

1. Phase 1 (T001 especially) and Phase 2.
2. US1: contribution side, proven against the fake source.
3. US2 and US3 together: now the loop is real, with the SQL tests proving the confirmation rule.
4. **Stop and validate** against a real Supabase project using the quickstart checks 1–9.

### Incremental Delivery

US4 (sources screen) and US5 (keep-alive) add on without changing earlier behaviour. The default project source stays absent until T013's key exists, so shipping earlier code never makes a network request.

## Notes

- Each task names the files it touches; none changes `resources/devdata`.
- Commit after each task or logical group; do not rewrite history on shared branches.
- Network requests are exactly the three in `plan.md`. Do not add others.
