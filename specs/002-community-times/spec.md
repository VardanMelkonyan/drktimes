# Feature Specification: Community Times (user-submitted dataset)

**Feature Branch**: none created (spec directory `002-community-times`; work continues on `devdata-dataset`)

**Created**: 2026-10-25

**Status**: Draft, awaiting the owner's review

**Input**: User description: "User-submitted dataset: an opt-in Settings toggle that shares the times a user actually developed with, automatically and without accounts, so everyone gets them as clearly labelled community times with automatic confirmations. Sources are configurable; the app stays standalone; no server of the owner's own."

## Context

The curated dataset (`resources/devdata`, CC0, every row cited to a datasheet page) can never cover every film and developer combination people really use. Today a hobbyist who has worked out a good time for a combination the dataset lacks can keep it only as a private recipe or send it to a friend (spec 001, US6).

This feature lets that knowledge reach everyone. A user switches on **Share my times** once. From then on, times they have actually used to develop a roll are contributed to a shared community pool, with nothing else to do. Everyone then sees those times in the app, clearly labelled as community times with a count of how many independent users back them.

**Design stance**: the curated dataset stays small, sourced and trustworthy. Community times are a separate, honestly labelled layer. They are never merged into it, never presented as datasheet data, and never required: the app is fully usable with no community source configured.

**Constitution impact** (this spec needs the owner's explicit approval of these, per the constitution's own rules):

- **Principle VI** forbids a server or third-party service unless a spec justifies it. Justification: shared submissions with automatic confirmation cannot work from static files alone, because a static host cannot receive writes, and a user-account-free design rules out writing through GitHub. A free, hosted database with write-only public access is the lightest thing that works, and it costs the owner nothing to run. Sources stay swappable so the choice is not locked in (FR-013).
- **Principle II** requires that every network request carry no user identifier and that all user data stays on the device unless the user explicitly shares it. Sharing here is explicit (an off-by-default switch with a plain consent text), but the confirmation mechanism needs some way to stop one install counting twice. Decided (Clarifications, 2026-10-25): a random, resettable, device-only contribution ID (FR-007). The constitution's Principle II and FR-072 of spec 001 must be amended to allow exactly that identifier and to list the new requests.
- **Principle I** is preserved: community times live in a separate store and a separate display layer and never enter `resources/devdata`.

## Clarifications

### Session 2026-10-25

- Q: How should the app recognise that two submissions come from the same install, given Principle II's "no user identifiers" rule? → A: A random per-install ID, stored only on the device and resettable by the user in Settings. Principle II is amended to allow exactly this identifier.
- Q: Should a community time be shown as soon as one install submits it, or only once two or more agree? → A: Only once two or more independent installs agree within the similarity window. Single submissions stay hidden until a second install confirms them.
- Q: When someone turns on Share my times, should past sessions be submitted too? → A: Yes. On switch-on the app automatically submits all eligible past sessions as well (same eligibility as any session, FR-005, FR-006), and the consent text says so.
- Q: When a combination has only community times, should Start preselect one? → A: Yes, the best-backed one. Since only entries with two or more installs are ever shown (previous answer), every visible community time already meets that bar.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Share my times without effort (Priority: P1)

A user has developed a roll with a combination that the dataset does not cover, using their own recipe. They want that time to be available to others without doing anything extra.

**Why this priority**: this is the contribution side, and without it nothing else has data. It must be effortless or nobody will do it.

**Independent Test**: turn the switch on, finish a session using an own recipe, and check that exactly one submission was made containing only the combination fields and time.

**Acceptance Scenarios**:

1. **Given** Share my times is off (the default), **When** the user completes sessions, **Then** the app makes no community network request at all.
2. **Given** the user opens the switch's settings row, **When** they read it, **Then** the text states plainly that turning it on releases the times they use, including eligible ones from past sessions, as CC0, anonymously, and that it can be turned off at any time (already-shared times cannot be recalled).
2a. **Given** the user has past completed sessions with their own recipes, **When** they turn the switch on, **Then** those eligible times are submitted automatically, once per combination and time.
3. **Given** the switch is on, **When** a session using the user's own recipe completes, **Then** the time is submitted automatically, with no prompt, screen or account.
4. **Given** the switch is on and the device is offline, **When** a session completes, **Then** the submission is kept and sent later once online, without the user doing anything.
5. **Given** the user turns the switch off, **When** later sessions complete, **Then** nothing is submitted, and anything queued but not yet sent is discarded.

---

### User Story 2 - See and trust community times (Priority: P1)

A user looks up a combination the dataset lacks and finds times other people used.

**Why this priority**: this is the payoff for everyone, including people who never share.

**Independent Test**: seed a source with community entries for a combination and check they appear on its page, labelled, with counts, below any curated times.

**Acceptance Scenarios**:

1. **Given** a combination has community times, **When** the user opens it, **Then** each is listed with a "Community" label, the name of its source, and how many independent installs back it (always two or more).
2. **Given** a combination has both datasheet and community times, **When** the page shows them, **Then** they are visibly distinct (label and grouping, not colour alone) and datasheet times come first.
3. **Given** a user has never turned on Share my times, **When** they open a combination, **Then** they still see community times (reading needs no opt-in).
4. **Given** a community time is chosen for Start, **When** the session starts, **Then** it behaves like any other time and is recorded in Recent with its source label.
5. **Given** the user can save a community time as their own recipe, **When** they do, **Then** it becomes a normal recipe that is not re-shared (see FR-005).

---

### User Story 3 - Automatic confirmation (Priority: P2)

Two independent users develop the same combination at similar times. The entry becomes more trustworthy without anyone voting.

**Why this priority**: it is what makes unmoderated community data worth trusting, but it works only once Stories 1 and 2 exist.

**Independent Test**: submit similar times for one combination from distinct install identities and check the count rises; submit repeatedly from one identity and check it does not.

**Acceptance Scenarios**:

1. **Given** an entry exists for a combination, **When** a different install submits a time within the similarity window, **Then** the entry's confirmation count rises by one.
2. **Given** an install already contributed to a combination, **When** it submits again, **Then** the count does not rise (its latest time replaces its earlier one).
3. **Given** a submitted time is far outside the similarity window of existing entries, **When** it arrives, **Then** it forms its own entry, hidden until a second install agrees with it, and is not merged into the others.
4. **Given** only one install has submitted a time for a combination, **When** any user opens that combination, **Then** that time is not shown to anyone.

---

### User Story 4 - Add or remove sources (Priority: P2)

A user, or a community, wants times from a different place than the project's default source.

**Why this priority**: the owner wants the design open and swappable. The default source is enough for launch, so this is not blocking.

**Independent Test**: add a source by its address, check its entries appear labelled with its name, then remove it and check they disappear.

**Acceptance Scenarios**:

1. **Given** Settings → Community sources, **When** the user adds a read-only feed address, **Then** its entries appear with that source's name.
2. **Given** a source that also accepts submissions, **When** Share my times is on, **Then** submissions go to the sources the user has chosen to share to (default: the project's source only).
3. **Given** the user removes every source, **When** they use the app, **Then** every other feature works exactly as before.
4. **Given** a source is unreachable or returns malformed data, **When** the app reads it, **Then** the app keeps working with whatever it already has and shows no error during a session.

---

### User Story 5 - The project keeps its source alive (Priority: P3)

The maintainer should not have to remember to keep the free hosted database running.

**Why this priority**: it protects availability rather than adding user capability.

**Independent Test**: confirm the scheduled job runs on its timetable and a skipped week is visible.

**Acceptance Scenarios**:

1. **Given** the project's community source is on a free tier that pauses when idle, **When** a week passes without traffic, **Then** a scheduled job has made a harmless request that counts as activity.

---

### Edge Cases

- A session is aborted: nothing is submitted.
- The user used an unmodified datasheet time, or a recipe received from someone else: nothing is submitted, because it is not the user's own to release (FR-005).
- A time is implausible (zero, negative, absurdly long, a temperature outside a darkroom range): it is rejected before sending and never queued.
- The combination uses a user-added film or developer not in the catalogue: it is not submitted, because the pool needs shared names (FR-006).
- Two sources return the same combination: both are shown, each under its own source label, never merged.
- A source removes an entry the app showed earlier: it disappears at the next refresh.
- The user switches sharing off while submissions are queued: the queue is discarded, not sent. Switching it on again submits the eligible history again, and the pool treats repeats from the same ID as replacements.
- Already-shared times cannot be recalled (no accounts, CC0 release); resetting the contribution ID does not remove them.
- The community source is down or paused: reads fall back to the last copy kept on the device; sharing queues.
- A user's own submitted time is not shown back to them as a community time until a second install agrees; they still have it as their own recipe.
- Timestamps and clock errors never make a submission invalid on their own.

## Requirements *(mandatory)*

### Functional Requirements

**Sharing**

- **FR-001**: Settings MUST have a **Share my times** switch, off by default. Its description MUST state that turning it on releases the times the user uses as CC0, anonymously, including eligible times from sessions they have already completed.
- **FR-002**: With the switch off, the app MUST NOT send anything to any community source.
- **FR-003**: With the switch on, when a session completes the app MUST submit the time automatically, with no account, prompt or other action by the user.
- **FR-003a**: When the switch is turned on, the app MUST also submit every eligible past session (same rules as FR-005 and FR-006), automatically and without a further prompt. Each distinct combination and time MUST be submitted once, not once per session.
- **FR-004**: A submission MUST contain only: film, developer, dilution, ISO, temperature (whole °C), time in seconds, and the contribution ID of FR-007. It MUST contain no name, notes, device data or location.
- **FR-005**: Only a time from the user's own recipe, from a completed session, MUST be submitted. Datasheet times, community times, and recipes received from others MUST NOT be.
- **FR-006**: Only catalogue films and developers MUST be submitted, so entries share names across users.
- **FR-007**: Each install MUST hold a random contribution ID, generated on first use of sharing, stored only on the device, and sent only with submissions. The pool MUST count each ID at most once per combination, and a repeat submission from the same ID MUST replace its earlier one. The ID MUST be derived from nothing about the user or device.
- **FR-007a**: Settings MUST let the user reset the contribution ID. After a reset the install counts as a new one, and its earlier submissions stay in the pool but can no longer be replaced.
- **FR-008**: A failed or offline submission MUST be retried later without user action, and MUST be dropped if the switch is turned off.
- **FR-009**: Implausible values MUST be rejected on the device before sending.

**Reading and display**

- **FR-010**: The app MUST read community times from every configured source, with no opt-in needed.
- **FR-011**: Each community time MUST show a "Community" label, its source's name and its confirmation count, and MUST be visually distinct from datasheet times by label and grouping, never by colour alone (constitution Principles I and III).
- **FR-012**: Community times MUST never be written into the bundled dataset or its exports, and MUST be stored apart from datasheet data and from the user's recipes.

**Sources**

- **FR-013**: A source is one of: a static read-only feed, or a hosted source that also accepts submissions. The app MUST reach every source through one small interface, so a source type can be replaced without changing the rest of the app.
- **FR-014**: Users MUST be able to add and remove sources in Settings. The project's source is the default and can be removed.
- **FR-015**: The app MUST work fully with no source configured and with no network.
- **FR-016**: Data from a source MUST be validated by the same rules as downloaded datasets (constitution Principle I) before it is shown, and anything failing validation MUST be ignored.
- **FR-017**: Entries from different sources MUST stay separate, each labelled by its source, and MUST NOT be merged.
- **FR-018**: Community data MUST be cached on the device so lookups work offline.

**Confirmation**

- **FR-019**: Entries MUST be confirmed automatically: submissions from distinct installs for the same combination within a similarity window MUST count toward one entry, and far-off times MUST form a separate entry.
- **FR-019a**: A community time MUST be shown only once at least two independent installs have submitted times within the similarity window of each other. A lone submission MUST stay hidden from every reader until a second install confirms it. The threshold (two) MUST be defined once and applied identically wherever visibility is decided.
- **FR-019b**: When a combination has no datasheet time and no time the user used before, the combination page MUST preselect the best-backed community time (highest count, ties broken by the most recent confirmation). This extends spec 001's preselection rule (last used, else datasheet time) with community time as the last fallback. A community time MUST never take precedence over a datasheet time or a time the user used before.
- **FR-020**: The similarity window MUST be defined once, documented, and applied identically wherever counts are computed.

**Operations and privacy**

- **FR-021**: The project's source MUST accept only submissions of the shape in FR-004, using a public key that cannot read private data, change or delete existing entries.
- **FR-022**: A scheduled job MUST make a harmless request to the project's source at least weekly so a free tier is not paused for inactivity.
- **FR-023**: Each network request this feature makes MUST be listed in the plan, with the exact fields sent, and Principle II and spec 001 FR-072 MUST be amended to allow them.
- **FR-024**: The App Store privacy answers MUST be reviewed before release, because sharing sends data off the device when enabled.
- **FR-025**: The maintainer MUST have a documented way to remove an abusive or wrong entry from the project's source.

### Key Entities

- **Community time**: a combination (film, developer, dilution, ISO, temperature) with a time, a confirmation count, and a source.
- **Submission**: one install's contribution of one time to one combination. Holds the FR-004 fields and nothing else.
- **Contribution ID**: a random, resettable, device-only marker that lets the pool count each install once (FR-007). It identifies no person or device.
- **Source**: a named place community times are read from, and possibly written to. Has a type, an address, and a name shown in the app.
- **Sharing setting**: the on/off switch plus the list of sources submissions go to.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Contributing takes zero extra steps. After switching sharing on once, completing a session submits its time with no further taps.
- **SC-002**: With sharing off, a network inspection of a full session shows zero community requests.
- **SC-003**: Every community time shown carries a visible label and count, and no community time is ever shown without one.
- **SC-004**: A user with no source and no network completes every flow of spec 001 unchanged.
- **SC-005**: A submission leaves the device with only the FR-004 fields, verified by a test of the exact payload.
- **SC-006**: Repeating a submission from one install changes a combination's confirmation count by zero.
- **SC-007**: A sharing queue built offline reaches the source within one minute of the device coming back online, with no user action.
- **SC-008**: A paused-prone free tier stays active: no week passes without the keep-alive run.
- **SC-009**: After a dataset gate run, `resources/devdata` is byte-identical whether or not community times exist.

## Assumptions

- "Actually used to develop a roll" means a completed session in Develop mode (spec 001). An aborted session submits nothing.
- Only the user's own recipe is submitted. Re-sharing datasheet or received times would add nothing or release material the user does not own. This is my guess; the owner can widen it.
- The similarity window is a few percent of the time, set once during planning from real data.
- The project's default source is a free hosted database with write-only public access; the owner needs no server of their own, and the plan must restate the free-tier limits.
- Moderation is after the fact and by the maintainer (FR-025). No community voting or reporting UI in v1.
- Users do not see who contributed any entry, and contributors cannot edit or withdraw a submission after the fact in v1, since there are no accounts.
- Android is the development target and iOS the release target, as in the constitution.
