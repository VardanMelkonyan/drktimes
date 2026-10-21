# Contract: Platform Channels and Background Cues

These are the native-boundary interfaces the Dart app depends on. Each one
sits behind a Dart interface with a fake implementation for tests (research
R13).

## 1. `CueScheduler` (research R2 and R3)

```dart
abstract interface class CueScheduler {
  /// Foreground: play [events] at their wall-clock times (sample player).
  void playForeground(List<CueEvent> events);

  /// Called on app pause: schedule attention cues (no ticks on iOS)
  /// as local notifications, rolling window ≤ 60 across all tanks.
  Future<void> scheduleBackground(List<CueEvent> events);

  /// Called on app resume and on session end: cancel all pending.
  Future<void> cancelBackground();
}

class CueEvent {
  final DateTime at;           // wall clock
  final int tankSlot;          // 1..3 → pitch set (FR-069)
  final CueKind kind;          // agitateStart | tick | finalPip | dumpPour
  final String title;          // "Tank 2 · Dump developer → pour stop bath"
  final String body;           // "Agitate 10 s · 5 inversions"
}
```

**Notification sound assets.** These are bundled per tank and per kind:
`cue_<kind>_t<slot>`. On iOS the files are `.caf`, at most 30 s each. On
Android they are `res/raw` files.

**Notification channels:**
- **iOS:** interruption level `timeSensitive`, using the Time Sensitive
  Notifications capability.
- **Android:** a channel `session_cues` with high importance and the custom
  sound, plus a channel `session_ongoing` for the foreground service's
  ongoing notification.

## 2. Android foreground service

```dart
abstract interface class SessionForegroundService {
  Future<void> start();                    // first active session
  Future<void> update(List<TankLine> lines);
  Future<void> stop();                     // last session ended/aborted
}
class TankLine { final int tankSlot; final String text; } // "T1 Developer · rest · 4:12"
```

Implementations: Android (below), an iOS no-op, and
`test/platform/fake_foreground_service.dart`.

- Start it when the first session starts, and stop it when the last session
  ends or is aborted.
- `foregroundServiceType="mediaPlayback"`.
- The ongoing notification shows one line per tank, for example
  "T1 Developer · rest · 4:12".
- The service runs the same Dart cue scheduler, through a background isolate
  (`flutter_foreground_task`) or a headless engine. The spike in research R3
  decides which.

## 3. Volume key → Next (Android only, FR-043, research R11)

```dart
enum VolumeKey { up, down }
abstract interface class VolumeKeys {
  Future<void> setArmed(bool armed);
  Stream<VolumeKey> get presses;
}
```

Implementations: the Android MethodChannel (below), an iOS no-op (never arms,
never emits), and `test/platform/fake_volume_keys.dart`.

**MethodChannel `am.drktimes/volume_keys`:**

| Direction | Method | Payload | Meaning |
|---|---|---|---|
| Dart → native | `setArmed` | `{armed: bool}` | Consume volume keys only while true (a session is awaiting Next and the setting is on) |
| native → Dart | `volumeKey` | `{key: "up" \| "down"}` | Either key acts as Next |

When not armed, the native side MUST NOT consume key events, so the system
volume works normally. On iOS there is no channel at all.

## 4. Screen wake

```dart
abstract interface class ScreenWake {
  Future<void> hold();     // while ≥ 1 session is active
  Future<void> release();  // when the last one ends
}
```

Implementations: `WakelockPlusScreenWake` (`wakelock_plus`) and
`test/platform/fake_screen_wake.dart`.

## 5. Incoming links and files

```dart
sealed class IncomingPayload {}
class IncomingLink extends IncomingPayload { final Uri uri; }
class IncomingFile extends IncomingPayload { final String name; final Uint8List bytes; }
abstract interface class Intake { Stream<IncomingPayload> get payloads; }
```

Implementations: the real one (below) and `test/platform/fake_intake.dart`
(`emitLink`, `emitFile`).

- **Links:** `app_links` URI stream to the go_router route `/import`
  (`contracts/links-and-files.md` §1).
- **Files:** the platform open-file intent or document handler, which reads
  the bytes and goes to `/import` (recipe) or `/backup/import` (backup).

## 6. Notification permission (FR-048, spec edge case "Notifications not allowed")

```dart
enum PermissionState { granted, denied, notDetermined }
abstract interface class NotificationPermission {
  Future<PermissionState> status();
  Future<PermissionState> request();      // iOS authorisation / Android 13+ POST_NOTIFICATIONS
  Future<void> openSystemSettings();
}
```

**Rules:**
- Request once, at the first session start, before the timer begins
  (`notifications_asked`).
- When the state is `denied`, the session still runs, `scheduleBackground` is
  skipped, and the session screen shows the "Background cues are off" banner.
- The state is always read from the OS, never stored.

Implementations: the real one (in `lib/platform/notification_permission.dart`,
built on `flutter_local_notifications`) and
`test/platform/fake_notification_permission.dart`.
