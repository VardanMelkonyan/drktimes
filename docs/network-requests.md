# Network requests the app can make

The app is offline-first. Everything below is optional or has an off switch, and none of it
runs for a core flow (lookup, recipes, sessions). Source of truth: the "Network requests"
table in `specs/002-community-times/plan.md`.

| Request | When | Sent | Never sent |
|---|---|---|---|
| `GET <dataset>/manifest.json` | Dataset update check (spec 001) | nothing | any identifier |
| `GET <feed url>` or `POST <project>/rest/v1/rpc/community_feed` | At most once per 24 h per configured community source, when the app opens or a combination page is opened with a stale cache. None if no source is configured. | the source's public key (project sources only) | contribution ID, any user data |
| `POST <project>/rest/v1/rpc/submit_time` | Only with **Share my times** on: after an eligible session completes, once per past session when the switch is turned on, and retried while the queue is not empty | catalog film id, catalog developer id, dilution, ISO, temperature (whole °C), time (seconds), and a random contribution ID | name, notes, device model, locale, app version, any timestamp |

## What the contribution ID is

A random version-4 UUID, created on the device the first time sharing is switched on. It is
not derived from the user or the device, never leaves it except in `submit_time`, and is never
returned by any read. It is not part of backups or exports. **Reset contribution ID** in
Settings deletes it; the next submission creates a new one. It lets the community source count
each install once and let a repeat submission replace the earlier one.

## What the source host sees

Any request reveals the device's IP address to the host that serves it. Times already shared
are released as CC0 and cannot be recalled. Switching sharing off stops further sending and
clears anything still queued.
