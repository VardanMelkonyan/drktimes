import 'combination_key.dart';

/// Chemistry amounts for a dilution and tank volume (FR-026), rounded to
/// 0.1 ml for display.
class Amounts {
  const Amounts(this.solutionsMl, this.waterMl);

  /// Stock volumes: one for `1+N`, two for `1+A+B`, the whole volume for
  /// `stock`/`working`.
  final List<double> solutionsMl;
  final double waterMl;

  static String _ml(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  String describe() {
    final parts = [for (final s in solutionsMl) '${_ml(s)} ml'];
    if (waterMl > 0) parts.add('${_ml(waterMl)} ml water');
    return parts.join(' + ');
  }
}

double _round1(double v) => (v * 10).round() / 10;

Amounts amountsFor(String dilution, int volumeMl) {
  final d = normaliseDilution(dilution);
  if (d == 'stock' || d == 'working') {
    return Amounts([volumeMl.toDouble()], 0);
  }
  final ratios = d.split('+').skip(1).map(double.tryParse).toList();
  if (ratios.isEmpty || ratios.any((r) => r == null)) {
    throw FormatException('not a dilution: $dilution');
  }
  final parts = ratios.cast<double>();
  final unit = volumeMl / (1 + parts.reduce((a, b) => a + b));
  if (parts.length == 1) {
    final conc = unit;
    return Amounts([_round1(conc)], _round1(volumeMl - conc));
  }
  // 1+A+B: part A is one unit, part B is A units, the rest is water.
  final a = unit;
  final b = parts[0] * unit;
  final water = parts[1] * unit;
  return Amounts([_round1(a), _round1(b)], _round1(water));
}
