import 'dart:async';

import 'package:drktimes/domain/clock.dart';
import 'package:drktimes/domain/timeline/cue_event.dart';
import 'package:drktimes/platform/cues/cue_player.dart';
import 'package:flutter_test/flutter_test.dart';

class _Samples implements SamplePlayer {
  final played = <(CueKind, int, double)>[];
  @override
  Future<void> init() async {}
  @override
  void play(CueKind kind, int tankSlot, double volume) =>
      played.add((kind, tankSlot, volume));
  @override
  Future<void> dispose() async {}
}

class _Focus implements AudioFocus {
  final controller = StreamController<bool>.broadcast();
  int reactivated = 0;
  @override
  Stream<bool> get interruptions => controller.stream;
  @override
  Future<void> reactivate() async => reactivated++;
}

void main() {
  late FakeClock clock;
  late _Samples samples;
  late _Focus focus;
  late CuePlayer player;
  var soundOn = true;
  var volume = 0.7;

  CueEvent cue(int seconds, [CueKind k = CueKind.tick, int slot = 1]) =>
      CueEvent(
        at: clock.now().add(Duration(seconds: seconds)),
        tankSlot: slot,
        kind: k,
        title: '',
        body: '',
      );

  setUp(() {
    clock = FakeClock();
    samples = _Samples();
    focus = _Focus();
    soundOn = true;
    volume = 0.7;
    player = CuePlayer(
      clock: clock,
      samples: samples,
      focus: focus,
      soundOn: () => soundOn,
      volume: () => volume,
    );
  });
  tearDown(() => player.dispose());

  test('plays each cue when its time arrives, with tank and volume', () {
    player.play([cue(2, CueKind.tick, 2), cue(4, CueKind.dumpPour, 3)]);
    clock.advance(const Duration(seconds: 1));
    player.pump();
    expect(samples.played, isEmpty);
    clock.advance(const Duration(seconds: 1));
    player.pump();
    expect(samples.played, [(CueKind.tick, 2, 0.7)]);
    clock.advance(const Duration(seconds: 5));
    player.pump();
    expect(samples.played.last, (CueKind.dumpPour, 3, 0.7));
  });

  test('sound off plays nothing', () {
    soundOn = false;
    player.play([cue(1)]);
    clock.advance(const Duration(seconds: 2));
    player.pump();
    expect(samples.played, isEmpty);
  });

  test(
    'cues inside an interruption are skipped, later ones still play',
    () async {
      player.play([cue(2), cue(10), cue(20)]);
      focus.controller.add(true); // call begins
      await Future<void>.delayed(Duration.zero);
      clock.advance(const Duration(seconds: 12));
      player.pump();
      expect(samples.played, isEmpty);

      focus.controller.add(false); // call ends
      await Future<void>.delayed(Duration.zero);
      expect(focus.reactivated, 1);
      player.pump();
      expect(samples.played, isEmpty, reason: 'missed cues are not replayed');

      clock.advance(const Duration(seconds: 8));
      player.pump();
      expect(samples.played, hasLength(1), reason: 'timing carries on');
    },
  );
}
