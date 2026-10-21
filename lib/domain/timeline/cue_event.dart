enum CueKind { agitateStart, tick, finalPip, dumpPour }

class CueEvent {
  const CueEvent({
    required this.at,
    required this.tankSlot,
    required this.kind,
    required this.title,
    required this.body,
    this.background = false,
  });

  final DateTime at;
  final int tankSlot;
  final CueKind kind;
  final String title, body;

  /// Whether this cue is worth a background notification. Ticks and all but
  /// the first of the last-10 s pips are foreground-only (research R3).
  final bool background;

  @override
  String toString() => 'Cue(${kind.name} t$tankSlot @${at.toIso8601String()})';
}
