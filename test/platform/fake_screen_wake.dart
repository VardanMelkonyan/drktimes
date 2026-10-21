import 'package:drktimes/platform/wake.dart';

class FakeScreenWake implements ScreenWake {
  bool held = false;
  final calls = <String>[];

  @override
  Future<void> hold() async {
    held = true;
    calls.add('hold');
  }

  @override
  Future<void> release() async {
    held = false;
    calls.add('release');
  }
}
