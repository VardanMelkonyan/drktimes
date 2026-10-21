import 'dart:math' as math;

/// k in `t₂ = t₁ · e^(−k·(T₂ − T₁))` (research R7).
const temperatureK = 0.081;

const estimateMinC = 18;
const estimateMaxC = 26;

const temperatureEstimateCitation =
    "Based on Ilford's published time/temperature compensation chart; "
    'estimate only';

/// Estimated time at [toC] given [baseTimeS] at [fromC], rounded to 15 s.
/// Null outside 18–26 °C (for either temperature).
int? estimateTimeS(int baseTimeS, {required int fromC, required int toC}) {
  bool inRange(int c) => c >= estimateMinC && c <= estimateMaxC;
  if (!inRange(fromC) || !inRange(toC)) return null;
  final t = baseTimeS * math.exp(-temperatureK * (toC - fromC));
  final rounded = (t / 15).round() * 15;
  return rounded < 15 ? 15 : rounded;
}
