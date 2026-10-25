# Quickstart: validating Develop mode

These are runnable checks that prove the feature works end to end. The
details live in `data-model.md` and `contracts/`. This guide only says what
to run and what you should see.

## Prerequisites

- The Flutter SDK at `~/development/flutter` (3.47.4 stable, Dart 3.13.3).
  Use `~/development/flutter/bin/flutter`, or add it to `PATH`.
- An Android SDK and an emulator. AVDs live in `~/.config/.android/avd`, so
  set `ANDROID_AVD_HOME` before running `flutter emulators`. Use JDK 21.
- For iOS: the GitHub Actions TestFlight workflow (research R12), and an
  iPhone with TestFlight installed.

```bash
cd ~/Work/drktimes
export PATH="$HOME/development/flutter/bin:$PATH"
export ANDROID_AVD_HOME="$HOME/.config/.android/avd"
flutter pub get
dart run tool/validate_devdata.dart          # dataset gate (existing)
dart run tool/build_dataset.dart             # compiles assets/devdata.json + version/sha
```

## 1. Automated checks (Linux, no device)

```bash
flutter analyze
flutter test                                 # unit + drift + widget + golden
```

What you should see:

- **Timeline engine:**
  - a simulated 30-minute default process ends each step within ±1 s of plan
    (SC-003)
  - pause, ±30 s and Undo behave as in the data-model state machine
  - two or three overlapping tanks never misroute Next (FR-070)
- **Search:** `trix`, `hp5`, `delta 400`, `R09` and `rodinal` each return
  the intended item in the top 3 (SC-012).
- **Amounts:**
  - Rodinal 1+50: 300 ml gives 5.9 + 294.1, and 500 ml gives 9.8 + 490.2
  - `1+1+5` at 300 ml gives 42.9 + 42.9 + 214.3
  - `stock` gives the full volume
- **Combination key and temperature:** 68 °F becomes 20 °C, 70 °F becomes
  21 °C, and `1:50` is stored as `1+50`.
- **Preselection** follows FR-071 in all four branches.
- **Exchange:**
  - encode → link → decode gives an identical document
  - importing the same recipe twice leaves exactly 1 copy (SC-009)
  - importing a newer version updates it, and an older version reports
    "up to date"
- **Backup:** export → wipe the database → import restores 100% of recipes,
  notes, favourites, sessions and settings. Importing again changes nothing
  (SC-010).
- **Migrations:** each schema version upgrades without data loss.
- **Golden tests:** every session state renders distinguishably in the dark
  and light themes, and through a monochrome colour filter. The chip shapes and numeral weights match
  `design/develop/Main.dc.html`.

## 2. Android emulator end-to-end

```bash
flutter emulators --launch <avd>
flutter test integration_test/               # scripted flows below
flutter run                                   # manual pass
```

| # | Flow | What you should see |
|---|---|---|
| A | Search `hp5` → HP5 Plus → ISO 400 → Ilfotec DD-X 1+4 → 20 °C | The combination page shows the datasheet time with its Ilford source and page, and amounts for 35mm and 120 (US2) |
| B | Tri-X 400 → Rodinal → ISO 400 → 1+50 → 20 °C | "No published time" → Add yours → save 13:00 with a note. The recipe appears on the page and survives an app restart (US3) |
| C | Start from B using the default process, with "wait for me" | Sequence: agitate 60 s → bursts every 60 s → final-10 pips → Dump & pour → Next → stop → fix → Ilford wash (5/10/20 with counted inversions) → wetting agent → Done. No timer input is needed between Start and Done (SC-007) |
| D | Run C, press Next, then Undo within 5 s | Returns to Dump & pour (US1 #6) |
| E | Start Tank 1, then Tank 2 4 minutes later, then try a fourth tank | Both tanks are labelled everywhere, with distinct sound pitches. A simultaneous wait routes Next to the tank waiting longest, and the fourth tank is blocked (FR-068–FR-070) |
| F | Lock the screen during C for 5 minutes | Ticks and cues continue (foreground service). On unlock the session is at the correct point |
| G | Kill the app from recents during C, then relaunch | The app returns to the live session at the correct time (FR-003) |
| H | Volume-down while awaiting Next (setting on), and then while not awaiting Next | The first acts as Next. The second changes the volume normally |
| I | Share the recipe from B → open the `.drktimes` file, and separately open the link, on a second emulator | Preview → Import. Importing again says "already up to date" |
| J | Airplane mode, then repeat A and C | Everything works (SC-011) |
| K | Network monitor (e.g. mitmproxy) over flows A–I | No requests except `GET /dataset/manifest.json`, with no identifiers, and none from spec 002 while sharing is off and no source is set (SC-016) |
| L | Android 13+: deny `POST_NOTIFICATIONS` at the first session start | Same as iOS check 5. The session runs, the banner shows, and the foreground cues and ticks play with the screen on |

## 3. iOS device (TestFlight build)

Push a `v*` tag, or run the "iOS TestFlight" workflow manually, then install
the build from TestFlight.

| # | Check | What you should see |
|---|---|---|
| 1 | **Background cue spike** (research R3, run first): lock the phone for the whole 15-minute developer step | Every agitate-start and dump cue arrives as a notification with a sound, within ±1 s. The one-time "ticks need the screen on" explanation was shown |
| 2 | Repeat 1 with the silent switch on and with a Focus mode active | Time-sensitive cues still alert. In the foreground, the cues still play with the silent switch on |
| 3 | Flows A–E and G–J from the Android table | Same results. Flow H doesn't apply, because volume keys are never captured on iOS |
| 4 | Tap a shared link in Messages | It opens the app's import preview through the Universal Link, once the host is configured |
| 5 | Refuse the notification prompt at the first session start, then lock the phone during a step | The session still runs. The "Background cues are off" banner shows, with an Open Settings button. Foreground cues work with the screen on. Settings shows "Notifications: off · Fix" |

## 4. Human checks (the success criteria that need people)

- **SC-002:** first lookup. Someone who has never used the app opens a fresh
  install and, timed with a stopwatch and with no help, finds HP5 Plus ·
  Ilfotec DD-X 1+4 · ISO 400 · 20 °C and presses Start. Pass: under 60 s for
  at least 4 of 5 people.
- **SC-008:** own recipe. Starting from the "No published time" page for
  Tri-X 400 · Rodinal 1+50 · ISO 400 · 20 °C, a tester adds 13:00 with a
  one-line note and saves. Pass: under 2 minutes for at least 4 of 5 people.
- **SC-004:** sound only. With the phone face down, complete flow C with zero
  missed agitations.
- **SC-005:** screen only. With sound off, complete flow C with zero missed
  agitations.
- **SC-006:** at 1 m, 9 out of 10 testers name the session state within 2 s.
  Include a colour-blind simulation (Android: Developer options → Simulate
  colour space), plus iOS Settings → Accessibility → Display & Text Size →
  Colour Filters → Colour Tint (red, full intensity).
- **SC-015:** two tanks, sound and screen together, with zero actions applied
  to the wrong tank.
- **SC-014:** the owner uses it for their own runs and compares it with their
  old routine.
