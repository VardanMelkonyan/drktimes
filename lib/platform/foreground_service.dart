import 'dart:io' show Platform;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class TankLine {
  const TankLine(this.tankSlot, this.text);

  final int tankSlot;

  /// e.g. "T1 Developer · rest · 4:12"
  final String text;
}

/// Android foreground service that keeps the process (and so the cue
/// scheduler) alive while a session runs. A no-op elsewhere.
abstract interface class SessionForegroundService {
  Future<void> start();
  Future<void> update(List<TankLine> lines);
  Future<void> stop();
}

class NoopForegroundService implements SessionForegroundService {
  const NoopForegroundService();

  @override
  Future<void> start() async {}

  @override
  Future<void> update(List<TankLine> lines) async {}

  @override
  Future<void> stop() async {}
}

class AndroidForegroundService implements SessionForegroundService {
  bool _initialised = false;

  void _init() {
    if (_initialised) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'session_ongoing',
        channelName: 'Session running',
        channelDescription: 'Shown while a development session is running',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
      ),
    );
    _initialised = true;
  }

  static String _text(List<TankLine> lines) =>
      lines.map((l) => l.text).join('\n');

  @override
  Future<void> start() async {
    _init();
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceTypes: [ForegroundServiceTypes.mediaPlayback],
      notificationTitle: 'drktimes',
      notificationText: 'Session running',
    );
  }

  @override
  Future<void> update(List<TankLine> lines) async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.updateService(
      notificationTitle: 'drktimes',
      notificationText: _text(lines),
    );
  }

  @override
  Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

SessionForegroundService createForegroundService() => Platform.isAndroid
    ? AndroidForegroundService()
    : const NoopForegroundService();
