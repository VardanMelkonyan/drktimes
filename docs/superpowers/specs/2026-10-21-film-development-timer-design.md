# drktimes, Part 1: Film Development Timer: Design

Date: 2026-10-21
Status: approved by owner, 2026-10-21

## 1. Intent

drktimes is a mobile app for black-and-white darkroom work. It has two parts:

1. **Develop** (this document): find the development time for a film, ISO and
   developer, then run the whole development process as one guided session:
   developer, stop, fix, wash, wetting agent.
2. **Print** (later, out of scope here): an enlarger exposure timer with
   test-strip calculations.

### Why

Today the owner looks up a time (e.g. Kodak Tri-X 400 in Rodinal 1+50), then
uses the phone's stock timer, setting and resetting it for every step and
remembering agitation rhythm and wash procedure in their head. The existing
reference app (Massive Dev Chart) has the data but "feels like it was made 10
years ago and no one has updated it since."

### What success looks like

- From opening the app to the developer timer running takes a few taps for
  a combination used before.
- During a run the owner never touches a timer: the app tells them (by sound,
  and visibly on screen) when to agitate, at what pace, and when to dump and
  pour what next, through to the final wetting agent.
- The owner can run a whole process **without looking**, by sound alone, and
  **without sound**, by screen alone.
- A combination missing from the data (like Tri-X + Rodinal 1+50) is not a
  dead end: the user enters their own time once and it's there forever, can be
  shared with friends, and other people's versions merge into one view.
- The UI is simple and modern; **form follows function**: every element is
  there because the process needs it.

## 2. Goals, non-goals, anti-goals

### Goals

- Look up development times from the bundled, manufacturer-sourced dataset.
- Let users create, edit and save their own recipes, starting from a datasheet
  time or from scratch, including push/pull and custom process steps.
- Run a guided, step-by-step development session with agitation metronome,
  sound cues and a glanceable screen.
- Share recipes person-to-person without a server; merge duplicates into
  grouped combinations, always showing every note.
- Remember context: last mode, favourites, recent sessions.

### Non-goals (for Part 1)

- The Print/enlarger timer (Part 2). The mode exists only as a placeholder.
- A server, user accounts, or a public community catalogue. These are planned
  as a later phase, and Part 1's data format must make them easy to add (§11).
- Tank/reel/roll-count chemistry calculations. Only a simple 35mm/120 volume
  choice is in scope (§8).
- Colour (C-41/E-6) process support as a first-class flow.
- Spoken voice prompts.
- Drain-time compensation.

### Anti-goals (would be a failure even if it "works")

- A cluttered, data-table-first UI that looks like the app it's replacing.
- Any step that requires reading the screen while agitating, or that can't be
  done with wet/gloved hands.
- A timer that drifts, stops, or goes silent when the phone locks or the app is
  backgrounded.
- Losing a user's own recipes or notes (on update, phone change, or import).
- Mixing user-entered times into the CC0 manufacturer dataset.

## 3. Constraints

- **Platform:** the existing Flutter project in this repo; target iOS and
  Android phones. (Desktop/web scaffolds exist but are not targets.)
- **Release: iOS first, via TestFlight, then the App Store** (owner's
  decision). Google Play and F-Droid are undecided and must not cost money
  yet.
  - The owner's Mac is too old for the current iOS SDK, so iOS builds and
    TestFlight uploads must run on hosted macOS CI. Day-to-day development
    and testing can happen on Linux with the Android emulator.
  - Everything must be **App Store safe**: no repurposed volume buttons on
    iOS, and no background-audio tricks that risk rejection. On iOS the
    background cues must use mechanisms Apple allows (e.g. scheduled local
    notifications with custom sounds), and the builder documents what a
    locked or killed app can and can't do.
- **Licence:** app code under **MIT** (owner's decision), so it can go on
  the App Store; the dataset stays CC0.
- **Share link host (my call, owner may override):** the project's GitHub
  Pages address, until a domain is bought. It's built into every shared
  link, so pick the final one before the first public release.
- **Fully offline.** Darkrooms and bathrooms have poor signal; nothing in the
  lookup or session may depend on the network.
- **Open source.**
- **Standalone, no server** in Part 1 (owner's decision).
- **Two strictly separate data pools:**
  - *Datasheet data:* the bundled CC0 dataset in `resources/devdata/`
    (manufacturer facts only, ~3,700 rows, 172 films, 73 developers; see that
    folder's README for the sourcing policy). The app reads it; users never
    write to it.
  - *User data:* user recipes, notes, favourites, sessions, and recipes
    imported from others. This is **user-generated content**; the user is
    responsible for where their numbers came from, and the app does not check
    provenance (owner's decision).

## 4. Core concepts

| Concept | Meaning |
|---|---|
| **Combination** | The grouping key: film + developer + dilution + ISO (EI) + temperature. Everything about "Tri-X 400 · Rodinal 1+50 · ISO 400 · 20 °C" lives under one combination. |
| **Datasheet time** | A read-only row from the bundled dataset, shown with its source (e.g. "Kodak datasheet F-4017, p. 3"). |
| **Recipe** | A user's own version of a combination: developer time, agitation pattern, optional custom process, notes. Has a permanent ID and an author name. Can be created from a datasheet time (as a baseline) or from scratch. |
| **Process** | An ordered list of steps (pre-soak, developer, stop, fix, hypo clear, wash, wetting agent, or custom). The user has a default process; a recipe may override it. |
| **Step** | Name, duration, agitation pattern, optional on-screen how-to, enabled/disabled. |
| **Agitation pattern** | How and when to agitate during a step (§7.3). |
| **Session** | One actual run of a process. Recorded in Recent. |
| **Note** | Free text attached to a recipe. A recipe can carry several notes over time (a log). All notes from all recipes in a combination are always shown. |

**Rebranded films (my call):** the key uses the film *as picked*, so an
Arista EDU 400 recipe and a Fomapan 400 recipe are different combinations.
This keeps stored groupings stable even if a `reported` rebrand link is
later corrected. The combination page for a rebrand also shows, in a
clearly labelled secondary section, recipes and notes for the original film
(and its other rebrands) with the same developer/dilution/ISO/temperature.

Push and pull are not a separate concept: Tri-X shot at ISO 800 is simply a
different combination from Tri-X at ISO 400. The UI labels EI relative to box
speed ("ISO 800 · push +1").

## 5. App structure and flows

### 5.1 Launch and modes

- Two modes: **Develop** and **Print**. Print shows a "coming later"
  placeholder in Part 1.
- The app reopens in the mode used last.
- If a session is in progress (app was killed or backgrounded), launching
  returns straight to the running session (§7.6).

### 5.2 Develop home

Three tabs (or equivalent segments):

- **Favourites:** starred **whole combinations** (owner's decision), e.g.
  "Tri-X 400 · Rodinal 1+50 · ISO 400 · 20 °C". One tap opens the
  combination page.
- **Recent:** past sessions, newest first. One tap opens that combination with
  the same recipe and format preselected, ready to start again.
- **Search:** one search field over films and developers, matching brand,
  name and aliases ("trix" → Tri-X, "R09" / "rodinal" → Rodinal-formula
  developers).

### 5.3 Picking a combination

Guided, in this order (my call; the order can be revisited during design):

1. **Film:** search or pick. Rebranded films (dataset `rebrand_of`) show the
   original film's times, labelled as inherited; where `rebrand_basis` is
   `reported` the label says the rebrand is reported, not confirmed.
2. **Developer:** developers that have datasheet times or any user/imported
   recipe for this film are listed first; all other developers below. Picking
   one with no data leads straight to "create your own time".
3. **ISO:** box speed first, then every EI with data (push/pull), plus
   "custom".
4. **Dilution and temperature:** preselected from what exists for the chosen
   film/developer/ISO, editable. Dilutions use the dataset's forms: `1+50`,
   `stock`, `working`, multi-part like `1+1+5`.

The user can also add a **custom film or developer** that isn't in the
catalogue (brand, name, box ISO for films). Custom entries live in user data
and travel inside shared recipes. (My call: without this, obscure stock is a
dead end.)

### 5.4 Combination page

The heart of lookup. Shows, for one combination:

- **Datasheet times**, each with its source. If a datasheet gives a range
  (`time_max_s`), it's shown as a range and the default used for a run is the
  midpoint (my call). Datasheet rows for tank inversion
  (`small_tank`) are primary; rows for other methods (rotary, stand, tray,
  large tank) are shown with their method label. Any datasheet agitation text
  is shown as a note.
- **Your recipes.**
- **From others:** imported recipes, each with author name.
- **Summary line** when there are 2+ times: count, typical (median) time and
  range, e.g. "4 times · typically 13:00 (12:30–14:00)".
- **All notes from every recipe**, in full, with author and date. Never
  collapsed into a summary.
- **Format selector** (35mm / 120) and the resulting **chemical amounts** (§8).
- **Start** (uses the selected recipe or datasheet time and the default or
  recipe process).
- **Customise:** create your own recipe from the selected time.
- **Star** (favourite), **Share** (for own recipes; §9).

Variations within a combination (different agitation, different steps) don't
split the group; they're shown on each recipe ("stand development").

### 5.5 Temperature conversion (my call, include in Part 1)

If the user's chemistry is at a different temperature than any listed time
(e.g. 22 °C water), the combination page offers a converted time using a
standard time/temperature compensation curve, clearly labelled as an
estimate. The dataset README already reserves this as an app calculation. The
converted time is never stored as data, but the user can save it as their own
recipe.

### 5.6 Recipe editor

Fields: film, developer, dilution, ISO, temperature, developer time, developer
agitation pattern, optional process override (full step editor, §6), notes.
Saving creates a recipe with a permanent ID, the user's author name, and an
origin ("based on Kodak datasheet F-4017" / "from scratch" / "edited copy
of [author]'s recipe"). Editing an imported recipe creates your own copy;
imported recipes themselves stay as received.

## 6. Process and steps

The process is fully customisable: steps can be enabled/disabled, reordered,
retimed, renamed, added (custom step) and removed. The user saves one
**default process**; a recipe may carry its own.

### Default process (the owner's workflow)

| # | Step | Default | Agitation | Enabled |
|---|---|---|---|---|
| 1 | Pre-soak (water) | 1:00 | initial 30 s continuous | off |
| 2 | Developer | from recipe | 1 min continuous, then 10 s every minute | on |
| 3 | Stop bath | 1:00 | same as developer | on |
| 4 | Fixer | 5:00 (user adjusts, typically 5–7) | same as developer | on |
| 5 | Hypo clearing agent | 2:00 | 30 s continuous, then 10 s every minute | off |
| 6 | Wash | method: Ilford fill-and-invert or running water 10:00 | per method | on |
| 7 | Wetting agent | 0:30 | none (gentle, per on-screen how-to) | on |

Each step has an optional **how-to** text shown on screen, prefilled for the
standard steps. For example, hypo clearing explains that it shortens the
wash, and the wetting agent step says not to shake (foam).

### Wash methods

- **Running water:** a plain countdown (default 10:00).
- **Ilford method (fill and invert):** a guided sequence. Fill the tank with
  water → invert **5** times → dump; refill → invert **10** times → dump; refill
  → invert **20** times → dump. The app shows each fill as a sub-step, counts
  inversions on screen in time with the metronome, and waits for Next between
  fills. Counts are editable.

## 7. The session (running a process)

### 7.1 Who and where

The phone lies on the table. While agitating, the user's hands and attention
are fully on the tank; they follow **sound** without looking. When unsure, they
glance at the screen, which must say what to do *right now*. The whole
session must also work **silently, by screen alone**.

### 7.2 Screen states

Each state must be distinguishable at a glance from about a metre away, by
more than colour alone (shape/layout/label too, for colour-blind users):

| State | Meaning | Shows |
|---|---|---|
| **Ready / pour** | Before a step starts | "Pour developer" + amounts + big Start/Next |
| **Agitate** | Agitate now | Visual beat pulse at the inversion pace, inversion count, time left in this agitation burst |
| **Rest** | Don't touch the tank | Time to next agitation |
| **Dump & pour** | Step finished | "Dump developer → pour stop bath" + big Next |
| **Guided wash** | Fill/invert/dump cycle | Current fill, inversions counted/remaining |
| **Done** | Process complete | Summary + "add a note" |

Always visible: current step name, big remaining time for the step, what's
next, overall progress through the steps.

The screen stays awake for the whole session.

### 7.3 Agitation patterns

Supported pattern types:

- **Intermittent:** initial continuous period, then X seconds every Y seconds
  (default: 60 s initial, then 10 s every 60 s).
- **Continuous:** for rotary processors.
- **Stand / semi-stand:** initial agitation, then none, or one agitation at a
  set point (e.g. halfway).
- **None.**

Plus an **inversion pace** (default one inversion every 2 s, adjustable),
which drives the metronome tick and the visual pulse.

### 7.4 Sounds

A small vocabulary of clearly distinct sounds (owner's decisions):

- **Start agitating:** a chime.
- **Metronome tick:** one per inversion while agitating. When the ticks stop,
  agitation stops. There is **no separate stop sound**.
- **End-of-step pips:** short pips in the last 10 s of each timed step.
- **Dump & pour:** a distinct chime when a step ends.
- **No spoken words.**

Sound on/off and volume are in settings. Cues must play with the screen locked
or the app in the background, and as reliably as the platform allows when the
phone is in silent mode. The builder decides how and documents any platform
limits.

### 7.5 Step transitions

The user picks per process (default in settings):

- **Wait for me** (default): step ends → dump & pour state → the next step
  stays paused until the user presses **Next**, meaning "next chemical is in."
- **Keep going:** step ends → dump & pour chime → the next step starts timing
  immediately; pour time counts inside it.

The first step (developer) always starts on the user's Start press.

**Next** is triggered by:
- a large Next button covering the bottom of the screen (usable with a
  knuckle, wet finger, or glove);
- optionally, a phone **volume button** press (my suggestion; on by default,
  can be switched off in settings). **Android only:** App Store guideline
  2.5.9 forbids repurposing the volume buttons, so iOS uses the Next
  button only;
- with **undo** available for a few seconds afterwards, to recover from an
  accidental press. (Chosen over hold-to-confirm, which is awkward with gloves.)

No drain-time compensation (owner's decision).

### 7.6 Interruptions

- **Pause:** available but behind a confirm, with the warning that the
  chemistry keeps working while paused.
- **Abort:** behind a confirm; the aborted session is still recorded in Recent
  as "aborted at step N".
- **Phone locks / app backgrounded / app killed:** timing is based on real
  elapsed time and must stay correct. Sounds still fire in the background.
  Reopening the app returns to the live session at the correct point.
- **Adjust on the fly:** add or subtract 30 s on the current step without
  stopping.

### 7.7 Finishing

The Done screen shows a summary (combination, recipe, actual step durations)
and offers **Add a note**. A note added here goes on the user's recipe for
this combination. If the session ran a datasheet time or someone else's
recipe, saving the note creates the user's own recipe from it. The session
appears in Recent.

## 8. Chemical amounts

- The user picks **35mm** or **120**, with default working volumes **300 ml**
  and **500 ml** (owner's values; editable in settings).
- For a dilution `1+N` the app shows concentrate and water, e.g. Rodinal 1+50
  at 300 ml → 5.9 ml concentrate + 294.1 ml water. Display rounded to 0.1 ml.
- `stock` / `working` → the full volume of the solution, no water.
- Multi-part dilutions (`1+1+5`) → one amount per part plus water.
- Amounts appear on the combination page and on each Ready/pour screen.
- No tank, reel-count or minimum-developer-per-roll calculations in Part 1.

## 9. Sharing, merging, backup (no server)

### 9.1 Sharing a recipe

- **Share** on any of your own recipes produces a **link** and/or a small
  **file**, sent through the system share sheet (Messages, Telegram, AirDrop,
  email, ...). Everyone can share with everyone.
- Opening the link or file on a phone with the app shows a preview and
  **Import**. Without the app, the link should lead somewhere that explains
  what drktimes is and how to get it.
- A shared recipe carries everything: combination, time, agitation, process
  override, all its notes, author name, any custom film/developer it uses,
  and its permanent ID and version.

### 9.2 Merging

- **Same recipe again** (same permanent ID): if the incoming version is newer,
  update the imported copy; otherwise say "already up to date". Never create a
  duplicate.
- **Different recipe, same combination**: stored as its own recipe and shown
  in the same combination group (§5.4). That is the merge: one combination,
  every time listed, summary line, and every note.
- **Same film/developer typed differently**: custom films/developers that
  match a catalogue entry (or each other) by brand + name should be offered as
  a match on import, so the groups don't split.

### 9.3 Author identity

No accounts. The user sets an **author name** once (asked on first share).
Recipes carry it plus the permanent ID.

### 9.4 Backup

- **Export all** user data (recipes, imported recipes, notes, favourites,
  sessions, settings, custom films/developers) to a single file, and
  **Import all** from it. This is the phone-switch path.
- Import of a backup merges by permanent ID; it never overwrites newer local
  data with older backup data.

### 9.5 Reporting

There is no catalogue to report to in Part 1, but an imported recipe can be
**hidden/removed** locally. Report/takedown belongs to the community
catalogue phase (§11).

## 10. Data updates

- The datasheet dataset is bundled in the app and always works offline.
- (My call) The app may check a static file on the project's public host (e.g.
  GitHub) for a newer dataset version and download it when online. This is
  not a server we run.
- Dataset updates never touch user data. If a datasheet row a recipe was based
  on changes, the recipe keeps its own numbers.

## 11. Later phase: community catalogue (designed-for, not built)

Part 1 must make this easy to add later:

- Recipes already have permanent IDs, versions and author names, and a stable,
  versioned, documented exchange format. The share file and backup use the
  same format.
- The combination key (§4) is the same rule that will group community
  submissions; the summary line becomes "12 people · typically 13:00
  (12–14)".
- The Share action gains a second option, "publish to community", next to
  person-to-person sharing.
- Community content is user-generated, kept separate from the CC0 dataset,
  and will need report/block/takedown (also an app store requirement).

## 12. Settings

- Author name
- Format volumes (35mm, 120)
- Default process (step editor)
- Default transition mode (wait for me / keep going)
- Inversion pace
- Sounds on/off, volume
- Volume button as Next (on/off)
- Temperature unit (°C / °F); the dataset stays °C internally
- Theme follows system light/dark
- Export all / Import all

## 13. Visual design brief (input for the design prompt)

- Modern, quiet, simple; **form follows function.** Not a data table. Not
  skeuomorphic darkroom kitsch.
- Primary surface during a session: huge time, current instruction, state.
  Readable from a metre, operable with wet hands.
- Session states (§7.2) must be visually distinct at a glance, with
  colour-blind-safe redundancy.
- Combination page: one clear time to start with, the rest (other sources,
  other people, notes) visible but secondary.
- Needs designs for: mode switch, Develop home (Favourites / Recent /
  Search), picking flow, combination page, recipe editor, process/step
  editor, every session state, guided wash, Done + note, share/import
  preview, settings, empty states (no favourites, no data for a combination).
- Light and dark themes. Print mode (Part 2) will need a safelight-safe red
  theme. The visual system should leave room for that.

## 14. Left to the builder

- Storage technology for user data, sharing link/file encoding, and the
  landing page for links.
- How to keep timing exact and sounds audible in the background and in silent
  mode on each platform, and documenting any platform limits.
- The specific sounds (they must be distinct and pleasant).
- The time/temperature compensation curve to use, with its source cited.
- Mapping datasheet `method` values and free-text agitation to default
  agitation patterns.
- Exact search ranking.
- Films with `process` other than `bw_negative` (5 reversal, 2 C-41): the
  default process doesn't fit them. Show them with a note that the steps must
  be customised, or hide them.

## 15. Decision log

**Owner's decisions:** two modes (Develop now, Print later), remembering the
last mode; film/ISO/developer lookup from the dataset; customisable recipes
with push/pull as separate entries; notes per combination; user recipes are
user-generated, provenance not checked; standalone (no server) for now, with a
community catalogue later; everyone can share with everyone; duplicates merge
by combination; all notes always shown; default steps and times as in §6;
fully customisable steps; no spoken prompts; no stop-agitating sound;
everything must also work by screen alone; Next button to advance (open to
better ideas); no drain time; simple 35mm (300 ml) / 120 (500 ml) amounts;
Favourites (whole combinations), Recent and Search; modern, form-follows-
function UI.

**My calls (owner to check):** combination key = film + developer + dilution
+ ISO + temperature, with agitation/steps not splitting a group; volume button
as Next plus undo; wait-for-me as default transition; inversion pace 2 s;
end-of-step pips; datasheet range → midpoint default; custom films/developers;
temperature conversion included in Part 1; optional dataset updates from a
static file; pause/abort/±30 s behaviour; Done → note creates your own recipe;
Ilford wash counts 5/10/20; hypo clear and pre-soak off by default; guided
picking order film → developer → ISO.
