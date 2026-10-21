---

description: "Tasks for Film Development Timer (Develop mode)"
---

# Tasks: Film Development Timer (Develop mode)

**Input**: Design documents from `specs/001-film-develop-timer/`

**Prerequisites**:
- `plan.md`
- `spec.md`
- `research.md` (R1–R13)
- `data-model.md`
- `contracts/`
- `quickstart.md`
- the visual design in `design/develop/` (with its README)

**Tests are included**: Constitution v1.0.0 Principle V requires unit tests,
runnable on Linux, for all domain logic, and test fakes for native
boundaries. Tests marked "write first" must fail before the matching
implementation task.

**Organization**: tasks are grouped by user story, in spec priority order
(US1, US2 → US3, US4 → US5, US6, US7).

**Conventions used by every task**:
- **Flutter:** `~/development/flutter/bin/flutter` (3.47.4 / Dart 3.13.3).
- **Pure logic** goes in `lib/domain/`. It must not import `package:flutter`.
- **Visual reference** for any UI task: the named artboard in
  `design/develop/<Name>.dc.html`, with tokens and classes from
  `design/develop/drk.css`.
- **Theme tokens** come from `lib/app/theme/tokens.dart`, never hard-coded
  colours.
- **Commits:** commit after each task or logical group.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on unfinished
  tasks).
- **[Story]**: US1–US7 from spec.md. Setup, Foundational and Polish tasks
  have no story label.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: dependencies, assets, the compiled dataset, and CI.

- [X] T001 Add runtime dependencies with `flutter pub add`: `flutter_riverpod go_router drift drift_flutter sqlite3_flutter_libs path_provider flutter_soloud audio_session flutter_local_notifications flutter_foreground_task wakelock_plus app_links share_plus file_selector uuid archive crypto http`. Add dev dependencies with `flutter pub add --dev build_runner drift_dev`. Then set `description:` in `pubspec.yaml` to "Darkroom film development timer" and `version: 0.1.0+1`.
- [X] T002 [P] Turn on strict analysis in `analysis_options.yaml`: keep `flutter_lints`, and add `strict-casts`, `strict-inference`, `strict-raw-types`, plus `prefer_const_constructors` and `always_declare_return_types`. Exclude `**/*.g.dart`.
- [X] T003 [P] Create the folder skeleton from plan.md "Source Code", with an empty `.gitkeep` where needed:
  - `lib/app/theme/`, `lib/domain/timeline/`, `lib/domain/exchange/`
  - `lib/data/db/`, `lib/data/repositories/`, `lib/data/dataset/`
  - `lib/platform/cues/`
  - `lib/features/{home,picker,combination,recipe_editor,process_editor,session,sharing,settings,print}/`
  - `test/{domain,data,platform,features}/`, `integration_test/`
  - `assets/{fonts,sounds}/`, `site/`
- [X] T004 [P] Download the JetBrains Mono static TTFs (weights 300, 400, 500, 600, 700, 800) and its OFL licence from the official JetBrains/JetBrainsMono GitHub release into `assets/fonts/`, together with `assets/fonts/OFL.txt`. Declare the family `JetBrainsMono` with those weights in `pubspec.yaml`.
- [X] T005 Write `tool/build_dataset.dart`:
  - load `resources/devdata` with `lib/devdata/loader.dart`, and fail on any `lib/devdata/validator.dart` error
  - write minified `assets/devdata.json` containing `{schema_version:1, dataset_version:"<YYYY.MM.DD>-<n>", films, developers, sources, times}`
  - write `assets/devdata.meta.json` with `{dataset_version, sha256, bytes}`
  - register both under `flutter: assets:` in `pubspec.yaml`
  - run it once and commit the outputs
- [X] T006 [P] Write `tool/make_cue_sounds.py` (stdlib only, no installs):
  - render 12 short mono samples, `cue_{agitate,tick,pip,dump}_t{1,2,3}.wav`, into `assets/sounds/`
  - kinds: agitate is a 2-tone chime of 250 ms, tick is a 30 ms click, pip is an 80 ms beep, dump is a 3-tone chime of 600 ms
  - base pitches per tank: t1 = 440 Hz, t2 = 587 Hz, t3 = 784 Hz
  - also write `.caf` copies via `afconvert` in CI only (see T039), and Android `res/raw` copies in `android/app/src/main/res/raw/`

  Register the assets in `pubspec.yaml` and commit the generated WAVs.
- [X] T007 [P] Create `.github/workflows/ci.yml` on `ubuntu-latest`. It sets up Flutter 3.47.4 and then runs:
  1. `flutter pub get`
  2. `dart run build_runner build --delete-conflicting-outputs`
  3. `flutter analyze`
  4. `dart run tool/validate_devdata.dart`
  5. `flutter test`

  It runs on every push and pull request (Constitution: CI gates).
- [X] T008 [P] Replace the counter app in `lib/main.dart` with a bootstrap stub that runs `ProviderScope(child: DrkApp())`. Create `lib/app/app.dart` with a minimal placeholder `DrkApp`: a `MaterialApp` with a dark `ThemeData` and a single `Scaffold` showing the text "drktimes". Delete `test/widget_test.dart`, and add `test/app/app_smoke_test.dart`, which pumps `DrkApp` and finds "drktimes". `flutter analyze` and `flutter test` must pass straight after this task (CI gate, T007).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: theme, router shell, storage schema, shared domain types, and
the catalogue. **No user-story work starts until this phase is complete.**

### Shared domain (write tests first)

- [X] T009 [P] Write tests in `test/domain/combination_key_test.dart`:
  - **Dilution normalisation:** `"1:50"`→`"1+50"`, `"1/50"`→`"1+50"`, `"1 + 50"`→`"1+50"`, `"Stock"`→`"stock"`, `"1+1+5"` unchanged.
  - **°F to °C:** `68`→`20`, `70`→`21`, `72`→`22`, using `round((F − 32) × 5/9)`.
  - **Canonical string:** `film|developer|dilution|ei|temp_c`.
  - **Film refs:** a catalogue and a user FilmRef with the same id produce different keys.
- [X] T010 [P] Implement `lib/domain/combination_key.dart`, so that T009 passes:
  - `FilmRef` / `DeveloperRef` as `{kind: catalog|user, id}`.
  - `CombinationKey(film, developer, dilution, ei, tempC)` with `canonical`, `==`/`hashCode`, and `fromJson`/`toJson` matching `contracts/exchange-format.schema.json#/$defs/combinationKey`.
  - Dilution must match `^(stock|working|1(\+[0-9]+(\.[0-9]+)?){1,2})$`.
  - `ei` must be "1–25600" and `temp_c` an "integer, 10–45".
- [X] T011 [P] Write tests in `test/domain/process_test.dart`:
  - The default process equals the data-model table exactly:

    | Step | Enabled | Duration | Agitation |
    |---|---|---|---|
    | presoak | off | 60 | stand{30} |
    | developer | on | from recipe | intermittent{60,60,10} |
    | stop | on | 60 | intermittent{60,60,10} |
    | fix | on | 300 | intermittent{60,60,10} |
    | hypo_clear | off | 120 | intermittent{30,60,10} |
    | wash | on | ilford[5,10,20] | none |
    | wetting_agent | on | 30 | none |

  - Validation rejects:
    - a process without exactly one `developer` step
    - zero enabled steps
    - intermittent patterns with `burst_s >= every_s`
    - Ilford fills outside 1–50
  - JSON round-trips through the schema `process` and `step` definitions.
- [X] T012 [P] Implement `lib/domain/process.dart` so that T011 passes:
  - `Process{id, steps, transitionMode: wait_for_me|keep_going}`
  - `Step{id, kind: presoak|developer|stop|fix|hypo_clear|wash|wetting_agent|custom, name (max 40 chars), enabled, durationS, agitation, howTo? (max 1000 chars), wash?, chemicalDilution?}`
  - sealed `AgitationPattern` = `intermittent{initialS, everyS, burstS}` | `continuous` | `stand{initialS, midAgitationAtS?, midBurstS?}` | `none`
  - sealed `WashMethod` = `running{durationS=600}` | `ilford{fills=[5,10,20]}`
  - `Process.defaults()` with id `default`, and the prefilled how-to texts: hypo clear explains that it shortens the wash; the wetting agent says not to shake (foam)
- [X] T013 [P] Create `lib/domain/clock.dart`:
  - `abstract interface class Clock { DateTime now(); }`
  - `SystemClock`
  - `FakeClock` with `advance(Duration)`, exported for tests

### Theme and app shell

- [X] T014 [P] Create `lib/app/theme/tokens.dart` by transcribing the `.th-dark` and `.th-light` variables from `design/develop/drk.css` (the `.th-red` values are copied into a commented-out reference block for Print mode only, not used in Part 1): `bg s1 s2 ln ln2 fg mut dim inv t1 t2 t3`. Also transcribe the type scale: `tx` 124/700, `tl` 64, `tm` 34, `dp` 28, `ti` 20, `bd` 15, `sm` 13, `lbl` 11/600 caps tracking 0.14em, all with tabular figures. Include the spacing scale 4–48, radius 3, and target sizes 44/72/112.
- [X] T015 Create `lib/app/theme/theme.dart` (depends on T014). It provides:
  - `ThemeData` for `dark` and `light` only, both in JetBrains Mono with no shadows and no blur
  - a `DrkTokens` `ThemeExtension` with the session-state styles from `design/develop/Main.dc.html` §04: chip shape per state, and numeral weight 800 act / 700 running / 300 rest
  - tank identity from §05: glyph circle/triangle/square plus colours t1–t3. The glyph and number must identify the tank on their own (Constitution III); hue is extra
- [X] T016 Create `lib/app/router.dart` with `go_router` routes: `/develop` (home), `/print`, `/pick/film`, `/pick/developer`, `/pick/iso`, `/pick/dilution`, `/combo/:key`, `/recipe/edit`, `/process/edit`, `/session`, `/import`, `/backup/import`, `/settings`. Use placeholder screens for now. Replace the placeholder `DrkApp` in `lib/app/app.dart` (from T008) with a `MaterialApp.router` that uses this router and picks the theme from settings. Update `test/app/app_smoke_test.dart` to expect the Develop home placeholder.
- [X] T017 Create the mode shell in `lib/features/home/mode_shell.dart`:
  - "Develop | Print" mode tabs and the `drktimes` wordmark plus settings button, following the `HomeFavourites.dc.html` header
  - a `lib/features/print/print_placeholder_screen.dart` that matches `PrintPlaceholder.dc.html` (FR-001)

### Storage

- [X] T018 Create the drift schema v1 in `lib/data/db/database.dart` with these tables:

  | Table | Columns |
  |---|---|
  | `user_films` | id UUID PK, brand (1–60 chars), name (1–80 chars), box_iso (1–25600), matched_catalog_id?, created_at |
  | `user_developers` | id, brand, name, matched_catalog_id?, created_at |
  | `recipes` | id UUID PK, version int ≥ 1, created_at, updated_at, author_name, ownership own\|received, origin_json, key_canonical (indexed), key_json, dev_time_s (30–7200), dev_agitation_json, process_json?, hidden bool default false |
  | `notes` | id UUID PK, recipe_id FK, author_name, created_at, text (1–4000 chars) |
  | `processes` | id PK, json |
  | `sessions` | id, tank_slot (1–3), tank_label, key_canonical, key_json, time_source_json, dev_time_s, format 35mm\|120, volume_ml, process_snapshot_json, inversion_pace_s, status active\|completed\|aborted, aborted_at_step?, started_at, finished_at?, step_runs_json |
  | `favourites` | key_canonical PK, key_json, created_at |
  | `settings` | single row, every field of data-model.md "Settings" (including `last_mode`, `last_format`, `background_limit_seen`, `notifications_asked`) with the data-model defaults |
  | `dataset_state` | active_version, active_sha256, source bundled\|downloaded, last_checked_at? |

  Run `build_runner`.
- [X] T019 [P] Write `test/data/db/migration_test.dart`. It opens schema v1 in memory, seeds the `default` process and the settings row, and checks the defaults: author "", 35mm 300, 120 500, pace 2.0, sound on, volume 0.7, volume_key_next true, temp_unit c, theme system, last_mode develop, background_limit_seen false, notifications_asked false, last_format 35mm. Use the drift schema-export tooling so future migrations are tested.
- [X] T020 Create `lib/data/db/seed.dart` (first-launch seeding of the `default` process from `Process.defaults()` and the settings row), and `lib/data/repositories/settings_repository.dart` (typed get/watch/update for every Settings field).
- [X] T021 Create `lib/app/providers.dart` with Riverpod providers for `Clock`, `AppDatabase`, `SettingsRepository`, and the catalogue (T023). Each can be overridden in tests.

### Catalogue

- [X] T022 [P] Write tests in `test/data/dataset/catalog_test.dart` against the real `assets/devdata.json`:
  - it loads 172 films and 73 developers
  - `rebrandFamily()` groups `rebrand_of` chains
  - `timesFor(film, dev)` returns `DatasheetTime` with `source` publisher/title/page
  - `defaultRunTimeS` gives the midpoint rounded to 15 s when `time_max_s` is set
  - `isPrimary` is true only for `method == small_tank`
  - rows inherited through a rebrand carry `inheritedFromFilmId` and `rebrandBasis`
- [X] T023 Implement `lib/data/dataset/catalog.dart` (in-memory index built from the compiled asset using `lib/devdata/models.dart`) and `lib/data/dataset/datasheet_time.dart`, following data-model.md "Datasheet pool". T022 must pass.

**Checkpoint**: the app boots into an empty Develop home with the mode tabs,
themes switch, the database seeds, and CI is green.

---

## Phase 3: User Story 1 — Run a guided development session (P1) 🎯 MVP

**Goal**: start from a manually entered developer time. The app runs the
whole process: agitation metronome, cues, dump & pour, Next/Undo, washes,
pause/abort/±30 s, resume after the app is killed, and up to 3 tanks.

**Independent Test**: enter 13:00 → Start with the default process →
complete it to Done, twice: screen covered (sound only) and sound off
(screen only). Quickstart flows C, D, E, F, G and H.

### 3A. Timeline engine (write tests first; pure Dart)

- [X] T024 [P] [US1] Write tests in `test/domain/timeline/compile_test.dart`:
  - Intermittent `{60,60,10}` over 780 s gives agitation windows [0–60), [120–130), [180–190) … with no burst after 770 s.
  - Ticks every `inversion_pace_s` (2 s) inside each window: 30 ticks in the first window, 5 in each burst.
  - The final-10 window is [770–780).
  - `continuous` gives one window covering the whole step.
  - `stand{30, mid 390, 10}` gives windows [0–30) and [390–400).
  - `none` gives no windows.
  - An Ilford wash gives 3 fills of 5, 10 and 20 counted inversions, with no clock end.
- [X] T025 [P] [US1] Write tests in `test/domain/timeline/state_at_test.dart`, using `FakeClock`:
  - `stateAt` returns `agitate`/`rest`/`final10`/`dump_pour`/`wash_fill`/`paused`/`done`, with remaining-time and time-to-next-agitation values.
  - **Pause:** the remaining time freezes and resumes exactly.
  - **±30 s:** shifts the step end and later windows. −30 s never goes below the elapsed time.
  - **`keep_going`:** the next step starts at the previous `ended_at`.
  - **`wait_for_me`:** the state stays `dump_pour` until `next()`.
  - **`undo()`** within 5 s restores `dump_pour` exactly; after 5 s it is a no-op.
- [X] T026 [P] [US1] Write `test/domain/timeline/accuracy_test.dart` for SC-003: simulate the whole default process (dev 13:00, ilford wash, `keep_going`) by stepping `FakeClock` in random 0.1–7 s jumps, including a single 20-minute jump that stands in for a locked phone. Every step boundary must fall within ±1 s of plan, and the result must be identical when the session is rebuilt from persisted anchors halfway through.
- [X] T027 [US1] Implement `lib/domain/timeline/compile.dart` (step plus pace → `StepPlan` with windows, ticks, final10 and end; wash fills) and `lib/domain/timeline/cue_event.dart` (`CueEvent{at, tankSlot, kind: agitateStart|tick|finalPip|dumpPour, title, body}`). T024 must pass.
- [X] T028 [US1] Implement `lib/domain/timeline/session_run.dart`:
  - anchors: `StepRun{stepIndex, startedAt?, endedAt?, adjustS, pauses[{from,to?}], washFillIndex?, nextPressedAt?, undoUntil?}`
  - the pure `stateAt(now)`
  - transitions `start`, `next`, `undo`, `pause`, `resume`, `adjust(±30)`, `abort`, following the data-model state machine
  - `upcomingCues(now, horizon)`
  - `toJson`/`fromJson` for persistence

  T025 and T026 must pass.
- [X] T029 [P] [US1] Write tests in `test/domain/sessions_test.dart`:
  - At most 3 active sessions; starting a 4th throws `TankLimitReached`.
  - Tank slots are reused when freed, with default labels "Tank N".
  - With two tanks in `dump_pour`, `next()` routes to the one with the earliest `ended_at`.
  - `undo()` acts on the session that the last `next()` hit.
  - The merged `upcomingCues` across tanks is sorted by time and capped at 60.
- [X] T030 [US1] Implement `lib/domain/sessions.dart` (`SessionCoordinator`: up to 3 `SessionRun`s, Next routing per FR-070, merged cue stream). T029 must pass.

### 3B. Persistence and platform boundaries

- [X] T031 [US1] Implement `lib/data/repositories/session_repository.dart`. It saves each `SessionRun` to `sessions` on **every** transition, `loadActive()` rebuilds the coordinator on launch (FR-003), and finished sessions are written with status `completed` or `aborted` and `aborted_at_step`.
- [X] T032 [P] [US1] Define `lib/platform/cues/cue_scheduler.dart` (the interface from `contracts/platform-channels.md` §1) and `test/platform/fake_cue_scheduler.dart` (it records foreground plays and the background schedule).
- [X] T033 [P] [US1] Implement `lib/platform/cues/soloud_player.dart`:
  - preload the 12 samples from `assets/sounds/`
  - set up an `audio_session` playback category that mixes with others
  - a ~50 ms look-ahead scheduler that plays `CueEvent`s at their wall-clock time
  - respect `sound_on` and `volume` from settings (FR-041)
  - handle audio interruptions (phone call, alarm, Siri, another app's voice message) via `audio_session` interruption events. When an interruption ends, re-activate the session and resume the scheduler from `now`. Cues that fell inside the interruption are skipped, not replayed late, and timing is unaffected. Add `test/platform/cue_interruption_test.dart` using a fake interruption stream
- [X] T034 [P] [US1] Implement `lib/platform/cues/notification_cues.dart` with `flutter_local_notifications`:
  - iOS: `timeSensitive`, custom sound `cue_<kind>_t<slot>.caf`
  - Android: channel `session_cues` (high importance, custom raw sound)
  - `scheduleBackground` takes non-tick events only, as a rolling window of ≤ 60
  - `cancelBackground`
  - also define the `NotificationPermission` interface in `lib/platform/notification_permission.dart`: `Future<PermissionState> status()` (granted / denied / notDetermined), `Future<PermissionState> request()`, and `Future<void> openSystemSettings()`. It covers the iOS authorisation and Android 13+ `POST_NOTIFICATIONS`. Add `test/platform/fake_notification_permission.dart`, with a settable state and recorded requests (Constitution V)
- [X] T035 [US1] Implement `lib/platform/cues/app_cue_scheduler.dart`. It combines T033 and T034 and listens to the app lifecycle: on `paused`, cancel foreground playback and schedule the background notifications; on `resumed`, cancel them and resume foreground playback.
- [X] T036 [P] [US1] Define the `ScreenWake` interface (`Future<void> hold()`, `Future<void> release()`) in `lib/platform/wake.dart`, with the real `WakelockPlusScreenWake` (`wakelock_plus`: held while there is at least one active session, released otherwise; FR-037) and `test/platform/fake_screen_wake.dart`, which records hold/release calls (Constitution V).
- [X] T037 [P] [US1] Define the `SessionForegroundService` interface (`start()`, `update(List<TankLine>)`, `stop()`) in `lib/platform/foreground_service.dart`, with a no-op implementation for iOS and `test/platform/fake_foreground_service.dart`, which records the calls (Constitution V). The Android implementation uses `flutter_foreground_task` with `foregroundServiceType="mediaPlayback"`, an ongoing notification on channel `session_ongoing` with one line per tank (e.g. "T1 Developer · rest · 4:12"), and starts and stops with the first and last active session. Add the permissions and `<service>` to `android/app/src/main/AndroidManifest.xml`.
- [X] T038 [P] [US1] Implement the Android volume-key hook in `android/app/src/main/kotlin/**/MainActivity.kt` and `lib/platform/volume_keys.dart`:
  - `android/app/src/main/kotlin/**/MainActivity.kt` overrides `onKeyDown`/`onKeyUp` for VOLUME_UP/DOWN. It consumes the event **only while armed** and sends `volumeKey{key}` over the MethodChannel `am.drktimes/volume_keys`.
  - `lib/platform/volume_keys.dart` defines the `VolumeKeys` interface (`Future<void> setArmed(bool)`, `Stream<VolumeKey> presses`), with the MethodChannel implementation for Android and a no-op for iOS (FR-043, research R11).
  - `test/platform/fake_volume_keys.dart` exposes `armed` and an `emit(VolumeKey)` for tests (Constitution V).

### 3C. Spike R3: background cues on real devices (⚠️ BLOCKING gate before 3D)

- [X] T039 [US1] Create `.github/workflows/ios-testflight.yml` on `macos-latest`. It is triggered by `workflow_dispatch` and tags `v*`, and runs:
  1. Set up Flutter 3.47.4.
  2. Run `tool/make_cue_sounds.py`, then convert the WAVs to `.caf` with `afconvert` into `ios/Runner/Sounds/`.
  3. `flutter build ipa --export-options-plist ios/ExportOptions.plist`, using automatic signing with the App Store Connect API key from secrets `ASC_KEY_ID`, `ASC_ISSUER_ID` and `ASC_KEY_P8`.
  4. Upload with `xcrun altool --upload-app` (or `fastlane pilot`).

  Add `ios/ExportOptions.plist`.
- [X] T040 [US1] Configure the iOS project in `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements` and `ios/Podfile`:
  - In `ios/Runner/Info.plist`, add the notification usage description and keep `UIBackgroundModes` **without** `audio`.
  - Create `ios/Runner/Runner.entitlements` with the Time Sensitive Notifications capability.
  - Set the deployment target to iOS 16.0 in `ios/Podfile` and the Xcode project.
  - Use the bundle id placeholder `am.drktimes`.
- [X] T041 [US1] Build the throwaway spike screen `lib/features/session/spike_screen.dart`. It is reachable only in debug builds or through a hidden long-press on the wordmark. It starts a single "Developer 15:00, intermittent {60,60,10}" run through `SessionCoordinator` + `AppCueScheduler` + wake + foreground service, and shows the raw state.
- [ ] T042 [US1] Run the device checks in quickstart §3.1–3.2 (TestFlight) and §2 flow F (Android) on the spike, and record the results in `specs/001-film-develop-timer/spike-r3-results.md`. **Exit criteria** (research R3):
  - iOS: with the phone locked, every agitate and dump cue arrives within ±1 s, with the silent switch on and with Focus on.
  - Android: with the screen off, every tick plays.
  - Foreground tick jitter: log each tick's scheduled vs. actual play time (debug-only logger in `lib/platform/cues/soloud_player.dart`) over the 15-minute step. p95 must be ≤ 30 ms on both platforms (plan Performance Goals). Record the numbers in the results file.

  **If iOS fails: stop and review R3 with the owner before T043.**

  Also run the spike once with notifications **refused**, on both platforms. The "Background cues are off" banner must appear, and foreground cues must keep working with the screen on (quickstart §3.5, §2 flow L).

### 3D. Session UI (after T042 passes)

- [ ] T043 [P] [US1] Build `lib/features/session/widgets/` from the `SessionReady`, `SessionAgitate`, `SessionRest` and `SessionFinal` artboards. It contains:
  - `state_chip.dart`, with one shape per state (`Main.dc.html` §04)
  - `big_time.dart`, the `tx` numerals with weight by state
  - `step_progress.dart`, the `.prog` bars with step labels
  - `beat_pulse.dart`, a pulse at `inversion_pace_s` with an inversion counter
  - `pips.dart`, the 10 last-seconds pips
  - `next_button.dart`, the 112 px `btn-xl` labelled with its tank, e.g. "Next · Tank 2"
- [ ] T044 [US1] Build `lib/features/session/session_screen.dart` for a single tank. It renders `stateAt(now)` on a `Ticker`, and contains:
  - the step name, the remaining time, "Next · <step> <time>", step progress, and the how-to text (FR-035)
  - Ready/pour with amounts (taken from the session's `volume_ml` and dilution) and a giant Start (FR-036). Non-developer steps show amounts only when `chemicalDilution` is set, e.g. "Fixer 1+4 · 300 ml → 60 ml + 240 ml water"; otherwise just "Pour <step>" (FR-027)
  - Dump & pour, "Dump <step> → pour <next>", showing the count-up wait time
  - an Undo toast for 5 s after Next (`SessionUndo.dc.html`)
  - secondary controls: ±30 s, Pause and Abort (FR-047)
- [ ] T045 [P] [US1] Build the Pause and Abort confirm sheets in `lib/features/session/confirm_sheets.dart`. Pause shows "The chemistry keeps working while paused." (`SessionPaused.dc.html`); Abort follows `SessionAbort.dc.html` (FR-046).
- [ ] T046 [P] [US1] Build the wash views in `lib/features/session/wash_views.dart`: Ilford fill N/3 with counted inversions (`n/target`) in time with the ticks, then "Dump" and Next between fills (`SessionWashIlford.dc.html`); and a running-water countdown (`SessionWashRunning.dc.html`) (FR-034).
- [ ] T047 [US1] Build the multi-tank layout in `lib/features/session/multi_tank_view.dart`. The tank needing attention soonest is shown large; the others are compact `.tank` rows (glyph, step·state, time). Every instruction is prefixed with the tank label, and the 4th-tank block uses the message "At most 3 tanks can run at once." Follow the `MultiAgitateRest`, `MultiBothAgitate`, `MultiBothWaiting` and `MultiThree` artboards (FR-068–FR-070).
- [ ] T048 [US1] Build the Done screen in `lib/features/session/done_screen.dart`: a summary of the combination, time source and actual step durations, with an "Add a note" field (saved by US3/T077; until then it's disabled) (`SessionDone.dc.html`, FR-049).
- [ ] T049 [US1] Build the manual-time start sheet in `lib/features/session/manual_start_sheet.dart`. It asks for a developer time (mm:ss) with an optional film/developer label, then starts a session with the default process. It is reachable from Develop home as "Start with a time", and is the MVP entry point before US2.
- [X] T050 [US1] Wire up the session lifecycle in `lib/features/session/session_controller.dart` (Riverpod). It connects the coordinator, repository persistence, the cue scheduler, wake, the foreground service, and arming the volume keys (only while awaiting Next and with `volume_key_next` on). On first background entry on iOS it shows the one-time "Ticks need the screen on; cues still arrive as notifications" sheet and sets `background_limit_seen`. On app start, active sessions are restored and the app routes to `/session` (FR-003).
  - **Notification permission (FR-048):**
    - On the first session start, if `notifications_asked` is false, call `NotificationPermission.request()` **before** the timer begins, then set `notifications_asked`.
    - On every session start, if `status()` is denied, still start the session, and show a non-blocking banner on the session screen: "Background cues are off. Keep the screen on, or allow notifications in Settings." The banner has an "Open Settings" button (`openSystemSettings()`).
    - Foreground cues are unaffected. `scheduleBackground` is skipped while permission is denied.
- [ ] T051 [P] [US1] Write widget tests in `test/features/session/session_screen_test.dart` using `FakeClock`, `FakeCueScheduler`, `FakeScreenWake`, `FakeForegroundService` and `FakeVolumeKeys`. They also check that the wake hold, foreground-service start/stop, and volume-key arming follow the session lifecycle. They cover each state's chip, label and numeral weight, the Next→Undo flow, Pause confirm, and a multi-tank Next label naming the right tank.
- [ ] T052 [P] [US1] Write golden tests in `test/features/session/goldens_test.dart` for Ready, Agitate, Rest, Final10, Dump & pour, Ilford wash, Paused, Done, and two-tanks-both-waiting, in the `dark` and `light` themes. Also render each one through a **monochrome** (luminance-only) colour filter, the equivalent of an iOS system red colour tint, and check that states and tanks are still told apart by chip shape, numeral weight, glyph and label (Constitution III).
- [X] T053 [US1] Add settings rows for sound on/off, volume, inversion pace and "Volume button as Next" (Android only, hidden on iOS) in `lib/features/settings/settings_screen.dart`, following `Settings.dc.html` (FR-041, FR-043, FR-066). The volume-button row is design gap #2.
- [ ] T054 [US1] Write `integration_test/session_flow_test.dart` (Android emulator), covering quickstart flows C, D and E with a shortened 1-minute developer time and an injected fast clock.
- [ ] T055 [US1] Gate `lib/features/session/spike_screen.dart` (from T041) and its route in `lib/app/router.dart` behind `kDebugMode` only, so release builds don't include it.

**Checkpoint**: MVP. A full process runs from a typed-in time, with sound,
screen, multiple tanks, and resume after the app is killed.

---

## Phase 4: User Story 2 — Look up a development time (P1)

**Goal**: film → developer → ISO → dilution/temperature → a combination
page with sourced datasheet times, amounts, a temperature estimate and
Start.

**Independent Test**: quickstart flow A (HP5 Plus · DD-X 1+4 · ISO 400 ·
20 °C → 9:00 Ilford source, 35mm and 120 amounts) and flow B up to the
"No published time" page.

### Tests first (pure Dart)

- [X] T056 [P] [US2] Write `test/domain/search_test.dart`:
  - normalisation: "Tri-X" becomes "trix", "HP5+" becomes "hp5", and so on
  - ranking order: exact > prefix > word-prefix > substring, with ties broken by current before discontinued, then alphabetically
  - SC-012: `trix`, `hp5`, `delta 400`, `R09` and `rodinal` each give the intended item in the top 3, against the real catalogue
- [X] T057 [P] [US2] Write `test/domain/amounts_test.dart`:
  - Rodinal 1+50: 300 ml gives 5.9 + 294.1, and 500 ml gives 9.8 + 490.2
  - `1+1+5` at 300 ml gives 42.9 + 42.9 + 214.3
  - `stock` and `working` give the full volume with no water
  - everything is rounded to 0.1 ml
- [X] T058 [P] [US2] Write `test/domain/temperature_test.dart`:
  - `t₂ = t₁·e^(−0.081·(T₂−T₁))`, rounded to 15 s; 13:00 at 20 °C gives the expected value at 22 °C
  - no estimate outside 18–26 °C
- [X] T059 [P] [US2] Write `test/domain/summary_test.dart`: shown only with 2 or more times; the median is rounded to 15 s; min–max range.
- [X] T060 [P] [US2] Write `test/domain/preselect_test.dart` for all four FR-071 branches:
  1. the latest session's time source, still existing and visible; an edited recipe resolves to its current version
  2. the primary datasheet time from the newest source (by edition, then retrieval date), using the midpoint for a range
  3. the user's own most recently updated recipe
  4. the most recently imported received recipe

  It also covers falling through when a source has been hidden or removed.

### Implementation

- [X] T061 [P] [US2] Implement `lib/domain/search.dart` (R9: in-memory index over catalogue plus user entries, with the synonym list in `assets/search_synonyms.json`). T056 must pass.
- [X] T062 [P] [US2] Implement `lib/domain/amounts.dart` (FR-026). T057 must pass.
- [X] T063 [P] [US2] Implement `lib/domain/temperature.dart` (R7). T058 must pass. Add the citation text "Based on Ilford's published time/temperature compensation chart; estimate only" as a constant for the info sheet.
- [X] T064 [P] [US2] Implement `lib/domain/summary.dart`. T059 must pass.
- [X] T065 [US2] Implement `lib/domain/preselect.dart`. It takes datasheet times, recipes and the latest session for a key as plain inputs. T060 must pass.
- [X] T066 [US2] Implement `lib/data/repositories/combination_repository.dart`, which assembles a `CombinationView` for a key from:
  - the catalogue's `DatasheetTime`s, with inherited and rebrand labels
  - own and received recipes (none yet until US3/US6)
  - the latest session
  - the summary
  - the preselection

### UI

- [X] T067 [US2] Build the Search tab `lib/features/home/search_tab.dart` (`HomeSearch.dc.html`): one field, mixed film and developer results; tapping a film starts the picker.
- [X] T068 [P] [US2] Build `lib/features/picker/pick_film_screen.dart` (`PickFilm.dc.html`, with the 4-step `.wiz` header): search plus a list. Its "Not in the list? Add it" link is wired in US3/T072.
- [X] T069 [P] [US2] Build `lib/features/picker/pick_developer_screen.dart` (`PickDeveloper.dc.html`). Developers with datasheet times or recipes for this film come first under "Has times for this film", and all others below (FR-007).
- [X] T070 [P] [US2] Build `lib/features/picker/pick_iso_screen.dart` (`PickISO.dc.html`): box speed first, then each EI with data labelled "push +N" or "pull −N", then "Custom" (FR-008).
- [X] T071 [US2] Build `lib/features/picker/pick_dilution_screen.dart` (`PickDilution.dc.html`). Dilution and temperature are preselected from the data and editable. Temperature uses the whole-degree stepper; in °F mode it shows °F and stores the rounded °C (FR-009, FR-073).
- [X] T072 [US2] Build `lib/features/combination/combination_screen.dart` (`Combination.dc.html`):
  - title and key line
  - "Time to use" in `tx`, with the "Used last time" chip when preselection branch 1 applied, and the source line (publisher · doc · p.N)
  - Start (→ session with `time_source`, format and volume), and "Runs as Tank N · Rename"
  - the time list with the summary header; datasheet rows show method labels for non-`small_tank` rows
  - **range display:** "7:00–8:00 · using 7:30" (design gap #4, FR-011)
  - the **rebrand label** "Inherited from <film>" and "(rebrand reported, not confirmed)" (design gap #1, FR-013)
  - the Chemistry block with the 35mm/120 toggle and amounts
  - "Your water is another temperature?", a stepper plus an "≈ mm:ss estimate" label. A "Save as my recipe" action next to the estimate is laid out here but stays hidden until US3 (T080) wires it
  - the notes section (empty until US3)
  - a Favourite star (wired in US5)
- [X] T073 [P] [US2] Build `lib/features/combination/combo_empty_screen.dart` (`ComboEmpty.dc.html`): "No published time for this combination.", with "Add yours" (→ the US3 editor) and "Pick another developer".
- [X] T074 [P] [US2] Add a "Temperature unit" row and "Tank volumes" (35mm/120 ml) rows to `lib/features/settings/settings_screen.dart` (FR-025, FR-066).
- [X] T075 [P] [US2] Write widget tests in `test/features/combination/combination_screen_test.dart`. Cover SC-013: datasheet, own and received times render in **one list with the same row widget**; only datasheet rows carry the "Datasheet · <publisher/doc>" label; own rows say "Your recipe"; received rows show the sharer's name; the order is datasheet, then own, then others. Also cover the source line, range and midpoint, the inherited and reported labels, the amounts toggle, the estimate shown only within 18–26 °C, the "Save as my recipe" action present only when an estimate is shown (once T080 has unhidden it), and the empty state.

**Checkpoint**: US1 + US2 together give the full "look up and develop"
product for datasheet combinations.

---

## Phase 5: User Story 3 — Create and customise my own recipes (P2)

**Goal**: own recipes from a datasheet baseline or from scratch, user-added
films and developers, dated notes, push/pull, and the Done-screen note.

**Independent Test**: quickstart flow B. Create Tri-X 400 · Rodinal 1+50 ·
ISO 400 · 20 °C · 13:00 with a note; it shows on the combination page and
survives a restart.

- [X] T076 [P] [US3] Write `test/data/repositories/recipe_repository_test.dart` (in-memory drift):
  - create with `origin` datasheet or scratch; `version` starts at 1 and each edit does `version+1` and `updated_at=now`
  - editing a `received` recipe creates a new `own` recipe with `origin.kind=copy_of` and leaves the received one untouched (FR-023)
  - notes are ordered by `created_at` and limited to "1–4000 chars"
  - `dev_time_s` must be "30–7200"
- [X] T077 [US3] Implement `lib/data/repositories/recipe_repository.dart` and `lib/data/repositories/note_repository.dart` per data-model.md "Recipe" and "Note". T076 must pass. Enable the Done-screen "Add a note" (T048) per US3 #7:
  - if the session ran the user's own recipe, the note is added to it
  - otherwise an own recipe is created from the session's time source with that note
- [X] T078 [P] [US3] Implement `lib/data/repositories/user_catalog_repository.dart`, which handles UserFilm (brand "1–60 chars", name "1–80 chars", box_iso "1–25600") and UserDeveloper. Feed user entries into the search index (T061) with a "user-added" marker (FR-015).
- [X] T079 [US3] Build `lib/features/picker/add_entry_sheet.dart`, the "Add a film / Add a developer" form, and wire it to the "Not in the list? Add it" links in `PickFilm` and `PickDeveloper`.
- [X] T080 [US3] Build `lib/features/recipe_editor/recipe_editor_screen.dart` (`RecipeEditor.dc.html`):
  - film, developer, dilution, ISO with a push/pull label, whole-degree temperature, developer time (mm:ss)
  - a developer agitation pattern picker (intermittent, continuous, stand, none, with fields)
  - "Custom process for this recipe", which opens the US4 editor or falls back to the default
  - the notes log with an add-note field
  - an origin line ("Based on Kodak datasheet F-4017" / "From scratch" / "Edited copy of <author>'s recipe")

  Entry points: Customise from the combination page, "Add yours" from the empty page, and **"Save as my recipe"** next to the temperature estimate on the combination page (FR-014). Unhide that action from T072 here. It opens the editor prefilled with:
  - the same film, developer, dilution and ISO
  - the estimate's temperature (whole °C) and estimated `dev_time_s`
  - the agitation of the time it was based on
  - `origin = {kind: temperature_estimate, base: <origin of the base time>}`

  The origin line reads "Estimated for <T₂> °C from <base source> at <T₁> °C". The saved recipe belongs to the new-temperature combination.
- [X] T081 [US3] Extend `combination_repository.dart` and `combination_screen.dart` with "Your recipes" rows and all notes from every visible recipe in the group (author · date · which recipe) (FR-017, FR-021).
- [X] T082 [P] [US3] Write widget tests in `test/features/recipe_editor/recipe_editor_test.dart`: validation messages, the push label for EI 800 on a 400 film, saving from a datasheet baseline sets the origin, and saving from a temperature estimate creates an `own` recipe whose key has the new `temp_c` and whose origin is `temperature_estimate` with `base` pointing at the original source.

**Checkpoint**: missing combinations are no longer dead ends.

---

## Phase 6: User Story 4 — Customise the development process (P2)

**Goal**: editing the default process, per-recipe processes, agitation and
wash editors, how-to text, and the transition mode.

**Independent Test**: enable hypo clearing, set the fixer to 7:00, choose
the running-water wash, save as default, then run a session that follows
the new sequence.

- [X] T083 [P] [US4] Write `test/data/repositories/process_repository_test.dart`: get and save the `default` process, refuse to save an invalid process (the T011 rules), and confirm that sessions keep `process_snapshot` after the default is edited.
- [X] T084 [US4] Implement `lib/data/repositories/process_repository.dart`. T083 must pass.
- [X] T085 [US4] Build `lib/features/process_editor/process_editor_screen.dart` (`ProcessEditor.dc.html`):
  - a reorderable step list with enable switches, and add/remove for custom steps
  - per step: name (max 40 chars), duration, agitation pattern editor, how-to text (max 1000 chars), and optional chemical dilution
  - the wash method switch: running (duration) or Ilford (fills, each "1–50")
  - "Between steps: Wait for me / Keep going" (FR-042)
  - save as default, or save into the recipe being edited (FR-030)
- [ ] T086 [US4] Make the session start use the recipe's `process` when present, otherwise the default (US4 #5), in `lib/features/session/session_controller.dart`. Show the step how-to text on the session screen (design gap #3).
- [X] T087 [P] [US4] Add a "Default process" row (→ editor) and a "Between steps" default to `lib/features/settings/settings_screen.dart`.
- [X] T088 [P] [US4] Write widget tests in `test/features/process_editor/process_editor_test.dart`: reordering, rejecting a second developer step, the Ilford fill limits, and switching the transition mode.

---

## Phase 7: User Story 5 — Get back to what I use (P3)

**Goal**: Favourites (whole combinations), Recent sessions, last-mode
memory, resuming active sessions, and empty states.

**Independent Test**: star a combination, run a session, kill and reopen
the app. It opens in Develop with the favourite listed, the run is in
Recent, and a repeat run takes 3 taps or fewer (SC-001).

- [X] T089 [P] [US5] Implement `lib/data/repositories/favourites_repository.dart` (add, remove and watch by `key_canonical`), with a test in `test/data/repositories/favourites_repository_test.dart`.
- [X] T090 [US5] Build the Favourites tab `lib/features/home/favourites_tab.dart` (`HomeFavourites.dc.html`): rows with the key line and preselected time; one tap opens `/combo/:key`. Wire the star on the combination screen (FR-051).
- [X] T091 [US5] Build the Recent tab `lib/features/home/recent_tab.dart` (`HomeRecent.dc.html`): newest first, with date, combination, tank label, and completed or "aborted at step N". One tap opens the combination with the same recipe and format preselected (FR-052).
- [X] T092 [P] [US5] Build the empty states in `lib/features/home/empty_states.dart` (`HomeEmpty.dc.html`): "No favourites yet", the Recent empty text, and a "Find a combination" button that goes to Search.
- [X] T093 [US5] Persist and restore `last_mode` in `lib/features/home/mode_shell.dart` and `lib/app/router.dart`: the initial route is `/develop` or `/print` from settings, unless active sessions exist, in which case it is `/session` (FR-002, FR-003).
- [ ] T094 [P] [US5] Write `integration_test/return_flow_test.dart` (Android): star → run → restart → favourite and recent present → Start in 3 taps or fewer.

---

## Phase 8: User Story 6 — Share recipes and see everyone's times together (P3)

**Goal**: share by link or file with no server, import preview, idempotent
merging, user-entry matching, hiding imports, the rebrand family section,
and the landing site.

**Independent Test**: quickstart flow I. Share on phone A → import on
phone B → import again (no duplicate) → two other recipes for the same key
are grouped with the summary and all notes.

### Tests first

- [X] T095 [P] [US6] Write `test/domain/exchange/codec_test.dart`:
  - encode a recipe document and validate it against `contracts/exchange-format.schema.json` (dev dependency `json_schema`, or a hand-written validator)
  - unknown fields are ignored
  - `format_version` "2.0" is rejected
  - the link round-trip `https://<host>/r#base64url(deflate-raw(utf8 json))` is identical
  - links over 6,000 characters report `tooLongForLink`
  - corrupt base64 or inflate input gives a typed error
- [X] T096 [P] [US6] Write `test/domain/exchange/merge_test.dart`, covering data-model "Import merge":
  - an unknown id is inserted as `received`
  - an id matching an `own` recipe stays own
  - a higher `(version, updated_at)` replaces the fields and unions notes by id
  - equal or older gives "already up to date"
  - matching user entries on normalised `brand+name` against the catalogue or existing user entries produces match offers
  - an empty `author_name` becomes "unknown author"

### Implementation

- [X] T097 [US6] Implement `lib/domain/exchange/codec.dart` (document model, JSON with `format: "drktimes-exchange"` and `format_version: "1.0"`) and `lib/domain/exchange/link.dart` (deflate-raw via `archive`, unpadded base64url, the `kShareHost` constant in `lib/app/config.dart`). T095 must pass.
- [X] T098 [US6] Implement `lib/domain/exchange/merge.dart` (a pure plan of inserts, updates and match offers) and `lib/data/repositories/import_service.dart` (applies the plan in one drift transaction). T096 must pass.
- [X] T099 [US6] Build the share flow in `lib/features/sharing/share_sheet.dart` (`ShareRecipe.dc.html`):
  - ask for the author name once if it's empty (FR-055)
  - offer "Share link" (if it's ≤ 6,000 characters) and "Share file". The file is `<Film>-<Developer>-<dilution>-ISO<ei>-<temp>C.drktimes`, sent with `share_plus`
  - share only own recipes (FR-053)
- [X] T100 [US6] Define the `Intake` interface (`Stream<IncomingPayload>`, where the payload is a link URI or file bytes plus name) in `lib/platform/intake.dart`, with `test/platform/fake_intake.dart` exposing `emitLink`/`emitFile` (Constitution V). The real implementation takes the `app_links` URI stream plus platform file-open → decode → route to `/import` (recipe) or `/backup/import` (backup). Invalid input goes to the "This link isn't a valid drktimes recipe" screen.
- [X] T101 [US6] Build the import preview in `lib/features/sharing/import_screen.dart` (`ImportNew.dc.html`, `ImportUpdate.dc.html`): author, key, time and note count, then Import, the "already up to date" / "updated" result, and dialogs for the match offers (FR-056–FR-058).
- [X] T102 [US6] Extend `lib/data/repositories/combination_repository.dart` and `lib/features/combination/combination_screen.dart`:
  - "From others" rows with author names
  - a summary across all visible times
  - **Hide** / **Remove** on received recipes (design gap #5, FR-059)
  - the labelled secondary section "Same combination on <original/other rebrands>" listing recipes and notes from the rebrand family (FR-018)
- [X] T103 [P] [US6] Register file and link handling in `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements` and `android/app/src/main/AndroidManifest.xml`:
  - `ios/Runner/Info.plist`: `UTExportedTypeDeclarations` `am.drktimes.exchange` (conforms to `public.json`, `public.data`, extension `drktimes`), `CFBundleDocumentTypes`, and `LSSupportsOpeningDocumentsInPlace=false`
  - `ios/Runner/Runner.entitlements`: `applinks:<host>`
  - `android/app/src/main/AndroidManifest.xml`: `VIEW`/`SEND` intent filters for `.drktimes`, `application/json` and `application/octet-stream`, and an auto-verified App Link for `https://<host>/r`
- [X] T104 [P] [US6] Create `site/r/index.html`, the static landing page:
  - inline JS decodes the fragment (DecompressionStream "deflate-raw" plus base64url)
  - read-only preview: author, film, developer, dilution, ISO, temperature, time and notes
  - "Get drktimes" and "Open in drktimes" links
  - an invalid-link message
  - no analytics, no external scripts, no cookies
- [X] T105 [P] [US6] Create `site/.well-known/apple-app-site-association` (paths `/r*`, appID `<TEAMID>.am.drktimes`) and `site/.well-known/assetlinks.json` (package `am.drktimes`, release certificate SHA-256 placeholder), plus `site/README.md` explaining how to deploy to the `<user>.github.io` repository (research R6).
- [X] T106 [P] [US6] Add an "Author name" row to `lib/features/settings/settings_screen.dart` (FR-055).
- [ ] T107 [US6] Write `integration_test/share_flow_test.dart` (Android): export a recipe file → import it → import again (up to date) → import a newer version (updated).

---

## Phase 9: User Story 7 — Back up and move to a new phone (P3)

**Goal**: export all user data to one file and import it with a merge.

**Independent Test**: export → wipe → import gives 100% back; importing
again changes nothing (SC-010).

- [X] T108 [P] [US7] Write `test/data/backup_test.dart`: seed every table → export a `kind: "backup"` document → wipe → import → deep-equal. Importing a second time adds nothing. An older backup never overwrites newer local rows. Settings are restored only when `restoreSettings: true`. Active sessions are not exported.
- [X] T109 [US7] Implement `lib/data/repositories/backup_service.dart`. Export covers recipes (with ownership and hidden), notes, user films and developers, favourites, finished sessions, processes and settings. Import goes through `import_service.dart` per entity. T108 must pass.
- [X] T110 [US7] Build `lib/features/sharing/backup_screens.dart`. "Export all" writes `drktimes-backup-YYYY-MM-DD.drktimes` through the share sheet or `file_selector`. "Import all" picks a file and shows a confirm with counts and the "Restore settings too" toggle. Add both rows to `settings_screen.dart` (FR-061).

---

## Phase 10: Polish & Cross-Cutting Concerns

- [ ] T111 [P] Implement the dataset updater, `lib/data/dataset/dataset_updater.dart` (FR-064, contracts/links-and-files.md §5):
  - at most every 24 h, and never during an active session
  - a plain `GET` with no query string and no custom headers
  - apply an update only if the version is newer, the app version is at least `min_app_version`, the SHA-256 matches, and `validator.dart` passes
  - swap atomically into app support storage, and update `dataset_state`

  Add tests in `test/data/dataset/dataset_updater_test.dart` with a fake HTTP client (bad sha, bad schema, older version, success).
- [ ] T112 [P] Add the `site/dataset/` publish step: extend `tool/build_dataset.dart` with `--site` to write `site/dataset/devdata-<version>.json` and `site/dataset/manifest.json`.
- [ ] T113 [P] Write a privacy test, `test/platform/no_network_test.dart`. It runs the app's providers through lookup, recipe, session and share flows with an `HttpOverrides` that fails on any request other than the manifest and dataset URLs (SC-016, Constitution II).
- [ ] T114 [P] Complete Settings against `Settings.dc.html`. Add a "Notifications: allowed / off" status row, read from `NotificationPermission.status()`, with a "Fix" link that calls `openSystemSettings()` when off. Theme (system/dark/light), the "Your data stays on this phone. Nothing is tracked." line, and app and dataset version info. Check every FR-066 row is present.
- [ ] T115 [P] Accessibility pass across `lib/features/**`, with contrast checks in `test/app/contrast_test.dart`:
  - semantics labels on every icon button
  - text contrast ≥ 4.5:1 in all three themes, checked against tokens in `test/app/contrast_test.dart`
  - minimum target 44 px, primary session controls 72 px, Start/Next 112 px (Constitution III)
- [ ] T116 [P] Replace the template text in `README.md` with: what drktimes is, how to build it (Flutter path, `ANDROID_AVD_HOME`), the MIT licence for the code and CC0 for the dataset, and links to `specs/`, `design/` and `resources/devdata/README.md`. Add a `LICENSE` file with the MIT text, held by "drktimes contributors".
- [ ] T117 Run the full `quickstart.md`: §1 automated, §2 Android flows A–K, §3 the TestFlight checks, §4 the human checks. Record the results in `specs/001-film-develop-timer/validation.md` and fix any failures before closing the feature.

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (Phase 1)** comes first. T005 needs the existing `lib/devdata`.
- **Foundational (Phase 2)** depends on Setup and blocks every user story.
- **US1 (Phase 3)** depends on Foundational. Inside it the order is fixed:
  1. 3A, the engine
  2. 3B, platform
  3. 3C, the spike gate (**T042 must pass before T043**)
  4. 3D, the UI
- **US2 (Phase 4)** depends on Foundational. Its Start button needs US1
  (T050) to launch sessions; everything else is independent and can run in
  parallel with US1 3A–3C.
- **US3 (Phase 5)** depends on US2 (the combination page and picker).
  Enabling the Done note (T077) touches US1's T048.
- **US4 (Phase 6)** depends on Foundational (T012) and US1 (the session
  controller). Its recipe-override part needs US3 (T080).
- **US5 (Phase 7)** depends on US1 (sessions) and US2 (the combination
  page).
- **US6 (Phase 8)** depends on US3 (recipes and notes).
- **US7 (Phase 9)** depends on US6's import service (T098).
- **Polish (Phase 10)** comes after the stories it touches. T111–T113 can
  start once Foundational is done.

### Story completion order

```text
Setup → Foundational → US1(3A→3B→3C gate→3D) ─┬─→ US4 ─┐
                       US2 (parallel w/ US1A–C)┴─→ US3 ─┼─→ US6 → US7 → Polish
                                                  US5 ──┘
```

### Within each story

- Tests marked "write first" come before their implementation, and must
  fail first.
- The domain comes before repositories, which come before the UI, which
  comes before integration tests.

---

## Parallel Examples

**Phase 2 (after T008)**: T009, T011, T013, T014, T019 and T022 together.
Then T010, T012 and T023 together.

**US1, 3A**: T024, T025, T026 and T029 (tests) together. Then T027, then
T028, then T030.

**US1, 3B**: T032, T033, T034, T036, T037 and T038 together, then T035.

**US1, 3D**: T043, T045 and T046 together, then T044, then T047–T050. Then
T051 and T052 together.

**US2**: T056–T060 (tests) together. Then T061, T062, T063 and T064
together, then T065, then T066. Then T068, T069 and T070 together.

**US6**: T095 and T096 together. Then T103, T104, T105 and T106 in parallel
with T097–T102.

---

## Implementation Strategy

### MVP (US1 only)

1. Phases 1–2.
2. US1 3A–3B. Then run the **spike gate T042 on TestFlight and Android**.
3. US1 3D, then **stop and validate**: quickstart flows C–H and the
   SC-004/SC-005 human checks.
4. Ship a TestFlight build for the owner's own runs using "Start with a
   time".

### Incremental delivery

| Step | Adds | Result |
|---|---|---|
| 1 | US2 | Datasheet lookup. TestFlight build |
| 2 | US3 + US4 | Own recipes and processes. The owner's Tri-X / Rodinal 1+50 is covered |
| 3 | US5 | Fast repeats |
| 4 | US6 + US7 | Sharing and backup. Deploy `site/` to the GitHub user site |
| 5 | Polish | Full quickstart, then App Store submission |

---

## Notes

- **Story labels:**
  - [US1] session
  - [US2] lookup
  - [US3] recipes
  - [US4] process
  - [US5] favourites/recent/mode
  - [US6] share/merge
  - [US7] backup
- **Design gaps** from `design/develop/README.md` are covered by:
  - T072: rebrand label, range display
  - T053: volume-key setting
  - T086: how-to text
  - T102: hide imported
- **Owner-only prerequisites** (plan "Open items"):
  - Apple Developer enrolment and the ASC API key secrets (before T039)
  - a public repository (before relying on free macOS CI)
  - the `<user>.github.io` host (before T103–T105 go live)
