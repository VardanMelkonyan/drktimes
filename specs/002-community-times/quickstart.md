# Quickstart: validating Community Times

## Prerequisites

- `flutter pub get`; `dart run build_runner build --delete-conflicting-outputs`
- Docker (or a local Postgres 15+) for the SQL tests
- For the device checks: an Android device or emulator; iOS via TestFlight for the iOS row

## Automated (Linux, no network)

1. `flutter analyze` is clean.
2. `flutter test test/domain/community test/data/community test/features/settings test/features/combination` passes. These cover, with fakes:
   - eligibility: completed + own recipe + catalog ids only; manual, datasheet, received and aborted sessions are rejected (FR-005, FR-006)
   - the serialised submission has exactly the FR-004 fields plus the ID (SC-005)
   - the queue: dedupe, discard on switch-off, retry after failure (FR-008, SC-007)
   - feed validation: bad ids, ranges and `installs < 2` are dropped (FR-016, FR-019a)
   - per-source separation and labelling (FR-011, FR-017)
   - preselection never outranks datasheet, last-used or recipes (FR-019b)
   - with sharing off, no `CommunitySource.submit` call is made (SC-002)
   - the dataset gate is unchanged with community data present (SC-009)
3. `dart run tool/validate_devdata.dart` passes.
4. SQL tests (CI `sql` job; locally against a throwaway Postgres): `psql -f supabase/schema.sql -f supabase/tests/run.sql` exits 0. They prove:
   - the public role cannot read or write the table
   - a lone submission is absent from `community_feed()`
   - two distinct IDs within the window appear with `installs = 2`
   - a repeat from one ID changes nothing (SC-006)
   - out-of-range values and the 200/day cap are rejected

## Manual, on a device

| # | Check | Expect |
|---|---|---|
| 1 | Fresh install, no source added, airplane mode on, run a full session | Everything works; no errors (SC-004) |
| 2 | Settings → Share my times | Off by default; text mentions CC0, anonymous, past sessions, cannot be recalled |
| 3 | Turn it on with 2 past completed own-recipe sessions, with network | Two submissions sent once each; none for manual or datasheet sessions |
| 4 | Finish another own-recipe session with network off, then reconnect | Sent within a minute, no taps (SC-007) |
| 5 | A second device with sharing on submits a time within ±4 % for the same combination | Both devices show the community time with "2 installs" after the next refresh |
| 6 | Open a combination with datasheet and community times | Datasheet first; community group labelled with source name and count, distinct without colour |
| 7 | Combination with only community times, tap Start | Best-backed community time is preselected |
| 8 | Turn sharing off with items queued | Nothing is sent afterward |
| 9 | Reset the contribution ID, submit again | Counts as a new install |
| 10 | Add a static feed URL, then remove it | Its entries appear under its name, then disappear |
| 11 | Point a source at a broken URL | No error during a session; cached data still shown |
| 12 | Trigger the keep-alive workflow manually | Green run |

Release gate: review the Apple privacy answers and the in-app privacy text (FR-024).
