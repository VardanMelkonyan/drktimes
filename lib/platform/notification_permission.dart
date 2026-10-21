import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum PermissionState { granted, denied, notDetermined }

/// Notification permission (iOS authorisation / Android 13+
/// `POST_NOTIFICATIONS`). The state is always read from the OS, never stored.
abstract interface class NotificationPermission {
  Future<PermissionState> status();
  Future<PermissionState> request();
  Future<void> openSystemSettings();
}

class PluginNotificationPermission implements NotificationPermission {
  PluginNotificationPermission(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<PermissionState> status() async {
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final o = await ios?.checkPermissions();
      return (o?.isEnabled ?? false)
          ? PermissionState.granted
          : PermissionState.denied;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final enabled = await android?.areNotificationsEnabled();
    return (enabled ?? true) ? PermissionState.granted : PermissionState.denied;
  }

  @override
  Future<PermissionState> request() async {
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final ok = await ios?.requestPermissions(alert: true, sound: true);
      return (ok ?? false) ? PermissionState.granted : PermissionState.denied;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ok = await android?.requestNotificationsPermission();
    return (ok ?? true) ? PermissionState.granted : PermissionState.denied;
  }

  @override
  Future<void> openSystemSettings() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.openAppNotificationSettings();
    // iOS: opening Settings needs url_launcher's app-settings URL; the session
    // banner falls back to explaining the path when this is a no-op.
  }
}
