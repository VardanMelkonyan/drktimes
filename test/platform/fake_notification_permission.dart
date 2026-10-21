import 'package:drktimes/platform/notification_permission.dart';

class FakeNotificationPermission implements NotificationPermission {
  FakeNotificationPermission([
    this.state = PermissionState.notDetermined,
    this.grantOnRequest = true,
  ]);

  PermissionState state;

  /// What a request resolves to.
  bool grantOnRequest;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<PermissionState> status() async => state;

  @override
  Future<PermissionState> request() async {
    requests++;
    state = grantOnRequest ? PermissionState.granted : PermissionState.denied;
    return state;
  }

  @override
  Future<void> openSystemSettings() async => settingsOpened++;
}
