import 'dart:async';

import 'package:drktimes/platform/volume_keys.dart';

class FakeVolumeKeys implements VolumeKeys {
  final _controller = StreamController<VolumeKey>.broadcast();
  bool armed = false;

  /// Emits a press only while armed, as the native side does.
  void emit(VolumeKey key) {
    if (armed) _controller.add(key);
  }

  @override
  Future<void> setArmed(bool armed) async => this.armed = armed;

  @override
  Stream<VolumeKey> get presses => _controller.stream;
}
