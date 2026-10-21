# Feature Specification: Film Development Timer (Develop mode)

**Feature Branch**: none created (spec directory `001-film-develop-timer`; work continues on `devdata-dataset`)

**Created**: 2026-10-21

**Status**: Draft

**Input**: User description: "Develop mode (Part 1 of drktimes): film development time lookup and guided development timer, as fully described in docs/superpowers/specs/2026-10-21-film-development-timer-design.md and the brainstorming conversation. Must capture every decision without omission."

**Source design**: [`docs/superpowers/specs/2026-10-21-film-development-timer-design.md`](../../docs/superpowers/specs/2026-10-21-film-development-timer-design.md) (approved by the owner on 2026-10-21). If this spec and the design ever disagree, raise it rather than silently picking one.

## Context

drktimes is a mobile app for home black-and-white darkroom work, in two parts:

1. **Develop** (this spec): find the development time for a film, the ISO it was shot at, and a developer at a dilution and temperature. Then run the whole development process as one guided session: developer, stop, fix, wash, wetting agent.
2. **Print** (a later, separate spec): an enlarger exposure timer with test-strip calculations. Out of scope here except as a placeholder.

**The problem today**: the owner looks up a time (e.g. Kodak Tri-X 400 in Rodinal 1+50) in a reference app that has the data but "feels like it was made 10 years ago and no one has updated it since". They then use the phone's stock timer, setting and resetting it for every step and remembering the agitation rhythm and wash procedure in their head. Their most common combination (Tri-X + Rodinal 1+50) isn't in the manufacturer-sourced dataset at all.

**The user and the setting**: a hobbyist developing film in a daylight tank at a table or sink, with the room light on. During a run the phone lies on the table about an arm's length away. Hands are wet or gloved and fully busy inverting the tank, and eyes are on the tank. They follow sound cues without looking, and glance at the screen only when unsure what to do next.

**Design principle**: simple and modern, **form follows function**. Every element is there because the process needs it.

## Clarifications

### Session 2026-10-21

- Q: Should you be able to run more than one development session at the same time (e.g. two tanks with different films started a few minutes apart)? → A: Yes. Multiple independent sessions, each with its own cues, labelled by tank.
- Q: When a combination has several times, which one should the combination page preselect for Start? → A: The time you used last for this combination, whatever its source. On first use, the datasheet time.
- Q: Should the app collect any data about how it's used or when it crashes? → A: No. Nothing collected: no analytics and no own crash reporting. The only network use is the optional dataset update check.
- Q: How precise should temperature be when the app decides that two recipes belong to the same combination? → A: Whole °C only. Entries are whole degrees, and °F is converted and rounded to the nearest °C for grouping.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run a guided development session (Priority: P1)

The user has a development time and a loaded tank. They press Start, and the app carries them through every step of the process: developer, stop bath, fixer, wash, wetting agent. It tells them when to agitate and at what pace (a metronome-like tick), when a step ends, and what to dump and pour next. They never set or reset a timer, can follow the whole run by sound without looking, and can equally follow it by screen alone with sound off.

**Why this priority**: this is the owner's main pain (constantly setting and resetting the phone timer) and the core value of the app. With only a manually entered time, it already replaces the stock timer.

**Independent Test**: enter a developer time (e.g. 13:00), start a session with the default process, and complete it end to end. Run it twice: once with the screen covered (sound only) and once with sound off (screen only).

**Acceptance Scenarios**:

1. **Given** the default process and a 13:00 developer time, **When** the user presses Start, **Then** the developer step begins with an "agitate" state and a start-agitating chime. A metronome tick sounds once per inversion at the inversion pace (default every 2 s) for 60 s. After that there are 10 s agitation bursts every minute, each opening with the chime and ticking for its duration.
2. **Given** agitation is in progress, **When** the agitation burst ends, **Then** the ticks simply stop (there is no separate stop sound) and the screen switches to a visibly different "rest" state showing the time until the next agitation.
3. **Given** a timed step is running, **When** 10 s remain, **Then** short end-of-step pips sound and the screen shows a heightened countdown.
4. **Given** the developer step ends, **When** the transition mode is "wait for me" (the default), **Then** a distinct dump-and-pour chime sounds and the screen shows "Dump developer → pour stop bath" with amounts and a large Next control. The stop bath step does not start until Next is pressed.
5. **Given** the transition mode is "keep going", **When** a step ends, **Then** the dump-and-pour chime sounds and the next step starts timing immediately, with the pour time counted inside it.
6. **Given** the user pressed Next by accident, **When** they press Undo within the undo window, **Then** the session returns to the dump-and-pour state as if Next had not been pressed.
7. **Given** the wash step uses the Ilford fill-and-invert method, **When** the wash begins, **Then** the app guides three fills (invert 5, then 10, then 20 times) and counts inversions on screen in time with the metronome. Each fill ends with a dump instruction and waits for Next before the next fill.
8. **Given** the wash step uses running water, **When** the wash begins, **Then** a plain 10:00 countdown runs.
9. **Given** the last step completes, **When** the session ends, **Then** a Done screen shows a summary (combination, recipe, actual step durations) and offers "Add a note". The session is recorded in Recent.
10. **Given** sound is switched off, **When** a full session runs, **Then** every instruction, agitation pace and state change is still visible on screen. The user can complete the run by looking alone.
11. **Given** a session is running, **When** the phone locks, the app goes to the background, or the system closes the app, **Then** step timing remains correct against real elapsed time. Cues continue in the background as far as the platform allows. Reopening the app returns to the live session at the correct point.
12. **Given** a session is running, **When** the user presses Pause, **Then** they must confirm a warning that the chemistry keeps working while paused before the timer pauses.
13. **Given** a session is running, **When** the user aborts and confirms, **Then** the session ends and is recorded in Recent as "aborted at step N".
14. **Given** a step is running, **When** the user taps +30 s or −30 s, **Then** the current step's remaining time changes by 30 s without stopping the timer.
15. **Given** a session for Tank 1 is running, **When** the user starts a second session (e.g. a different film) as Tank 2, **Then** both run independently with their own timing, states and cues. Each is labelled by tank everywhere it appears: on screen, in the dump-and-pour instruction, and in Recent.
16. **Given** two sessions are running, **When** one needs attention (agitate, last 10 s, dump & pour), **Then** its cues are audibly distinguishable from the other tank's, and the screen makes clear which tank they belong to.

---

### User Story 2 - Look up a development time (Priority: P1)

The user picks a film, the ISO they shot it at, and a developer with its dilution and temperature. The app shows the time to use, where it came from, and how much chemical to mix. One tap starts the session.

**Why this priority**: you can't develop without knowing the time. Together with Story 1 this is the minimum product that replaces both the reference app and the stock timer.

**Independent Test**: search "hp5", pick Ilford HP5 Plus → ISO 400 → Ilford Ilfotec DD-X 1+4 → 20 °C, and check that the combination page shows the datasheet time with its source and correct chemical amounts for 35mm and 120.

**Acceptance Scenarios**:

1. **Given** the Develop home, **When** the user searches "trix", **Then** Kodak Tri-X 400 appears among the results. Searching "R09" or "rodinal" finds the Rodinal-formula developers (search matches brand, name and aliases).
2. **Given** a film is picked, **When** the developer list appears, **Then** developers with datasheet times or recipes for that film are listed first and all other developers below.
3. **Given** a film and developer are picked, **When** the ISO list appears, **Then** box speed comes first, then every push/pull ISO that has data (labelled relative to box speed, e.g. "ISO 800 · push +1"), then "custom".
4. **Given** film, developer and ISO are picked, **When** dilution and temperature are shown, **Then** they are preselected from what exists for that choice and remain editable. Dilutions display in the forms the data uses: `1+50`, `stock`, `working`, multi-part like `1+1+5`.
5. **Given** a combination with a datasheet time, **When** its page opens, **Then** it shows the preselected time (FR-071) prominently with its source (publisher, document, page), a Start action, a 35mm/120 selector with chemical amounts, a Customise action and a Favourite action.
6. **Given** a datasheet gives a time range (e.g. 7:00–8:00), **When** the combination page shows it, **Then** it displays as a range, and the time preselected for a run is the midpoint (7:30), adjustable before starting.
7. **Given** a datasheet lists times for several processing methods, **When** the combination page shows them, **Then** small-tank inversion times are primary and others (rotary, stand, tray, large tank) are shown with their method label. Any agitation instruction from the datasheet is shown as a note.
8. **Given** a film is a rebrand of another film, **When** its times are shown, **Then** the original film's datasheet times appear, labelled as inherited. If the rebrand is only reported, not confirmed by the seller, the label says so.
9. **Given** 35mm is selected and the dilution is Rodinal 1+50, **When** amounts are shown, **Then** they read 5.9 ml concentrate + 294.1 ml water (300 ml total). With 120 selected they read 9.8 ml + 490.2 ml (500 ml).
10. **Given** a combination with no published time (e.g. Tri-X 400 + Rodinal 1+50), **When** its page opens, **Then** it says no published time exists and leads straight to creating your own (Story 3).
11. **Given** the user's chemistry is at a temperature that no listed time uses (e.g. 22 °C), **When** they enter that temperature, **Then** the page offers a converted time, clearly labelled as an estimate, which they can use for a run or save as their own recipe. The converted time is never stored as datasheet data.

---

### User Story 3 - Create and customise my own recipes (Priority: P2)

When a combination is missing, or the user develops differently from the datasheet, they save their own recipe. They can start from a datasheet time as a baseline or from scratch, and add dated notes over time, like a log. Push and pull are simply recipes at a different ISO.

**Why this priority**: the owner's most-used combination has no published time, so without this the app is a dead end for them. It's not P1 only because Stories 1–2 already work with a manually entered time.

**Independent Test**: create a recipe "Tri-X 400 · Rodinal 1+50 · ISO 400 · 20 °C · 13:00" from scratch with a note. Confirm that it appears on that combination's page and survives an app restart.

**Acceptance Scenarios**:

1. **Given** a combination page with a datasheet time, **When** the user taps Customise, edits the time and saves, **Then** a new recipe of their own is created with origin "based on [datasheet source]". The datasheet time stays unchanged.
2. **Given** no published time, **When** the user creates a recipe from scratch, **Then** they can set film, developer, dilution, ISO, temperature, developer time, developer agitation pattern, an optional custom process, and notes.
3. **Given** a film or developer isn't in the catalogue, **When** the user adds it (brand, name, and box ISO for films), **Then** it can be used in recipes and appears in search alongside catalogue entries, marked as user-added.
4. **Given** an existing recipe, **When** the user adds another note, **Then** the recipe keeps all its notes, each dated, in order.
5. **Given** the user edits a recipe someone else shared with them, **When** they save, **Then** their own copy is created (origin "edited copy of [author]'s recipe") and the received recipe stays exactly as received.
6. **Given** Tri-X shot at ISO 800, **When** the user saves a recipe for it, **Then** it is its own combination, separate from Tri-X at ISO 400, labelled "push +1".
7. **Given** the Done screen after a run that used a datasheet time or someone else's recipe, **When** the user adds a note and saves, **Then** their own recipe for that combination is created with that note. After a run of their own recipe, the note is added to it.

---

### User Story 4 - Customise the development process (Priority: P2)

Not everyone works the same way. One person skips the wetting agent, another uses a hypo clearing agent before the wash. The user edits their default process and can give a recipe its own process.

**Why this priority**: the default works out of the box for the owner. Customising it matters for everyone else and for less common workflows (stand development, a pre-soak).

**Independent Test**: enable hypo clearing, change the fixer time to 7:00, switch the wash to running water, save as default, and run a session that follows the new sequence.

**Acceptance Scenarios**:

1. **Given** the process editor, **When** the user toggles, reorders, retimes, renames, adds or removes steps and saves, **Then** the next session follows exactly that sequence.
2. **Given** a fresh install, **When** the user opens the default process, **Then** it is:
   - pre-soak (water) 1:00, initial 30 s continuous agitation (**off**)
   - developer, time from the recipe, 60 s continuous then 10 s every 60 s
   - stop bath 1:00, same agitation as the developer
   - fixer 5:00, same agitation as the developer
   - hypo clearing agent 2:00, 30 s continuous then 10 s every 60 s (**off**)
   - wash, Ilford fill-and-invert method (alternative: running water 10:00)
   - wetting agent 0:30, no agitation
3. **Given** a step, **When** the user edits its agitation, **Then** they can choose:
   - **intermittent:** initial continuous period, then X s every Y s
   - **continuous:** for rotary processing
   - **stand / semi-stand:** initial agitation, then none, or one agitation at a set point such as halfway
   - **none**
4. **Given** the Ilford wash method, **When** the user edits it, **Then** the inversion counts for each fill (default 5, 10, 20) can be changed.
5. **Given** a recipe with its own process, **When** a session runs that recipe, **Then** the recipe's process is used instead of the default.
6. **Given** standard steps, **When** a step is shown during a session, **Then** its how-to text is displayed. For example, hypo clearing explains that it shortens the wash, and the wetting agent step says not to shake (foam). The text is editable.
7. **Given** the process settings, **When** the user sets the transition mode ("wait for me" or "keep going") for a process, **Then** sessions using that process behave accordingly.

---

### User Story 5 - Get back to what I use (Priority: P3)

The app remembers context: the mode used last, starred combinations, and recent runs. A repeat run takes a couple of taps.

**Why this priority**: it makes daily use fast, but the app works without it.

**Independent Test**: star a combination, run a session, close the app, and reopen it. The app opens in Develop mode, the combination is in Favourites, the run is in Recent, and starting it again takes at most three taps.

**Acceptance Scenarios**:

1. **Given** the user last used Develop mode, **When** they reopen the app, **Then** it opens in Develop mode. The Print mode exists as a "coming later" placeholder and is remembered the same way.
2. **Given** a combination page, **When** the user stars it, **Then** the whole combination (film, developer, dilution, ISO, temperature) appears in Favourites, and one tap opens its page.
3. **Given** past sessions, **When** the user opens Recent, **Then** runs are listed newest first with date, combination and outcome (completed / aborted at step N). One tap opens that combination with the same recipe and format preselected, ready to start.
4. **Given** a session was in progress when the app was closed, **When** the user reopens the app, **Then** it returns straight to the live session.
5. **Given** a first launch, **When** Favourites or Recent are empty, **Then** each shows a helpful empty state pointing to Search.

---

### User Story 6 - Share recipes and see everyone's times together (Priority: P3)

The user sends their Tri-X/Rodinal recipe to a friend through any messaging app, and the friend imports it. When several people's recipes for the same combination arrive, they are grouped into one view with a summary, and every note stays visible.

**Why this priority**: it's what makes the app a community, which the owner wants, but it builds on Stories 2–3 and isn't needed for a single user's darkroom work.

**Independent Test**: share a recipe from phone A, import it on phone B, then import it again on phone B. Import two other people's recipes for the same combination. Phone B shows one combination with every time, the summary line and all notes, and no duplicates.

**Acceptance Scenarios**:

1. **Given** one of the user's own recipes, **When** they tap Share, **Then** a link and/or a file is offered through the system share options. It carries the combination, time, agitation, process, all notes, author name, any user-added film or developer, and the recipe's permanent identity and version.
2. **Given** a first share, **When** the user has not set an author name, **Then** they are asked for one once, and it is attached to everything they share afterwards.
3. **Given** a shared recipe arrives, **When** the recipient opens it on a phone with the app, **Then** they see a preview (author, combination, time, note count) and an Import action.
4. **Given** a shared link, **When** it is opened on a phone without the app, **Then** it leads to a page explaining what drktimes is and how to get it.
5. **Given** the recipient already has this exact recipe, **When** they import it again, **Then** a newer version updates their copy, an equal or older version reports "already up to date", and no duplicate is ever created.
6. **Given** recipes from different people for the same combination, **When** the combination page opens, **Then** all of them appear under that one combination: datasheet times, "Your recipes", "From others" (with author names), and a summary line such as "4 times · typically 13:00 (12:30–14:00)". All notes from all recipes appear in full, with author and date.
7. **Given** an imported recipe uses a user-added film or developer that matches a catalogue entry or an existing user-added one by brand and name, **When** importing, **Then** the app offers to treat them as the same, so the combination groups don't split.
8. **Given** an imported recipe, **When** the user hides or removes it, **Then** it no longer appears in their combination views.
9. **Given** a recipe for a rebranded film, **When** its combination page opens, **Then** recipes and notes for the original film (and its other rebrands) with the same developer, dilution, ISO and temperature appear in a clearly labelled secondary section. They are not merged into the main group.

---

### User Story 7 - Back up and move to a new phone (Priority: P3)

The user exports all their data to one file and imports it on a new phone without losing anything.

**Why this priority**: losing recipes and notes would be a failure, but it only matters once there's data to lose.

**Independent Test**: create recipes, notes, favourites and sessions, export, import on a clean install, and confirm everything is there. Import the same backup again and confirm nothing is duplicated.

**Acceptance Scenarios**:

1. **Given** user data exists, **When** the user taps Export all, **Then** one file is produced. It contains own recipes, imported recipes, notes, favourites, sessions, settings, and user-added films and developers.
2. **Given** a backup file, **When** the user imports it, **Then** items merge by permanent identity, nothing is duplicated, and newer local data is never overwritten by older backup data.

---

### Edge Cases

- **No published time for a combination**: it is never a dead end. The page offers to create your own (US2 #10).
- **Several datasheet times for one combination** (several sources, editions or methods): all are shown with their sources. Preselection follows FR-071.
- **The recipe or time used last has since been hidden, removed, or changed by a dataset update**: preselection falls back to the next rule in FR-071. A recipe used last that was later edited preselects its current version.
- **Datasheet time ranges**: the midpoint is the default (US2 #6).
- **Recipes that differ only in agitation or steps**: they stay in one combination group. The variation is shown on each recipe (e.g. "stand development").
- **Temperatures in °F that don't map to a whole °C** (e.g. 70 °F ≈ 21.1 °C): grouped under the rounded °C (21 °C), with the user's °F value still shown.
- **Different temperature**: a separate combination. Conversion is offered as a labelled estimate (US2 #11).
- **Accidental Next** (splash, sleeve): undo within a short window (US1 #6).
- **The phone is locked, the app backgrounded or closed by the system mid-session**: timing stays correct and the session resumes on reopen (US1 #11). Where the platform limits background sound, the app uses the platform's allowed alert mechanism and explains the limitation to the user once.
- **Phone in silent mode**: cues play as reliably as the platform allows. The screen-only path always works.
- **Incoming phone call or other audio during a session**: timing continues. Cues resume afterwards (assumption: the app does not pause the session automatically).
- **Pause**: allowed only after confirming the chemistry warning (US1 #12).
- **Unusual dilution forms**: `stock` and `working` show the full volume with no water. Multi-part forms (`1+1+5`) show one amount per part plus water.
- **Films whose process isn't black-and-white negative** (a few reversal and C-41 films in the catalogue): shown with a notice that the default process doesn't fit and the steps must be customised.
- **Datasheet data updated after a recipe was based on it**: the recipe keeps its own numbers. Updates never touch user data.
- **Corrupt or foreign file opened as a recipe or backup**: rejected with a clear message. Existing data is untouched.
- **A shared recipe with no author name**: shown as "unknown author".
- **Importing your own previously shared recipe**: recognised by permanent identity as your own and not duplicated.
- **Two recipes from the same author for the same combination**: both kept, as distinct recipes.
- **Two tanks need agitation at the same moment**: both are shown and both cue, each in its own tank sound. Instructions name the tank. The sessions' timing is never shifted to avoid overlap.
- **Two tanks finish a step at the same moment**: both dump-and-pour states are shown. Next acts on the one waiting longest, which is labelled on the Next control.
- **Starting a fourth session**: blocked, with a message that at most 3 tanks can run at once.

## Requirements *(mandatory)*

### Functional Requirements

**Modes and navigation**

- **FR-001**: The app MUST have two top-level modes, Develop and Print. Print MUST show only a "coming later" placeholder in this feature.
- **FR-002**: The app MUST reopen in the mode used last.
- **FR-003**: If one or more sessions are in progress when the app is reopened, the app MUST return directly to them, each at its correct point.
- **FR-004**: Develop home MUST offer Favourites, Recent and Search.

**Lookup**

- **FR-005**: Search MUST match films and developers by brand, name and aliases, tolerating common shorthand (e.g. "trix", "hp5", "R09").
- **FR-006**: Picking MUST follow the order film → developer → ISO → dilution and temperature. Each step after film narrows to options that have data, while still allowing any choice.
- **FR-007**: Developer lists MUST put developers with datasheet times or recipes for the chosen film first.
- **FR-008**: ISO lists MUST show box speed first, then ISOs with data labelled as push/pull relative to box speed, then a custom value.
- **FR-009**: Dilution and temperature MUST be preselected from existing data and remain editable.
- **FR-010**: Each datasheet time MUST display its source (publisher, document title or code, page).
- **FR-011**: Datasheet ranges MUST be shown as ranges, with the midpoint as the default run time.
- **FR-012**: Small-tank inversion times MUST be primary. Other processing methods MUST be shown with a method label. Datasheet agitation instructions MUST be shown as notes.
- **FR-013**: Rebranded films MUST show the original film's datasheet times, labelled as inherited. Rebrands that are only reported MUST be labelled as not confirmed.
- **FR-014**: The app MUST offer a temperature-converted time when the user's temperature has no listed time. It MUST be labelled as an estimate, never stored as datasheet data, and saveable as the user's own recipe. The conversion method MUST cite its source.
- **FR-015**: The user MUST be able to add films (brand, name, box ISO) and developers (brand, name) that are not in the catalogue. These MUST be marked as user-added.

**Combinations, recipes, notes**

- **FR-016**: A combination MUST be identified by film (as picked) + developer + dilution + ISO + temperature. Temperature is in whole °C. Differences in agitation or process MUST NOT split a combination.
- **FR-073**: Temperatures MUST be entered in whole degrees. When the unit is °F, the value MUST be converted to °C and rounded to the nearest whole °C for storage and grouping, while the user's °F value is displayed back (e.g. 68 °F → 20 °C, 72 °F → 22 °C).
- **FR-017**: The combination page MUST show:
  - datasheet times, then your recipes, then recipes from others (with author names)
  - a summary line (count, median, range) when there are 2 or more times
  - every note from every recipe, in full, with author and date
  - a format selector with chemical amounts
  - Start, Customise, Favourite, and Share for own recipes
- **FR-071**: The combination page MUST preselect a time for Start in this order:
  1. the time used in the user's most recent session for this combination, whatever its source (datasheet, own recipe, or someone else's recipe)
  2. if there was no previous session, the datasheet time (small tank, from the newest source; the midpoint for a range)
  3. if there is no datasheet time, the user's own most recent recipe
  4. otherwise, the most recently imported recipe from others

  The preselected time MUST be visibly marked (e.g. "used last time"), and the user can pick any other listed time before starting.
- **FR-018**: For a rebranded film, the combination page MUST show matching recipes and notes for the original film and its other rebrands in a clearly labelled secondary section, without merging them into the main group.
- **FR-019**: Users MUST be able to create a recipe from a datasheet time (as a baseline) or from scratch. The fields are:
  - film, developer, dilution, ISO, temperature
  - developer time and developer agitation pattern
  - an optional own process
  - notes
- **FR-020**: Every recipe MUST have a permanent identity, a version, an author name and an origin ("based on [source]", "from scratch", or "edited copy of [author]'s recipe").
- **FR-021**: A recipe MUST hold multiple dated notes, kept in order.
- **FR-022**: Datasheet times MUST be read-only. User data MUST never be written into, or presented as, datasheet data.
- **FR-023**: Editing a received recipe MUST create the user's own copy and leave the received recipe unchanged.
- **FR-024**: Push/pull MUST be handled as separate combinations at a different ISO, not as a separate concept.

**Chemical amounts**

- **FR-025**: The user MUST be able to choose a 35mm format (default 300 ml) or a 120 format (default 500 ml). Both volumes MUST be editable in settings.
- **FR-026**: For a dilution `1+N` the app MUST show concentrate and water to 0.1 ml. `stock` and `working` show the full volume. Multi-part dilutions show one amount per part plus water.
- **FR-027**: Amounts MUST appear on the combination page and on each pour instruction during a session.
- **FR-028**: The app MUST NOT calculate by tank model, reel count or minimum developer per roll in this feature.

**Process and steps**

- **FR-029**: The process MUST be an ordered list of steps. Each step has a name, duration, agitation pattern, optional how-to text, and an enabled flag.
- **FR-030**: Users MUST be able to enable/disable, reorder, retime, rename, add and remove steps, and save the result as their default process. A recipe MAY carry its own process, which overrides the default.
- **FR-031**: The default process MUST match US4 #2.
- **FR-032**: Agitation patterns MUST support intermittent (initial continuous period, then X s every Y s), continuous, stand/semi-stand (initial agitation, then none or one agitation at a set point), and none.
- **FR-033**: The inversion pace MUST be adjustable (default one inversion every 2 s) and MUST drive both the tick and the visual pulse.
- **FR-034**: The wash step MUST offer running water (default 10:00) or the Ilford fill-and-invert method (default 5/10/20 inversions over three fills, editable). Each fill is guided, inversions are counted, and Next is required between fills.
- **FR-035**: Standard steps MUST come with prefilled, editable how-to text.

**Session**

- **FR-036**: The developer step MUST start only when the user presses Start.
- **FR-037**: The session screen MUST always show the current step name, the remaining time for the step (dominant, readable from about one metre), what comes next, and progress through all steps. The screen MUST stay awake for the whole session.
- **FR-038**: The session MUST present these distinct states:
  - ready/pour
  - agitate (visual beat at the inversion pace, inversion count, time left in the burst)
  - rest (time to the next agitation)
  - last 10 seconds
  - dump & pour (what to dump, what to pour, amounts)
  - guided wash
  - paused
  - done

  Each state MUST be distinguishable by more than colour alone.
- **FR-039**: Sound cues MUST be:
  - a start-agitating chime
  - a metronome tick for each inversion while agitating
  - short pips in the last 10 s of each timed step
  - a distinct dump-and-pour chime when a step ends

  There MUST be no stop-agitating sound and no spoken words.
- **FR-040**: Every session MUST be completable with sound off, with all information conveyed on screen.
- **FR-041**: Sound MUST be switchable on/off, with adjustable volume.
- **FR-042**: The transition mode MUST be selectable per process, with a default in settings:
  - **"wait for me"** (the default): the next step waits for Next
  - **"keep going"**: the next step starts at once, with pour time counted inside it
- **FR-043**: Next MUST be a large control covering the bottom of the screen, operable with a knuckle, wet finger or glove. On Android, a volume-button press MUST also act as Next (on by default, switchable off). On iOS, volume buttons MUST NOT be used.
- **FR-044**: After Next, an Undo MUST be available for a few seconds.
- **FR-045**: There MUST be no drain-time compensation.
- **FR-046**: Pause MUST require confirming a warning that the chemistry keeps working. Abort MUST require confirmation and record the session as aborted at its step.
- **FR-047**: The user MUST be able to add or subtract 30 s on the current step without stopping it.
- **FR-048**: Session timing MUST follow real elapsed time and stay correct when the phone locks, the app is backgrounded, or the app is closed by the system. Cues MUST continue in the background by means the platform allows.
- **FR-049**: The Done screen MUST show a summary (combination, recipe, actual step durations) and offer Add a note, which behaves as in US3 #7.
- **FR-050**: Every session MUST be recorded in Recent with date, combination, recipe, format, tank label and outcome.
- **FR-068**: Users MUST be able to run multiple independent sessions at the same time (up to 3), each labelled by tank (default "Tank 1", "Tank 2", "Tank 3", renamable). Each session has its own timing, transition mode, pause/abort and ±30 s.
- **FR-069**: With several sessions running:
  - each tank's sound cues MUST be distinguishable by ear (e.g. a different pitch or timbre per tank)
  - the screen MUST show every running session, with the one needing attention soonest made prominent
  - every instruction MUST name its tank ("Tank 2: dump developer → pour stop bath")
- **FR-070**: With several sessions running, Next (on-screen or volume button) MUST apply to the session currently shown as waiting for Next. If several are waiting, it MUST apply to the one that has been waiting longest. The on-screen Next MUST be labelled with that tank. Undo applies to the session that Next acted on.

**Favourites and Recent**

- **FR-051**: Favourites MUST store whole combinations, and one tap MUST open the combination page.
- **FR-052**: Recent MUST list sessions newest first. One tap MUST open the combination with the same recipe and format preselected.

**Sharing and merging**

- **FR-053**: Users MUST be able to share any of their own recipes as a link and/or file through the system share options. Everyone can share with everyone. There are no accounts.
- **FR-054**: A shared recipe MUST include everything listed in US6 #1.
- **FR-055**: The author name MUST be requested once, at first share, and be editable in settings.
- **FR-056**: Opening a shared recipe MUST show a preview and an Import action. A link opened without the app MUST lead to a page explaining the app and how to get it.
- **FR-057**: Import MUST be idempotent by permanent identity: newer versions update, equal or older versions report "already up to date", and duplicates are never created.
- **FR-058**: On import, user-added films and developers matching a catalogue entry or an existing user-added entry by brand and name MUST be offered as matches.
- **FR-059**: Users MUST be able to hide or remove imported recipes locally.
- **FR-060**: User-generated recipes are the sharer's responsibility. The app MUST NOT verify where their numbers came from. It MUST keep them visibly separate from datasheet times.

**Backup and data**

- **FR-061**: Users MUST be able to export all user data to one file and import it, merging by permanent identity without duplicating anything or overwriting newer local data with older data.
- **FR-062**: The share format and the backup format MUST be the same stable, versioned, documented format. This is the format a future community catalogue will also use.
- **FR-063**: The datasheet dataset MUST be bundled, and every lookup and session MUST work fully offline.
- **FR-064**: When online, the app MAY fetch a newer datasheet dataset from the project's public static host. Updates MUST never modify user data, and recipes keep their own numbers.
- **FR-065**: User data MUST survive app updates.
- **FR-072**: The app MUST NOT collect or transmit any usage, analytics, crash or personal data. All user data stays on the device unless the user explicitly shares or exports it. The only network request the app makes on its own is the optional dataset update check (FR-064), which MUST send no user data. The app MUST qualify for the App Store "Data Not Collected" privacy label.

**Settings**

- **FR-066**: Settings MUST include:
  - author name
  - 35mm/120 volumes
  - default process
  - default transition mode
  - inversion pace
  - sound on/off and volume
  - volume button as Next (Android only)
  - temperature unit (°C/°F, with datasheet values kept in °C)
  - theme (follows system light/dark)
  - export all / import all

**Visual design**

- **FR-067**: The UI MUST follow the "form follows function" principle. It must not be data-table-first, and it must avoid skeuomorphic darkroom styling. It MUST provide light and dark themes, and the visual system MUST leave room for a future red safelight theme for Print mode.

### Key Entities

- **Film**: a film stock. Brand, name, box ISO, process type, formats, aliases, optional rebrand link (with confirmed/reported basis). Either from the catalogue or user-added.
- **Developer**: a developer. Brand, name, aliases. Either from the catalogue or user-added.
- **Datasheet time**: a read-only published time. Film, developer, dilution, ISO, temperature, time (or range), processing method, optional agitation text, and its source (publisher, document, page).
- **Combination**: the grouping of film (as picked) + developer + dilution + ISO + temperature (whole °C). It gathers datasheet times, recipes and notes. It can be a favourite.
- **Recipe**: a user's version of a combination. Permanent identity, version, author name, origin, developer time, developer agitation pattern, optional own process, notes. It is either the user's own or received from someone else (received recipes are read-only, and can be hidden).
- **Note**: dated free text with an author, belonging to a recipe.
- **Process**: an ordered list of steps plus a transition mode. One default per user, optionally overridden per recipe.
- **Step**: name, duration, agitation pattern, how-to text, enabled flag. A wash step also has a method (running water, or fill-and-invert with per-fill inversion counts).
- **Agitation pattern**: a type (intermittent / continuous / stand-semi-stand / none) with its timings. The inversion pace is a setting.
- **Session**: one run. Tank label, date, combination, recipe or datasheet time used, format, actual step durations, outcome (completed / aborted at step N). Up to 3 sessions can be active at once.
- **Source**: the published document behind a datasheet time.
- **Settings**: user preferences as listed in FR-066.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A repeat run is fast. From launching the app to the developer step starting takes at most 3 taps, via Favourites or Recent.
- **SC-002**: A first-time lookup is fast. A new user finds a datasheet time for a common film and developer and starts a session in under 60 seconds.
- **SC-003**: Timing is accurate. Over a full default-process session (about 30 minutes), every step ends within 1 second of its planned time, including when the phone is locked for the whole session.
- **SC-004**: Sound alone is enough. With the screen covered, a tester completes a full session with zero missed or mistimed agitations.
- **SC-005**: Screen alone is enough. With sound off, a tester completes a full session with zero missed or mistimed agitations.
- **SC-006**: The states are readable at a distance. At one metre, at least 9 of 10 testers (including someone with simulated colour blindness) name the current session state correctly within 2 seconds.
- **SC-007**: The user never resets or re-enters a timer during a session. Zero manual time entries are needed between Start and Done.
- **SC-008**: Missing combinations are quick to fill. A user creates their own recipe for a missing combination in under 2 minutes.
- **SC-009**: Imports never duplicate. Importing the same recipe any number of times leaves exactly one copy, and 100% of notes from all recipes in a combination are visible on its page.
- **SC-010**: Backups lose nothing. An export-and-restore round trip on a clean install preserves 100% of recipes, notes, favourites, sessions and settings.
- **SC-011**: The app is fully usable offline. Every lookup and session works with no network connection.
- **SC-012**: Search finds shorthand. "trix", "hp5", "delta 400", "R09" and "rodinal" each return the intended item within the top 3 results.
- **SC-013**: User data never passes as datasheet data. 100% of user-entered or received times are labelled as such, and none is presented as a datasheet time.
- **SC-014**: The owner, after using it for their own development runs, prefers it to the stock phone timer plus reference-app routine (a qualitative check).
- **SC-015**: Two tanks can run together. With two overlapping sessions, a tester following sound and screen completes both with zero agitations or pours applied to the wrong tank.
- **SC-016**: The app sends no user data. Network monitoring during a full use cycle (lookup, sessions, recipes, settings) shows no outgoing traffic except the dataset update check, and that check carries no user data.

## Assumptions

- **Release**: iOS first, through TestFlight and then the App Store. Android is supported for development and testing. Google Play and F-Droid releases are undecided and must not require paid accounts yet. The owner's Mac can't build for the current iOS SDK, so iOS builds come from a hosted build service.
- **App Store rules apply**: volume buttons are not repurposed on iOS, and background cues use only mechanisms Apple permits. Background behaviour when the app is closed by the system may be more limited on iOS. Any limits are documented and shown to the user once.
- **Licence**: the app is open source, and its code is MIT. The bundled datasheet dataset is CC0 and contains manufacturer-published facts only (see `resources/devdata/README.md`). User-generated recipes are never added to it.
- **No server or accounts** in this feature. A community catalogue is a later phase. This feature's permanent identities, versions, author names, combination rule and exchange format are designed so that it can be added without migration. That phase will need report/block/takedown.
- **Share link host**: the project's public static hosting address until a domain is bought. The final address must be chosen before the first public release, because it is built into every shared link.
- **Language**: English only.
- **Units**: times as mm:ss. Temperature shown in °C by default, with °F available.
- **Interruptions**: an incoming call or other audio doesn't pause the session automatically. Timing continues.
- **Concurrent sessions**: up to 3 tanks at once (a reasonable cap for home darkroom work; adjustable in planning).
- **Undo window**: a few seconds (exact length to be settled in design, around 5 s).
- **Out of scope**: Print mode (beyond its placeholder); spoken prompts; drain-time compensation; tank, reel and roll-count calculations; first-class colour (C-41/E-6) processing; the community catalogue.
- **Left to planning** (the design doc's "left to the builder" list):
  - how user data is stored and how links and files are encoded
  - how background timing and sound are achieved on each platform
  - the specific sound designs
  - which time/temperature compensation curve to use (with its source)
  - how datasheet methods and agitation text map to agitation patterns
  - search ranking
- **Visual design** comes from a separate Claude Design pass, using the brief in `docs/superpowers/specs/2026-10-21-film-development-timer-design-prompt.md`. This spec defines behaviour, not visuals.
