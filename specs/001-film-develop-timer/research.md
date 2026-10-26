# Research: Film Development Timer (Develop mode)

Phase 0 of `/speckit-plan`. Each entry settles one open question from the
plan's Technical Context. The format is **Decision**, **Rationale**,
**Alternatives considered**.

Package versions are deliberately not pinned here. They are resolved with
`flutter pub add` at implementation time against Flutter 3.47.4 / Dart 3.13.3
(the SDK installed in `~/development/flutter`), and recorded in
`pubspec.lock`.

---

## R1. Session timing engine

**Decision**: A pure-Dart, deterministic **timeline** model.
- Starting a step compiles it into a list of timed events: agitation burst
  start/end, the times of each inversion tick, the last-10 s window, and step
  end.
- The session stores **anchors**: the wall-clock time each step started, plus
  any pause intervals and ±30 s adjustments.
- The current state is a pure function `stateAt(now)`.
- A `Clock` abstraction is injected, so tests run a 30-minute session in
  microseconds.
- The UI re-renders from a ticker. It never counts time by accumulating ticks.

**Rationale**:
- This is what makes SC-003 (±1 s over 30 minutes, phone locked) achievable.
  Nothing drifts because nothing accumulates.
- After the app is killed and relaunched (FR-003, FR-048), the session is
  rebuilt from persisted anchors, so resuming is exact.
- Multi-tank (FR-068) is just N independent timelines.
- Background notifications (R3) are scheduled from the same event list, so
  the foreground and background cues can never disagree.

**Alternatives considered**:
- `Timer.periodic` countdowns: drift, and they die with the isolate.
- A native timer per platform: duplicated logic, and hard to test on Linux.

## R2. Foreground audio cues and the metronome

**Decision**:
- Use a low-latency sample player, **`flutter_soloud`**, with sounds
  preloaded at session start.
- Six cue types: agitate-start chime, inversion tick (turn over) and tock
  (bring back, half a pace later), 3-2-1 countdown pip, last-10 s pip, and
  dump-&-pour chime (FR-039). Tock and countdown are foreground-only, like
  ticks. (Tock and countdown added 2026-10-26.)
- **Per-tank sound identity** (FR-069) comes from three pre-rendered sample
  sets, each at a different pitch: tank 1 low, tank 2 mid, tank 3 high. They
  are generated once, offline, as short WAV/OGG assets.
- Cues are played by a scheduler that reads the timeline (R1) and fires each
  event when its time arrives (look-ahead about 50 ms).
- The audio session uses the **playback category** (via `audio_session`) so
  cues play when the iOS silent switch is on. The spec asks for "as reliably
  as the platform allows".
- Cues **mix with** other audio rather than stopping it, so a podcast keeps
  playing under the ticks.

**Rationale**:
- A metronome needs tight timing. Players that open a platform media player
  per sound have tens of milliseconds of jitter, which you can hear in a
  2-second tick.
- Pre-rendered pitches avoid real-time pitch shifting and sound identical on
  both platforms.

**Alternatives considered**:
- `audioplayers` / `just_audio`: built for media playback, not sample
  triggering; higher latency.
- Synthesising tones at runtime: more code, and no real benefit over three
  small asset sets.

## R3. Cues while locked, backgrounded, or killed (highest risk)

**Decision**: a layered approach. Each layer is proven by an early spike
(see `plan.md`, "Risk-first order").

1. **Primary path: the screen stays on.**
   - The screen is held awake for the whole session (FR-037) with
     **`wakelock_plus`**.
   - In normal use the app is in the foreground and R2 plays every cue,
     including ticks.
2. **The phone is locked or the app is backgrounded (iOS).**
   - When the app goes to the background, each remaining *attention* cue
     (agitate-start, last-10 s, dump-&-pour) is scheduled as a **local
     notification** with a bundled custom sound and **time-sensitive**
     interruption level, using `flutter_local_notifications`.
   - iOS allows 64 pending notifications per app. The scheduler keeps a
     rolling window of the next ≤ 60 cue events across all tanks and tops it
     up whenever the app runs.
   - Per-inversion **ticks are not delivered in the background on iOS**.
     The agitate-start notification text says how long and at what pace
     ("Tank 1 · Agitate 10 s · 5 inversions"). This limitation is shown once
     to the user (spec edge case).
   - On returning to the foreground, the pending notifications are cancelled
     and R2 takes over again.
   - No background-audio mode trick (playing silence to stay alive). That is
     an App Store rejection risk, and the constraint list explicitly rules it
     out.
3. **Android.**
   - A **foreground service** keeps the cue scheduler alive while a session
     runs, with an ongoing notification that shows each tank's state. It
     uses `flutter_foreground_task` or a small Kotlin service; the spike
     decides.
   - With the service running, full audio, ticks included, continues when
     the screen is locked.
   - The service type is `mediaPlayback`, because the user hears metronome
     audio throughout.
   - `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` are not needed.
   - **Play-policy watch item** (Constitution VI): before any Google Play
     release, confirm that `mediaPlayback` is acceptable for a metronome
     whose rest periods are silent. If not, switch to `specialUse` with the
     declared justification "darkroom process timer with audible cues".
     This doesn't affect iOS-first work or sideloaded/emulator testing.
4. **The app is killed.**
   - On iOS, the notifications already scheduled still fire.
   - On Android, the foreground service survives in most cases. If the system
     kills it, already-scheduled exact notifications fire as a fallback.
   - Relaunching rebuilds the session from persisted anchors (R1).

**Rationale**:
- This meets FR-048 within App Store rules. The interface the user relies on
  most (the screen stays on, with sound) is the fully featured one.
- The background layers degrade gracefully and honestly.

**Alternatives considered**:
- *iOS `UIBackgroundModes: audio` with a continuous audio stream*:
  rejected. The rest periods are silent, and keeping the session alive with
  silent audio is a known rejection cause.
- *Live Activities / Dynamic Island countdown*: a nice later addition for
  glanceability. It can't play sound, so it doesn't solve cues. Deferred.
- *Push from a server*: there is no server (constraint).

**Spike exit criteria** (must pass before session UI work):
- On a TestFlight build, with the phone locked through a 15-minute fake
  developer step, every agitate-start and dump cue arrives within ±1 s,
  including with the silent switch on and with Focus enabled.
- On the Android emulator and on a real device, with the screen off, every
  tick plays.

## R4. Local storage

**Decision**:
- **`drift`** (SQLite) for all user data: recipes, notes, user films and
  developers, favourites, sessions, settings, processes, hidden imports.
- The bundled dataset stays as JSON assets parsed by the existing
  `lib/devdata` loader into an in-memory index at startup (~3,700 rows,
  fast).
- The schema is versioned, with explicit migrations and a migration test per
  version (FR-065).

**Rationale**:
- The data is relational (combinations ↔ recipes ↔ notes ↔ sessions) and
  needs transactional imports (FR-057, FR-061).
- drift runs in plain Dart tests on Linux through `sqlite3`, so the storage
  logic is testable without a device.
- It has typed queries and migration tooling.

**Alternatives considered**:
- `isar` / `hive`: weaker migration and relational stories, and their
  maintenance has been uneven.
- JSON files: no transactions, and merging becomes hand-rolled.
- `shared_preferences`: only for trivial keys. Even settings live in drift,
  so backup has one source.

## R5. Exchange format (share and backup)

**Decision**: one versioned JSON document format, **`drktimes-exchange`**,
used both for a single shared recipe and for a full backup (FR-062). The
schema is in `contracts/exchange-format.schema.json`.

- **File:** a `.drktimes` file (UTF-8 JSON). The iOS document type is a
  custom UTI, `am.drktimes.exchange`, conforming to `public.json`. On Android
  it's an intent filter on that extension or MIME type.
- **Link:** `https://<host>/r#<payload>`. The payload is the single-recipe
  document, compressed with deflate and then base64url-encoded, and it sits
  in the URL **fragment**.
  - The fragment is never sent to any server (consistent with FR-072).
  - A typical recipe with notes is about 600–1,500 characters, well within
    the URL length that messengers keep intact.
  - Beyond about 6,000 characters (a very long note history), Share offers
    only the file.
- Identity uses **UUIDv4** recipe IDs plus an integer `version` and an
  `updated_at` timestamp. On import, "newer" means a higher `version`; if
  versions are equal, the later `updated_at` wins.

**Rationale**:
- A single format means backup import and recipe import are the same code
  path. The future community catalogue (spec §11) can accept the same
  documents unchanged.
- A link needs no server and no domain beyond static hosting.

**Alternatives considered**:
- A protobuf/binary format: smaller, but opaque to contributors of an
  open-source project.
- Separate backup and share formats: two merge paths to keep correct.

## R6. Deep links and the landing page

**Decision**:
- Host a small static site (`site/` folder in this repo) on **GitHub Pages**
  (owner's call: the GitHub Pages address until a domain is bought). It
  contains:
  - `r/index.html`: the landing page. Client-side JS decodes the fragment and
    shows the recipe preview, plus "Get drktimes" (App Store / TestFlight
    link) (FR-056).
  - `.well-known/apple-app-site-association` for **Universal Links**
    (path `/r*`).
  - `.well-known/assetlinks.json` for Android **App Links**.
  - `dataset/manifest.json` and dataset bundles (R8).
- Both `.well-known` files must sit at the **domain root**. The host is
  therefore a GitHub *user* site (`<user>.github.io`, repo
  `<user>.github.io`) or a custom domain. A *project* site
  (`<user>.github.io/drktimes`) can't serve root files.
- The app handles incoming links with **`app_links`**, and receives files
  through the platform "open in" handlers.

**Rationale**:
- Universal Links and App Links make a shared link open the app directly
  when it's installed, and the landing page when it isn't.
- Custom URL schemes (`drktimes://`) aren't tappable in most messengers.

**Open item (owner)**:
- Create the `<user>.github.io` repository, or buy a domain, before the
  first public release.
- The host string is a single constant in code plus the two `.well-known`
  files.
- Until then, sharing by file works fully, and links work wherever the app
  is installed.

**Alternatives considered**:
- Firebase Dynamic Links: shut down, and would add a third-party service.
- Branch.io: a third party, against FR-072.

## R7. Temperature compensation (FR-014)

**Decision**:
- Use the standard exponential time/temperature relationship
  `t₂ = t₁ · e^(−k·(T₂ − T₁))` with **k = 0.081 per °C**. That is about 8%
  shorter per +1 °C, matching the published Ilford and Kodak
  time/temperature charts for typical black-and-white developers.
- The estimate is offered only between **18 °C and 26 °C**.
- It is always labelled "estimate" and rounded to the nearest 15 s.
- The source is cited in the in-app info sheet and in `docs/`: Ilford's
  published time/temperature compensation chart, and Kodak's equivalent
  guidance. Only the relationship is used (a fact, not copied content).

**Rationale**:
- The curve is simple, well known, and close to the manufacturer charts
  across the normal range.
- Limiting the range avoids extrapolating where developers behave
  differently.

**Alternatives considered**:
- Per-developer curves: no licence-clean data source.
- A linear rule ("10% per degree"): drifts from the charts at the ends of
  the range.

## R8. Dataset updates (FR-064)

**Decision**:
- Bundle a **compiled dataset** asset: one minified JSON file built from
  `resources/devdata` by a `tool/` script, with a `dataset_version` and its
  SHA-256.
- When online, at most once a day and off the session path, fetch
  `https://<host>/dataset/manifest.json`. It contains `dataset_version`, a
  URL, `sha256` and `min_app_version`.
- If the version is newer and the app is compatible, download it, verify the
  SHA-256, validate it with the existing `lib/devdata/validator.dart`, and
  then swap it in atomically (it's stored in app support storage). Any
  failure keeps the current dataset.
- The request carries no identifiers, no query string and no custom headers
  (FR-072).

**Rationale**:
- This reuses the validator already in the repo, and serves static files
  only.
- Verifying the SHA-256 and validating before the swap means a bad update
  can never break lookups.

**Alternatives considered**:
- Updates only through app releases: simpler, but App Store review latency
  for data fixes.

## R9. Search (FR-005, SC-012)

**Decision**:
- An in-memory index over films and developers (catalogue plus user-added).
- **Normalisation:** lowercase, strip diacritics, and remove spaces,
  hyphens, dots and `+` signs. For example "Tri-X" becomes `trix`, "HP5+"
  becomes `hp5`, and "R09" becomes `r09`.
- **Indexed text:** brand, name, brand+name and aliases.
- **Ranking:**
  1. exact match
  2. prefix match
  3. word-prefix match
  4. substring match

  Ties are broken by catalogue status (current before discontinued) and then
  alphabetically.
- A small curated synonym list (`rodinal` → Rodinal-formula developers) is
  kept in data, not code.

**Rationale**:
- The catalogue is small (172 films and 73 developers), so a linear scan is
  instant.
- The normalisation rules cover every SC-012 example.

**Alternatives considered**:
- Fuzzy matching (Levenshtein): adds noise, and isn't needed for these
  queries.
- SQLite FTS: overkill for in-memory data.

## R10. State management, navigation, theming

**Decision**:
- **`flutter_riverpod`** for state and dependency injection. It overrides
  `Clock`, repositories and platform services in tests.
- **`go_router`** for navigation and deep-link routes.
- A theme built from the design tokens in `design/develop/drk.css`:
  - two `ThemeData` variants: dark (default) and light
  - **no in-app red theme in Part 1** (owner's decision, analysis S1). A safelight-red look is achieved with the system colour filter. On iOS that is Accessibility → Colour Filters → Colour Tint, red at full intensity, plus Reduce White Point. Android has no standard built-in red filter; that is decided with Print mode (Part 2). The red token values from the design are kept as a reference for that decision
  - a custom `ThemeExtension` for session-state and tank tokens
  - **JetBrains Mono** bundled as an asset (OFL licence, file included in
    the repo), not fetched at runtime (offline, FR-063)
- Riverpod and go_router are mainstream, well documented, and testable.

**Rationale**:
- Bundling the font keeps the app offline and private.
- A `ThemeExtension` maps the design's tokens one-to-one.

**Alternatives considered**:
- `provider` / `ChangeNotifier`: workable, but weaker test overrides.
- `bloc`: more ceremony than this app needs.

## R11. Android volume-button Next (FR-043)

**Decision**:
- A small Kotlin hook in `MainActivity.onKeyDown` for `KEYCODE_VOLUME_UP`
  and `KEYCODE_VOLUME_DOWN`.
- It forwards the press over a `MethodChannel` and consumes it (so the volume
  doesn't change) **only while a session is waiting for Next and the setting
  is on**.
- iOS has no implementation (App Store guideline 2.5.9).

**Rationale**: about 20 lines, and no dependency.

**Alternatives considered**: volume-listener plugins can't consume the key
press, so the system volume would still change.

## R12. iOS build and distribution without a current Mac

**Decision**:
- **GitHub Actions on `macos-latest`** runs `flutter build ipa` and uploads
  to TestFlight with an **App Store Connect API key** (stored in repo
  secrets). It triggers on tags `v*` or manually.
- Code signing uses an App Store Connect API key with automatic signing.
  Provisioning is fetched at build time; `fastlane match` is an alternative
  if automatic signing proves flaky.
- macOS runner minutes are free for **public** repositories. The repository
  needs to be public on GitHub (open source, MIT) before this is cost-free.

**Rationale**: it meets the owner's constraint (old Mac, no extra spend
beyond the Apple Developer Program).

**Alternatives considered**:
- Codemagic free tier: viable fallback, with a limit on build minutes.
- A rented Mac: costs money.

## R13. Testing strategy

**Decision**:
- **Unit tests** (plain `flutter test`, run on Linux) for all pure logic:
  - the timeline engine with a fake clock, including SC-003 accuracy and
    multi-tank interleaving
  - dilution parsing and amounts
  - combination key and temperature rounding
  - preselection order (FR-071)
  - median and range summary
  - merge and import rules
  - exchange encode/decode round trips
  - search ranking (SC-012)
  - temperature compensation
- **drift tests** against in-memory SQLite: repositories, imports and
  migrations.
- **Widget tests** for each screen state against the design artboards
  (states, labels, tank naming). There are golden tests for the session
  states in each theme.
- **`integration_test`** on the Android emulator for end-to-end flows. These
  are the quickstart scenarios.
- **Manual device checklists** for what can't be automated: the background
  cue spike (R3), silent switch, Focus, and sound-only / screen-only runs
  (SC-004, SC-005, SC-006).

**Rationale**:
- Almost all of the risk-bearing logic is pure Dart and testable on the
  owner's Linux machine.
- Only platform audio and notifications need devices.
