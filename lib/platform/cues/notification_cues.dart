import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/timeline/cue_event.dart';
import '../../domain/sessions.dart' show maxBackgroundCues;

/// Background cues as local notifications (research R3).
abstract interface class BackgroundCues {
  Future<void> schedule(List<CueEvent> events);
  Future<void> cancel();
}

String _sound(CueKind kind, int slot) =>
    'cue_${switch (kind) {
      CueKind.agitateStart => 'agitate',
      CueKind.tick => 'tick',
      CueKind.finalPip => 'pip',
      CueKind.dumpPour => 'dump',
    }}_t$slot';

class NotificationCues implements BackgroundCues {
  NotificationCues(this.plugin);

  final FlutterLocalNotificationsPlugin plugin;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Non-tick events only, a rolling window of at most 60.
  @override
  Future<void> schedule(List<CueEvent> events) async {
    await init();
    final now = DateTime.now().toUtc();
    final due = [
      for (final e in events)
        if (e.background && e.kind != CueKind.tick && e.at.isAfter(now)) e,
    ]..sort((a, b) => a.at.compareTo(b.at));
    final window = due.take(maxBackgroundCues).toList();
    for (final (i, e) in window.indexed) {
      final sound = _sound(e.kind, e.tankSlot);
      await plugin.zonedSchedule(
        id: i,
        title: e.title,
        body: e.body,
        scheduledDate: tz.TZDateTime.from(e.at, tz.UTC),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'session_cues',
            'Session cues',
            channelDescription: 'Agitation, last-10-seconds and dump cues',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound(sound),
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            sound: '$sound.caf',
            presentSound: true,
            presentAlert: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
      );
    }
  }

  @override
  Future<void> cancel() async {
    await init();
    await plugin.cancelAllPendingNotifications();
  }
}

bool get isMobile => Platform.isAndroid || Platform.isIOS;
