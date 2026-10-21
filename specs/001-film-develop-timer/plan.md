# Implementation Plan: Film Development Timer (Develop mode)

**Branch**: no feature branch. Spec-kit resolves the feature as
`001-film-develop-timer` from `.specify/feature.json`. Git is on
`devdata-dataset`.
**Date**: 2026-10-21
**Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-film-develop-timer/spec.md`
(4 clarifications). The visual design is in `design/develop/` (Claude Design
snapshot; see its README).

## Summary

Build Develop mode of drktimes as a Flutter app for iOS (released first) and
Android. The app has four parts:

1. **Lookup.** A combination lookup over the bundled CC0 manufacturer dataset.
2. **User recipes.** A user-recipe layer, with notes, processes, favourites
   and sessions, stored locally.
3. **Guided sessions.** A guided multi-step development session for up to
   three tanks, with a metronome and sound cues.
4. **Sharing without a server.** Sharing by link or file, plus full backup.

**Technical approach:**

- **Timing is pure Dart and deterministic.** All timing comes from a
  timeline engine: wall-clock anchors and `stateAt(now)`. This makes it
  accurate, resumable after the app is killed, testable on Linux, and the
  single source for both foreground audio and background notifications.
- **Two separate data stores.** User data lives in drift/SQLite. The dataset
  stays as validated JSON loaded into memory.
- **Platform code stays small.** It is limited to:
  - a low-latency sample player
  - local notifications for background cues on iOS
  - an Android foreground service
  - an Android volume-key channel
  - deep-link and file handlers
- **Risk first.** The riskiest piece, iOS background cues, is proven with a
  TestFlight spike before the session UI is built.

## Technical Context

**Language/Version**: Dart 3.13.3, Flutter 3.47.4 stable (the existing
project; SDK at `~/development/flutter`). Kotlin is used for the small
Android hooks.

**Primary Dependencies** (versions resolved with `flutter pub add` at
implementation time; see research.md):

| Need | Package |
|---|---|
| State and dependency injection | `flutter_riverpod` |
| Navigation and deep-link routes | `go_router` |
| Storage | `drift`, `drift_flutter` / `sqlite3_flutter_libs`, `path_provider` |
| Audio | `flutter_soloud`, `audio_session` |
| Background cues | `flutter_local_notifications`, `flutter_foreground_task` (Android) |
| Screen wake | `wakelock_plus` |
| Links and sharing | `app_links`, `share_plus`, `file_selector` |
| Utilities | `uuid`, `archive` (raw deflate), `crypto` (sha256), `http` (dataset manifest only) |
| Dev only | `build_runner`, `drift_dev` |

**Storage**:
- User data: SQLite via drift, in the app support directory.
- Datasheet dataset: a bundled JSON asset, optionally replaced by a verified
  download (FR-064).
- Font: JetBrains Mono, bundled as an asset.

**Testing**:
- `flutter test` for unit, drift (in-memory SQLite), widget and golden
  tests.
- `integration_test` on the Android emulator.
- Manual device checklists for background audio and notifications on
  TestFlight (see quickstart.md).

**Target Platform**:
- iOS 16+ (TestFlight, then the App Store). This version supports
  time-sensitive notifications.
- Android 8.0+ (API 26). This is for development and testing, and a later
  store release.
- The project's desktop and web scaffolds are not targets.

**Project Type**: mobile app (single Flutter project), plus a tiny static
site (`site/`) for the share landing page, the `.well-known` files and the
dataset manifest.

**Performance Goals**:
- Cue timing within ±1 s over a 30-minute session, including when the phone
  is locked (SC-003).
- Tick jitter below about 30 ms in the foreground. Measured in the R3 spike (T042) by logging scheduled vs. actual play times.
- Search results update within one frame, given ~250 searchable entries.
- Cold start to Develop home in under 1.5 s on a mid-range phone, including
  the dataset load.
- 60 fps on session screens.

**Constraints**:
- Fully offline (FR-063).
- No data collection (FR-072). The app makes only two network requests:
  - `GET <host>/dataset/manifest.json`, at most daily
  - `GET` of the dataset file it names, only when a newer version exists

  Neither carries identifiers.
- App Store safe:
  - no volume-key capture on iOS
  - no keep-alive with silent audio
- MIT licence for the code; the dataset stays CC0, and user content is kept
  separate.
- Owner's tooling:
  - develop on Linux with the Android emulator
  - iOS builds only on hosted macOS CI

**Scale/Scope**:
- One user per device.
- Data: about 3,700 datasheet rows, 172 films and 73 developers. User data is
  hundreds of recipes at most.
- About 30 screens or states (34 design artboards).
- Up to 3 concurrent sessions.

All unknowns are resolved in `research.md` (R1–R13). There are no
NEEDS CLARIFICATION items left.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Evaluated against **drktimes Constitution v1.0.1** (ratified 2026-10-21, amended 2026-10-21: Principle I display wording).

| Principle / section | Gate | Plan evidence | Result |
|---|---|---|---|
| **I. Licence-Clean Data** | The dataset contains allowed sources only, and user data stays separate | Two pools in data-model.md. The dataset is read-only in the app. `tool/build_dataset.dart` compiles from the validated `resources/devdata`. Updates must pass `validator.dart` (R8). User recipes are exported only in the exchange format, never in the dataset. On screen they share the combination list with datasheet times but always carry "Your recipe" or the sharer's name, never "Datasheet" (FR-017, test T075 for SC-013) | ✅ PASS |
| **II. Privacy by Default** | No collection; every network request listed; offline | No analytics or crash SDKs. Two listed GETs (Technical Context). Share payload in the URL fragment (contracts/links-and-files.md §1). Font bundled. SC-016 network check in quickstart K | ✅ PASS |
| **III. Darkroom-First Interaction** | Sound-only and screen-only; states not by hue alone; target sizes; no typing mid-run | Session states use the design's chip shape and numeral weight. Tanks are told apart by glyph and pitch. Next/Start use the 112 px design button, and primary session buttons are 72 px. Secondary controls (pause, ±30 s, abort) are 48 px: optional, and behind confirms. The only typing (the note) happens after Done. Golden tests in dark and light, plus a monochrome-filter pass. No in-app red theme in Part 1 (analysis S1); the red token values are kept for Print mode, so a safelight theme stays possible as the constitution requires | ✅ PASS |
| **IV. Timing Is Derived** | Wall-clock anchors, `stateAt(now)`, resume after kill, ±1 s | R1 timeline engine. StepRun anchors are persisted on every transition. One event list feeds the foreground player and the notifications (R2, R3). SC-003 simulated in unit tests | ✅ PASS |
| **V. Testable Core** | Pure-Dart domain with Linux tests; interfaces with fakes; manual checks written down | `lib/domain/` has no Flutter imports. contracts/platform-channels.md interfaces have fakes. quickstart §3–4 lists the device-only checks | ✅ PASS |
| **VI. Open, Store-Safe, Simple** | MIT; store policies; no server, accounts or paid services; versioned formats; complexity justified | No volume capture on iOS, no silent audio (R3, R11). Static site only. The exchange format is versioned and readers ignore unknown fields. Complexity Tracking filled in. **Watch item:** the Android foreground service type `mediaPlayback` must be checked against Play policy before any Play release (R3) | ✅ PASS (with watch item) |
| **Platform & Technology Constraints** | Flutter; iOS first through hosted CI; no recurring spend; static hosting; seconds and whole °C | R12 GitHub Actions on a public repo. GitHub Pages. Data model uses integer seconds and integer °C, with °F display only | ✅ PASS |
| **Workflow & Quality Gates** | Approved spec; design in `design/`; CI gates; risk-first spike | Spec is clarified. `design/develop/` has a README. `ci.yml` runs analyze, test and the dataset validator. R3 spike with exit criteria, blocking the session UI | ✅ PASS |

**Initial gate: PASS.**

**Post-design re-check (after Phase 1): PASS.**
- `data-model.md`, `contracts/` and `quickstart.md` add no network calls,
  no third-party services and no writes to the dataset.
- The only new item is the Play-policy watch item on the foreground service
  type. It is recorded in R3 and does not block iOS-first work.

## Project Structure

### Documentation (this feature)

```text
specs/001-film-develop-timer/
├── spec.md
├── plan.md              # this file
├── research.md          # Phase 0: R1–R13 decisions
├── data-model.md        # Phase 1: entities, state machine, derived logic
├── quickstart.md        # Phase 1: validation guide
├── contracts/
│   ├── exchange-format.schema.json   # share + backup document (FR-062)
│   ├── links-and-files.md            # link, file, landing page, dataset manifest
│   └── platform-channels.md          # cue scheduler, FGS, volume keys, wake, intake
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks; not created here)
```

### Source Code (repository root)

```text
lib/
├── main.dart                       # bootstrap: ProviderScope, dataset load, router
├── app/
│   ├── router.dart                 # go_router: /develop, /print, /combo, /pick/*, /session, /import, /settings…
│   └── theme/                      # tokens from design/develop/drk.css → ThemeData ×3 + ThemeExtension
├── devdata/                        # EXISTING: models, loader, validator (dataset schema v1)
├── domain/                         # pure Dart, no Flutter imports, the unit-test core
│   ├── combination_key.dart        # key, dilution + °F normalisation (FR-016, FR-073)
│   ├── amounts.dart                # FR-026
│   ├── temperature.dart            # compensation estimate (R7)
│   ├── search.dart                 # normalise + rank (R9)
│   ├── summary.dart                # median/range (FR-017)
│   ├── preselect.dart              # FR-071
│   ├── process.dart                # Process/Step/AgitationPattern/WashMethod + defaults
│   ├── timeline/                   # engine: compile step → events; stateAt(now); Clock
│   ├── sessions.dart               # multi-tank coordinator, Next routing, undo (FR-068–FR-070)
│   └── exchange/                   # codec, link encode/decode, import merge rules
├── data/
│   ├── db/                         # drift schema, DAOs, migrations
│   ├── repositories/               # recipes, notes, favourites, sessions, settings, user catalogue
│   └── dataset/                    # bundled load, catalog index, rebrand families, updater (R8)
├── platform/                       # interfaces + real impls + fakes
│   ├── cues/                       # CueScheduler: soloud foreground, notifications background
│   ├── foreground_service.dart     # Android FGS
│   ├── notification_permission.dart # NotificationPermission: iOS auth / Android 13+ POST_NOTIFICATIONS
│   ├── volume_keys.dart            # VolumeKeys: Android MethodChannel (R11), iOS no-op
│   ├── wake.dart                   # ScreenWake
│   └── intake.dart                 # Intake: app_links + file open → /import
└── features/
    ├── home/                       # modes, Favourites/Recent/Search, empty states
    ├── picker/                     # film → developer → ISO → dilution/temp, user-added entries
    ├── combination/                # page, times list, notes, chemistry, estimate, rebrand section
    ├── recipe_editor/
    ├── process_editor/
    ├── session/                    # single + multi-tank screens, all states, Done + note
    ├── sharing/                    # share sheet, import preview, backup import/export
    ├── settings/
    └── print/                      # "coming later" placeholder

assets/
├── devdata.json                    # compiled dataset (tool/build_dataset.dart), + version/sha
├── fonts/JetBrainsMono-*.ttf       # OFL, with licence file
└── sounds/                         # cue_{agitate,tick,pip,dump}_t{1,2,3}.{ogg,caf}

android/app/src/main/kotlin/…/MainActivity.kt   # volume-key hook (R11)
android/app/src/main/AndroidManifest.xml        # FGS mediaPlayback, intent filters, app links
ios/Runner/Info.plist                           # UTI/document types, associated domains
ios/Runner/Runner.entitlements                  # associated domains, time-sensitive notifications

site/                                # static GitHub Pages content (R6, R8)
├── r/index.html                     # landing page + fragment decoder
├── .well-known/{apple-app-site-association,assetlinks.json}
└── dataset/manifest.json

tool/
├── validate_devdata.dart            # EXISTING
├── fetch_source.sh                  # EXISTING
├── build_dataset.dart               # NEW: compile resources/devdata → assets/devdata.json
└── make_cue_sounds.*                # NEW: render per-tank cue samples (one-off, outputs committed)

.github/workflows/
├── ci.yml                           # analyze + flutter test (+ dataset gate) on ubuntu
└── ios-testflight.yml               # macos: build ipa → TestFlight (R12)

test/                                # mirrors lib/: domain/, data/, platform/ (fakes), features/ (widget + golden)
integration_test/                    # Android emulator end-to-end flows A–K (quickstart)
```

**Structure decision**:
- **A single Flutter project, layered.** `domain` holds pure logic, `data`
  holds storage and the dataset, `platform` holds native boundaries behind
  interfaces, and `features` holds the UI.
- **The existing `lib/devdata` stays as is** and is reused for both bundled
  loading and validating updates.
- **The `site/` folder** is deployed separately to the GitHub user site
  chosen by the owner.

## Risk-first order (input for `/speckit-tasks`)

1. **Foundations.** Dependencies, theme tokens and font, the compiled dataset
   asset, the drift schema v1, and the CI that runs `flutter test` on
   ubuntu.
2. **Timeline engine and session coordinator.** Pure Dart, fully
   unit-tested, including multi-tank, and covering SC-003 in simulation.
3. **Spike R3 (blocking).** Cue scheduler, notifications, Android foreground
   service, the TestFlight workflow, and a throwaway "15-minute step" screen.
   Run the device checks in quickstart §3.1–3.2. If the iOS exit criteria
   fail, stop and revisit R3 with the owner before building the session UI.
4. **US1: session UI** (one tank, then multi-tank), with a manually entered
   time.
5. **US2: lookup.** Search, picker, combination page, amounts, estimate,
   rebrands.
6. **US3 and US4.** Recipes and notes, and the process editor.
7. **US5.** Favourites, Recent, mode memory, resume.
8. **US6 and US7.** Exchange codec, share and import, `site/`, and backup.
9. **Dataset updater** (FR-064). Polish the five design gaps listed in
   `design/develop/README.md`, then run the full quickstart pass.

## Open items for the owner (they don't block planning)

- **Share host.** Create the `<user>.github.io` repository, or buy a domain,
  before the first public release (research R6).
- **Public repository.** Make the GitHub repository public, so macOS CI
  minutes are free (research R12).
- **Apple setup.** Enrol in the Apple Developer Program and create an App
  Store Connect API key, needed for TestFlight.
- **App identity.** Confirm the bundle ID/package (placeholder:
  `am.drktimes`).

## Complexity Tracking

No constitution violations. The entries below are justified complexity under Principle VI.

| Notable complexity | Why it's needed | Simpler alternative rejected because |
|---|---|---|
| Two background mechanisms (iOS notifications, Android foreground service) | FR-048 within each platform's rules | One cross-platform mechanism can't both satisfy App Store rules and keep ticks on Android |
| Per-tank pre-rendered sound sets | FR-069: tanks told apart by ear | Real-time pitch shifting adds latency and differs between platforms |
| Static `site/` alongside the app | Links must open the app or explain it (FR-056); dataset updates (FR-064) | A custom URL scheme isn't tappable in messengers; app-release-only data updates are slow |
