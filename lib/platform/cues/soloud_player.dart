import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../../domain/timeline/cue_event.dart';
import 'cue_player.dart';

String _asset(CueKind kind, int slot) =>
    'assets/sounds/cue_${switch (kind) {
      CueKind.agitateStart => 'agitate',
      CueKind.tick => 'tick',
      CueKind.finalPip => 'pip',
      CueKind.dumpPour => 'dump',
    }}_t$slot.wav';

/// Low-latency sample player (research R2): all 12 samples are preloaded.
class SoloudSamplePlayer implements SamplePlayer {
  final _sources = <String, AudioSource>{};
  final SoLoud _soloud = SoLoud.instance;

  /// Debug-only: scheduled-vs-actual play-time logger for the R3 spike.
  void Function(CueKind kind, int slot)? onPlayed;

  @override
  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.assistanceSonification,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
      ),
    );
    await _soloud.init();
    for (final kind in CueKind.values) {
      for (var slot = 1; slot <= 3; slot++) {
        final path = _asset(kind, slot);
        _sources[path] = await _soloud.loadAsset(path);
      }
    }
  }

  @override
  void play(CueKind kind, int tankSlot, double volume) {
    final source = _sources[_asset(kind, tankSlot)];
    if (source == null) return;
    _soloud.play(source, volume: volume);
    if (kDebugMode) onPlayed?.call(kind, tankSlot);
  }

  @override
  Future<void> dispose() async {
    _soloud.deinit();
  }
}

/// [AudioFocus] over `audio_session` interruption events.
class AudioSessionFocus implements AudioFocus {
  AudioSession? _session;

  Future<AudioSession> get _s async => _session ??= await AudioSession.instance;

  @override
  Stream<bool> get interruptions async* {
    final s = await _s;
    yield* s.interruptionEventStream.map((e) => e.begin);
  }

  @override
  Future<void> reactivate() async {
    final s = await _s;
    await s.setActive(true);
  }
}
