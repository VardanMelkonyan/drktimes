import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

enum VolumeKey { up, down }

/// Android volume buttons as Next (FR-043, research R11). Consumed only while
/// armed; never on iOS.
abstract interface class VolumeKeys {
  Future<void> setArmed(bool armed);
  Stream<VolumeKey> get presses;
}

class MethodChannelVolumeKeys implements VolumeKeys {
  MethodChannelVolumeKeys() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'volumeKey') {
        final key = (call.arguments as Map)['key'] as String;
        _presses.add(key == 'up' ? VolumeKey.up : VolumeKey.down);
      }
    });
  }

  static const _channel = MethodChannel('am.drktimes/volume_keys');
  final _presses = StreamController<VolumeKey>.broadcast();

  @override
  Future<void> setArmed(bool armed) =>
      _channel.invokeMethod<void>('setArmed', {'armed': armed});

  @override
  Stream<VolumeKey> get presses => _presses.stream;
}

class NoopVolumeKeys implements VolumeKeys {
  const NoopVolumeKeys();

  @override
  Future<void> setArmed(bool armed) async {}

  @override
  Stream<VolumeKey> get presses => const Stream.empty();
}

VolumeKeys createVolumeKeys() =>
    Platform.isAndroid ? MethodChannelVolumeKeys() : const NoopVolumeKeys();
