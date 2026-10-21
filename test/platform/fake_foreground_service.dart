import 'package:drktimes/platform/foreground_service.dart';

class FakeForegroundService implements SessionForegroundService {
  bool running = false;
  int starts = 0;
  int stops = 0;
  List<TankLine> lines = [];

  @override
  Future<void> start() async {
    running = true;
    starts++;
  }

  @override
  Future<void> update(List<TankLine> lines) async => this.lines = lines;

  @override
  Future<void> stop() async {
    running = false;
    stops++;
    lines = [];
  }
}
