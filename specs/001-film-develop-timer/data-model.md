# Data Model: Film Development Timer (Develop mode)

There are two strictly separate pools (spec FR-022, FR-060):

- **Datasheet pool**: read-only. It is loaded from the bundled or updated
  dataset (`resources/devdata`, schema in `lib/devdata/models.dart`). It is
  never written by the app.
- **User pool**: lives in local storage (drift/SQLite, research R4). It is
  everything the user creates or imports. It is exported and imported with
  the exchange format (`contracts/exchange-format.schema.json`).

**Notation used below**:
- `?` marks an optional field.
- IDs are strings.
- Times are integer seconds.
- Temperatures are integer °C.
- Timestamps are UTC ISO-8601.

---

## Datasheet pool (existing, read-only)

These entities already exist in `lib/devdata/models.dart`: `Film`,
`Developer`, `Source`, `DevTime`. This feature adds derived views only.

| Derived view | Built from | Purpose |
|---|---|---|
| `CatalogFilm` | `Film`, rebrand resolution through `rebrand_of` | Search, and labelling inherited times (FR-013) |
| `DatasheetTime` | `DevTime` + `Source` | A time on a combination page, with its source (FR-010–FR-012) |

**`DatasheetTime` fields:**
- `film_id`, `developer_id`, `dilution`, `ei`, `temp_c`
- `time_s`, `time_max_s?`
- `method`: `small_tank`, `rotary`, `stand`, `tray`, `large_tank` or `other`
- `agitation_text?`
- `source`: publisher, title, `doc_code?`, `edition?`, `page?`
- `inherited_from_film_id?`: set when the time is shown through a rebrand
- `rebrand_basis?`: `stated` or `reported`

**Rules:**
- **Default run time** = `time_s` if there is no range, otherwise the
  midpoint `(time_s + time_max_s) / 2`, rounded to 15 s (FR-011).
- **Primary rows** are those with `method = small_tank` (FR-012).
- **Temperature** is already an integer in the dataset. Non-integer values,
  if any appear, are rounded for grouping (FR-073).

---

## User pool

### UserFilm / UserDeveloper (FR-015)

| Field | Type | Rules |
|---|---|---|
| `id` | UUIDv4 | Permanent identity; travels in shared recipes |
| `brand` | string | Required, 1–60 chars |
| `name` | string | Required, 1–80 chars |
| `box_iso` | int | Films only; 1–25600 |
| `matched_catalog_id?` | string | Set when the user accepts a catalogue match on import (FR-058) |
| `created_at` | timestamp | |

A user-added entry is shown with a "user-added" marker. Once
`matched_catalog_id` is set, every reference resolves to the catalogue entry.

### FilmRef / DeveloperRef

A tagged reference that is used everywhere a film or developer is named:
`{kind: catalog, id}` or `{kind: user, id}`.

### CombinationKey (FR-016, FR-073)

This is a value object, not stored as its own row.

| Part | Normalisation |
|---|---|
| `film` | the FilmRef **as picked** (rebrands are not merged) |
| `developer` | DeveloperRef |
| `dilution` | `1+N`, `1+A+B`, `stock` or `working`. Separators `:`, `/` and spaces are normalised to `+`, e.g. `1:50` becomes `1+50` |
| `ei` | int |
| `temp_c` | int. A °F entry is converted with `round((F − 32) × 5/9)` |

The canonical string is `film|developer|dilution|ei|temp_c`. It is used for
grouping, for favourites, and later for the community catalogue.

**Rebrand family** (FR-018): the set of FilmRefs that share the root
`rebrand_of` chain. The combination page queries the same key with the
family's other films to fill the secondary section.

### Recipe (FR-019–FR-021, FR-023)

| Field | Type | Rules |
|---|---|---|
| `id` | UUIDv4 | Permanent identity |
| `version` | int ≥ 1 | Incremented on every saved edit |
| `updated_at` | timestamp | Tie-breaker on import (research R5) |
| `created_at` | timestamp | |
| `author_name` | string | Copied from Settings when created; "unknown author" if empty on import |
| `ownership` | enum | `own` or `received` |
| `origin` | object | One of: `{kind: datasheet, source_id, page?}`, `{kind: scratch}`, `{kind: copy_of, recipe_id, author_name}`, or `{kind: temperature_estimate, base: <origin>}` |
| `key` | CombinationKey | Required |
| `dev_time_s` | int | 30–7200 |
| `dev_agitation` | AgitationPattern | Required |
| `process?` | Process | Overrides the default process when set |
| `hidden` | bool | Received recipes only (FR-059) |

**Rules:**
- A `received` recipe is read-only. Editing it creates a new `own` recipe
  with `origin.kind = copy_of` (FR-023).
- Datasheet times are never Recipes. Customising a datasheet time creates an
  `own` Recipe with `origin.kind = datasheet`.
- Deleting is allowed for own recipes, with a confirm. Received recipes are
  hidden or removed.

### Note (FR-021)

| Field | Type | Rules |
|---|---|---|
| `id` | UUIDv4 | |
| `recipe_id` | Recipe.id | |
| `author_name` | string | |
| `created_at` | timestamp | Notes are ordered by this |
| `text` | string | 1–4000 chars |

Notes belong to a recipe and travel with it when shared. The combination page
shows the union of the notes on all visible recipes in the group (FR-017).

### Process / Step / AgitationPattern / WashMethod (FR-029–FR-035)

**Process:**

| Field | Type | Rules |
|---|---|---|
| `id` | UUIDv4 | The default process has a fixed id `default` |
| `steps` | ordered list of Step | At least 1 enabled step, and exactly one `developer` step |
| `transition_mode` | enum | `wait_for_me` (default) or `keep_going` (FR-042) |

**Step:**

| Field | Type | Rules |
|---|---|---|
| `id` | UUIDv4 | |
| `kind` | enum | `presoak`, `developer`, `stop`, `fix`, `hypo_clear`, `wash`, `wetting_agent` or `custom` |
| `name` | string | Editable display name |
| `enabled` | bool | |
| `duration_s` | int | Ignored for `developer` (it comes from the recipe or datasheet time) and for `wash` with the `ilford` method |
| `agitation` | AgitationPattern | |
| `how_to?` | string | Prefilled for the standard kinds, editable (FR-035) |
| `wash?` | WashMethod | Wash kind only |
| `chemical_dilution?` | string | Optional, for showing stop/fix/hypo amounts. If absent, the pour screen shows only the step name |

**AgitationPattern** is a tagged union:
- `intermittent`: `{initial_s, every_s, burst_s}`. Requires
  `burst_s < every_s` and `initial_s ≥ 0`.
- `continuous`: `{}`
- `stand`: `{initial_s, mid_agitation_at_s?, mid_burst_s?}`
- `none`: `{}`

**WashMethod** is a tagged union:
- `running`: `{duration_s}` (default 600)
- `ilford`: `{fills: [int]}` (default `[5, 10, 20]`, each 1–50)

The **default process** (FR-031, seeded on first launch) is exactly as in
spec US4 #2:

| Step | Enabled | Duration | Agitation |
|---|---|---|---|
| presoak | off | 60 | stand {initial 30} |
| developer | on | from recipe | intermittent {initial 60, every 60, burst 10} |
| stop | on | 60 | intermittent {60, 60, 10} |
| fix | on | 300 | intermittent {60, 60, 10} |
| hypo_clear | off | 120 | intermittent {30, 60, 10} |
| wash | on | ilford [5, 10, 20] (running alternative: 600) | none |
| wetting_agent | on | 30 | none |

The inversion pace (default 2 s) lives in Settings, not in the pattern.

### Session (FR-036–FR-050, FR-068–FR-070)

| Field | Type | Rules |
|---|---|---|
| `id` | UUIDv4 | |
| `tank_slot` | 1, 2 or 3 | Unique among active sessions |
| `tank_label` | string | Default "Tank N", renamable |
| `key` | CombinationKey | |
| `time_source` | object | `{kind: datasheet, source_id, page?}` or `{kind: recipe, recipe_id, recipe_version}` |
| `dev_time_s` | int | As started (after any range midpoint or estimate) |
| `format` | enum | `35mm` or `120` |
| `volume_ml` | int | Snapshot of the setting |
| `process_snapshot` | Process | Frozen copy, so later edits don't affect a running or finished session |
| `inversion_pace_s` | number | Snapshot |
| `status` | enum | `active`, `completed` or `aborted` |
| `aborted_at_step?` | int | |
| `started_at` | timestamp | |
| `finished_at?` | timestamp | |
| `step_runs` | list of StepRun | |

**StepRun** (the anchors for the timeline, research R1):
- `step_index`
- `started_at?`
- `ended_at?`
- `adjust_s`: the sum of the ±30 s changes
- `pauses`: a list of `{from, to?}`
- `wash_fill_index?`
- `next_pressed_at?`
- `undo_until?`

**Session state machine (per tank):**

```text
ready ──Start──▶ step_running
step_running ──(agitate/rest/final10 derived from timeline)──▶ step_running
step_running ──time up──▶ awaiting_next        [wait_for_me]
step_running ──time up──▶ step_running (next)  [keep_going]
awaiting_next ──Next──▶ step_running (next)  ──Undo (≤5 s)──▶ awaiting_next
step_running(wash/ilford) ──fill done──▶ awaiting_next(fill) ──Next──▶ next fill
any running ──Pause(confirm)──▶ paused ──Resume──▶ previous
any ──Abort(confirm)──▶ aborted
last step done ──▶ completed
```

The derived step sub-states, which drive the screen states in FR-038, are
computed by `stateAt(now)`:
- `agitate`
- `rest`
- `final10`
- `dump_pour`, the same as `awaiting_next`
- `wash_fill`

**Rules:**
- At most 3 sessions have `status = active` (FR-068).
- **Next routing** (FR-070): of the active sessions in `awaiting_next`,
  Next goes to the one with the earliest `ended_at`.
- Sessions are persisted on every transition, so they can be rebuilt after
  the app is killed (FR-003).

### Favourite (FR-051)

- `key` (CombinationKey canonical string, unique)
- `created_at`

### Settings (FR-066)

The settings form a single row with these fields:

| Field | Type | Default |
|---|---|---|
| `author_name` | string | "" |
| `volume_35mm_ml` | int | 300 |
| `volume_120_ml` | int | 500 |
| `default_process_id` | string | `default` |
| `inversion_pace_s` | number | 2.0 |
| `sound_on` | bool | true |
| `volume` | 0–1 | 0.7 |
| `volume_key_next` | bool | true (Android only) |
| `temp_unit` | `c` or `f` | `c` |
| `theme` | `system`, `dark` or `light` | `system` (the design's default look is dark) |
| `last_mode` | `develop` or `print` | `develop` (FR-002) |
| `background_limit_seen` | bool | false (the one-time explanation, research R3) |
| `notifications_asked` | bool | false (the permission prompt was shown once; the actual permission state is always read from the OS, never stored) |
| `last_format` | `35mm` or `120` | `35mm` |

### DatasetState (FR-064)

- `active_version`
- `active_sha256`
- `source`: `bundled` or `downloaded`
- `last_checked_at?`

---

## Derived logic (pure functions; the unit-test targets)

### Amounts (FR-026)

| Dilution | Result |
|---|---|
| `1+N` | concentrate = V / (1 + N), water = V − concentrate |
| `1+A+B` | part A = V / (1 + A + B), part B = A × part A, water = B × part A. For example 1+1+5 at 300 ml gives 42.9 + 42.9 + 214.3 ml |
| `stock` / `working` | V of solution, no water |

All results are rounded to 0.1 ml for display.

### Summary line (FR-017)

Shown when there are 2 or more visible times (datasheet defaults plus visible
recipes):
- `count`
- `median`, rounded to 15 s
- `min`–`max`

### Preselection (FR-071)

1. The `time_source` of the latest Session with this key, if that recipe or
   datasheet row still exists and is visible. A recipe that was edited since
   resolves to its current version.
2. Otherwise, the primary datasheet time from the newest source (by source
   edition, then retrieval date).
3. Otherwise, the user's own most recently updated recipe.
4. Otherwise, the most recently imported received recipe.

### Import merge (FR-057, FR-058, FR-061)

| Case | What happens |
|---|---|
| Unknown id | Insert as `received`. If the id matches one of the user's `own` recipes, it is treated as their own (spec edge case) |
| Known id, incoming `(version, updated_at)` is greater | Replace the fields. Notes are merged as a union by note id |
| Known id, otherwise | "Already up to date". Nothing changes |
| User film/developer whose `brand+name` (normalised as in research R9) matches a catalogue or existing user entry | Offer the match. If the user accepts, set `matched_catalog_id` or reuse the existing user id |
| Backup import | The same rules apply per entity. Settings are imported only if the user chooses "restore settings". Local data is never overwritten by older data |
