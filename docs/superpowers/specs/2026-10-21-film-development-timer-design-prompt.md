# Claude Design prompt: drktimes Develop mode

Paste everything below the line into Claude Design. Source of truth:
`2026-10-21-film-development-timer-design.md` (same folder).

---

Design the iPhone UI for **drktimes**, an open-source darkroom app for
black-and-white film photographers. This brief covers its first mode,
**Develop**: find the right development time for a film, then run the whole
development process as a guided timer.

## Who uses it, and where

A hobbyist developing film at home in a daylight tank, at a kitchen table or
bathroom sink. The room light is on. During a run, the phone lies flat on the
table about an arm's length away. Their hands are wet or gloved and busy
inverting the tank, and their eyes are on the tank, not the phone. They follow
**sound cues** without looking, and glance at the screen only when unsure what
to do next. The app must also work **fully silently**, by screen alone.

## What's wrong today

The reference app in this space (Massive Dev Chart) has the data but feels
ten years old: dense tables, tiny targets, no guidance during the run. Users
end up juggling the phone's stock timer, resetting it for every step.

## Design principles

- **Form follows function.** Every element exists because the process needs
  it. Modern, quiet, simple. No data tables as the main UI, and no
  skeuomorphic darkroom kitsch.
- **Glanceable from a metre.** During a session, the remaining time and the
  current instruction dominate the screen.
- **Wet-hands operable.** Primary actions are huge, at the bottom of the
  screen, usable with a knuckle.
- **States are unmistakable.** Each session state differs in more than colour
  (layout, shape, label) so it is colour-blind safe and readable at a glance.
- **Light and dark themes.** Leave room in the visual system for a future
  red, safelight-safe theme (the Print mode, designed later).

## App structure

Two modes, switched at the top level: **Develop** (this brief) and **Print**
(show only a tasteful "coming later" placeholder). The app reopens in the last
used mode.

## Screens to design

### 1. Develop home
Three segments: **Favourites**, **Recent** and **Search**.
- *Favourites:* starred combinations, e.g. "Kodak Tri-X 400 · Rodinal 1+50 ·
  ISO 400 · 20 °C · 13:00". One tap opens the combination.
- *Recent:* past runs, newest first, with date, combination and result
  (completed, or aborted at a step). One tap gets ready to run it again.
- *Search:* one field over films and developers, forgiving ("trix" finds
  Tri-X, "R09" finds Rodinal).
- Empty states for no favourites and no recent runs (first launch).

### 2. Picking a combination
A guided flow: **Film → Developer → ISO → Dilution & temperature**.
- Developers that have known times for the chosen film come first. The rest
  sit below, and picking one leads to "no published time, add your own".
- ISO shows box speed first, then push/pull options labelled relative to box
  speed ("ISO 800 · push +1"), then custom.
- Users can add a film or developer that isn't in the catalogue.

### 3. Combination page (the core lookup screen)
For one combination, e.g. *Tri-X 400 · Rodinal 1+50 · ISO 400 · 20 °C*:
- One clear **time to use**, prominent, with a big **Start**.
- Where it came from: a manufacturer datasheet (with source name), the user's
  own recipe, or someone else's shared recipe (author name).
- When there are several times, a summary line: "4 times · typically 13:00
  (12:30–14:00)", with each time still listed.
- **All notes** from every recipe, in full, with author and date. Never
  hidden behind a summary.
- A **35mm / 120** selector and the chemical amounts it gives (e.g. "Rodinal
  1+50, 300 ml → 5.9 ml concentrate + 294.1 ml water").
- An optional temperature conversion ("Your water is 22 °C? ≈ 11:15,
  estimate").
- Actions: Customise (save your own version), Favourite, Share.
- An empty state: "No published time for this combination. Add yours."

### 4. Recipe editor
Film, developer, dilution, ISO, temperature, developer time, agitation
pattern, an optional custom process, and notes (a recipe can hold several dated
notes, like a log). Shows its origin, e.g. "Based on Kodak datasheet".

### 5. Process editor
An ordered list of steps that can be toggled on/off, reordered, retimed,
renamed, added and removed. Default steps:
pre-soak (off) · developer · stop bath 1:00 · fixer 5:00 · hypo clearing
agent (off) · wash (Ilford fill-and-invert method, or running water 10:00) ·
wetting agent 0:30.
Each step has a duration, an agitation pattern and an optional how-to text.
Agitation pattern types:
- intermittent (e.g. 60 s continuous, then 10 s every minute)
- continuous
- stand / semi-stand
- none

There is also an inversion pace (default one inversion every 2 s).
The setting for what happens between steps lives here too: **wait for me**
(default) or **keep going**.

### 6. The session (most important, design every state)
The phone lies on the table. Always visible: current step name, a **huge
remaining time**, what's next, and progress through all steps. States:
- **Ready / pour:** "Pour developer", amounts, giant **Start**.
- **Agitate:** a strong visual beat pulsing at the inversion pace (one beat
  per inversion), an inversion counter, and time left in this burst.
- **Rest:** calm. "Don't touch the tank", with a countdown to the next
  agitation.
- **Last 10 seconds of a step:** a heightened countdown.
- **Dump & pour:** "Dump developer → pour stop bath", amounts, a giant
  **Next** across the bottom. Show a brief **Undo** after Next is pressed.
- **Guided wash (Ilford method):** fill 1 of 3 → invert 5 times (counted) →
  dump; fill 2 → 10 inversions; fill 3 → 20 inversions. Next between fills.
- **Running-water wash:** a simple countdown.
- **Paused:** a clear warning that the chemistry keeps working.
- Small secondary controls: ±30 s on the current step, pause, abort (with a
  confirm).
- **Done:** a summary of the run, plus **Add a note** ("how did it turn
  out?").

Sound runs alongside the visuals but isn't designed here. For reference: a
chime when agitation starts, a metronome tick per inversion (no stop sound),
pips in the last 10 seconds, and a distinct chime for dump & pour. There are
no spoken words.

### 7. Share and import
- Share a recipe through the iOS share sheet.
- An import preview when a recipe arrives from someone ("Ani's recipe: Tri-X
  · Rodinal 1+50 · 13:00 · 2 notes → Import"), including a "you already have
  this, updated" case.

### 8. Settings
Author name; 35mm and 120 volumes (300 / 500 ml); default process; transition
mode; inversion pace; sounds on/off and volume; °C/°F; theme; export and
import all data.

## Deliverables

- A small visual system: type scale (including the giant timer numerals),
  colour tokens for light and dark, session-state colours, spacing, and
  components.
- High-fidelity iPhone screens for everything above. Show the session states
  side by side so their differences are obvious.
- Use realistic content: Kodak Tri-X 400, Ilford HP5 Plus, Fomapan 100;
  Rodinal 1+50, Kodak D-76 stock, Ilfosol 3 1+9; times like 13:00, 9:30,
  7:45.
- Keep it buildable in Flutter: standard layouts and no effects that depend
  on platform-specific blur tricks.
