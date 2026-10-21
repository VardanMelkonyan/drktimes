import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while a session is active (FR-037).
abstract interface class ScreenWake {
  Future<void> hold();
  Future<void> release();
}

class WakelockPlusScreenWake implements ScreenWake {
  @override
  Future<void> hold() => WakelockPlus.enable();

  @override
  Future<void> release() => WakelockPlus.disable();
}
