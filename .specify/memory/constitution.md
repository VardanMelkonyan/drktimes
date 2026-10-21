# drktimes Constitution

## Core Principles

### I. Licence-Clean Data (NON-NEGOTIABLE)

- The bundled development-time dataset (`resources/devdata`) MUST contain only facts from allowed
  sources:
  - manufacturer datasheets
  - developer-maker datasheets
  - distributor sheets for their own products
  - packaging inserts
  - written permission
  - our own tests
  - CC0-dedicated contributions
- Each row MUST cite its source and page.
- The dataset is published under CC0 1.0. Forbidden sources (Massive Dev Chart / digitaltruth,
  commercial compilations, forums, blogs, Scribd, Wikipedia text) MUST never be used, not even
  as a cross-check that ends up copied.
- User-generated recipes and notes MUST be stored and exported separately from the dataset, and
  MUST never be merged into it.
- Wherever user-generated times are displayed, including in the same list as datasheet times,
  each MUST carry a distinct source label ("Your recipe", or the sharer's name) and MUST never be
  presented as datasheet data.
- Every change to the dataset MUST pass the dataset validator (`tool/validate_devdata.dart`) and
  the dataset gate test.
- Downloaded dataset updates MUST pass the same validator before replacing the current data.

Rationale: the dataset is the project's public asset. A single tainted row puts the whole CC0
release at risk.

### II. Privacy by Default

- The app MUST NOT collect or transmit usage, analytics, crash or personal data, and MUST NOT
  embed SDKs that do.
- All user data stays on the device unless the user explicitly shares or exports it.
- Every network request MUST be listed in the feature plan and MUST carry no user identifiers.
  Today the only one is the dataset manifest check.
- Shared content travels only where the user sends it. Recipe links keep their payload in the
  URL fragment, so no server receives it.
- Every core flow (lookup, recipes, sessions) MUST work fully offline.

Rationale: a darkroom tool has no reason to know who you are. "Data Not Collected" is a
product promise.

### III. Darkroom-First Interaction

The interface MUST serve someone with wet or gloved hands whose eyes are on the tank:

- **Sound only.** A guided session MUST be completable by sound alone.
- **Screen only.** It MUST equally be completable by screen alone.
- **State is never hue alone.** Session states MUST be distinguishable by shape, line, weight
  or label, never by colour hue alone.
- **Tank identity, too.** The same holds for each tank's identity.
- **Usable with wet hands.** Primary session controls MUST be at least 72 px, and Next/Start at
  least 112 px.
- **No typing mid-run.** No step between Start and Done may require typing or a precise tap.
- **Form follows function.** Every element on screen MUST exist because the process needs it.
  The design source is `design/`.
- **Safelight-ready.** Visual tokens MUST keep a safelight-red theme possible, with green and
  blue at 0.

Rationale: in a bathroom darkroom, a UI that needs precise looking or tapping is a ruined roll.

### IV. Timing Is Derived, Never Counted

- All session timing MUST be computed from persisted wall-clock anchors: a pure function of
  "now" plus the recorded starts, pauses and adjustments. It MUST never come from accumulated
  timer ticks.
- Timing MUST stay correct when the phone locks, the app goes to the background, or the system
  kills the app, and a reopened app MUST resume each session at its true point.
- Foreground sounds, background notifications and the screen MUST all be driven by the same
  computed timeline.
- Accuracy target: every step ends within ±1 s of its plan over a 30-minute session.

Rationale: a timer that drifts or forgets is worse than the phone's stock timer it replaces.

### V. Testable Core

- Domain logic MUST be pure Dart with no Flutter or platform imports, and MUST have unit tests
  that run on Linux. Domain logic covers:
  - the timeline
  - combination keys and normalisation
  - amounts
  - preselection
  - search
  - import merging
  - the exchange codec
  - temperature estimates
- Native boundaries (audio, notifications, foreground service, volume keys, wake lock,
  link/file intake) MUST sit behind Dart interfaces with test fakes.
- A change to logic MUST come with tests that would fail without it.
- Behaviour that can only be verified on a device MUST have a written manual check in the
  feature's quickstart.

Rationale: the maintainer develops on Linux and can test iOS only through TestFlight. Whatever
can be proven on Linux must be.

### VI. Open, Store-Safe, and Simple

- Application code is open source under MIT.
- Features MUST comply with App Store and Play policies, with no workaround that risks
  rejection:
  - no repurposed iOS volume buttons
  - no silent-audio keep-alive
  - no private APIs
- Features MUST NOT introduce a server, accounts or a paid third-party service unless a spec
  explicitly justifies it.
- Persisted and shared formats (the exchange format, the combination key) are public contracts.
  They MUST be versioned, readers MUST ignore unknown fields, and breaking changes need a new
  major format version with a migration path.
- Prefer the simplest design that meets the spec. Added complexity MUST be justified in the
  plan's Complexity Tracking table.

Rationale: an open, free, community-minded tool survives only if it stays cheap to run, easy
to contribute to, and acceptable to the stores.

## Platform & Technology Constraints

- **Stack**: Flutter/Dart (the SDK version is recorded in each plan) with small Kotlin/Swift
  hooks only where a platform requires them.
- **Targets**:
  - iOS is the first release target (TestFlight, then the App Store).
  - Android is the development and test target, with a store release undecided.
  - Desktop and web scaffolds are not targets.
- **Builds**: iOS builds and TestFlight uploads run on hosted macOS CI. No step may require a
  local Mac.
- **Costs**: no recurring spend beyond the Apple Developer Program without the owner's explicit
  approval.
- **Hosting**: static only (GitHub Pages or an owner-chosen domain), for the share landing page,
  `.well-known` files and dataset manifests.
- **Units**: times are stored in seconds and temperatures in whole °C. °F is a display unit
  only.

## Development Workflow & Quality Gates

- **The Spec Kit flow runs in order**:
  1. `/speckit-specify`
  2. `/speckit-clarify`
  3. `/speckit-plan`
  4. `/speckit-tasks`
  5. `/speckit-implement`

  The owner approves each spec before planning, and each plan's Constitution Check MUST pass,
  or record a justified exception, before tasks are generated.
- **Visual design comes first** for user-facing features. It is kept in `design/` with a README
  noting its source and any gaps against the spec.
- **CI gates on every push**:
  - `flutter analyze` is clean
  - `flutter test` passes
  - the dataset validator passes

  Nothing merges to `main` with a failing gate.
- **Risk first.** The riskiest unknown in a plan (e.g. background cues on iOS) is proven by a
  spike with written exit criteria before dependent UI is built.
- **Commits** are small and descriptive, and git history is not rewritten on shared branches.

## Governance

- This constitution supersedes conflicting practice in this repository.
- Amendments are made by changing this file in a commit that does three things:
  - includes a Sync Impact Report
  - bumps the version
  - updates any affected templates or active plans
- **Versioning** follows semantic versioning:
  - **MAJOR**: a principle is removed or redefined incompatibly.
  - **MINOR**: a principle or section is added, or guidance is materially expanded.
  - **PATCH**: clarifications and wording.
- **Compliance** is checked in every plan's Constitution Check, and again in code review of each
  implementation change.
- Runtime guidance for a feature lives in its `specs/<feature>/` documents and in
  `resources/devdata/README.md` (data sourcing policy).

**Version**: 1.0.1 | **Ratified**: 2026-10-21 | **Last Amended**: 2026-10-21
