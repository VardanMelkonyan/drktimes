/// The summary line over a combination's visible times (FR-017).
class TimeSummary {
  const TimeSummary({
    required this.count,
    required this.medianS,
    required this.minS,
    required this.maxS,
  });

  final int count;
  final int medianS, minS, maxS;
}

/// Null with fewer than two times.
TimeSummary? summarise(List<int> timesS) {
  if (timesS.length < 2) return null;
  final s = [...timesS]..sort();
  final mid = s.length ~/ 2;
  final median = s.length.isOdd ? s[mid].toDouble() : (s[mid - 1] + s[mid]) / 2;
  return TimeSummary(
    count: s.length,
    medianS: (median / 15).round() * 15,
    minS: s.first,
    maxS: s.last,
  );
}
