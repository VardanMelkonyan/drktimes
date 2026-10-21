import 'dart:math' as math;

/// `13:00`, `6:45`, `1:00:00` for a duration in seconds.
String formatTime(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  final ss = sec.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

/// Parses `13:00`, `1:30:00`, `90` (seconds) → seconds; null if not a time.
int? parseTime(String input) {
  final t = input.trim();
  if (t.isEmpty) return null;
  final parts = t.split(':');
  if (parts.any((p) => int.tryParse(p) == null || int.parse(p) < 0)) {
    return null;
  }
  final n = parts.map(int.parse).toList();
  switch (n.length) {
    case 1:
      return n[0];
    case 2:
      return n[0] * 60 + n[1];
    case 3:
      return n[0] * 3600 + n[1] * 60 + n[2];
  }
  return null;
}

/// `20 °C` or `68 °F`.
String formatTemp(int tempC, {bool fahrenheit = false}) =>
    fahrenheit ? '${(tempC * 9 / 5 + 32).round()} °F' : '$tempC °C';

/// Push/pull label for an exposure index relative to box speed:
/// `push +1`, `pull −1`; null within half a stop.
String? pushPullLabel(int ei, num boxIso) {
  if (boxIso <= 0) return null;
  final stops = (_log2(ei / boxIso) * 2).round() / 2;
  if (stops.abs() < 0.5) return null;
  final n = stops == stops.roundToDouble()
      ? stops.abs().toStringAsFixed(0)
      : stops.abs().toString();
  return stops > 0 ? 'push +$n' : 'pull −$n';
}

double _log2(double x) => x <= 0 ? 0 : math.log(x) / math.ln2;
