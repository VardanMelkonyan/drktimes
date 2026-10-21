import 'dart:math' as math;

import 'package:drktimes/app/theme/tokens.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

double _lum(Color c) {
  double f(double v) =>
      v <= .03928 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
  return .2126 * f(c.r) + .7152 * f(c.g) + .0722 * f(c.b);
}

double ratio(Color a, Color b) {
  final x = _lum(a), y = _lum(b);
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

void main() {
  for (final (name, p) in [
    ('dark', DrkPalette.dark),
    ('light', DrkPalette.light),
  ]) {
    test('$name: text tokens reach 4.5:1 on the background', () {
      for (final (n, c) in [
        ('fg', p.fg),
        ('mut', p.mut),
        ('t1', p.t1),
        ('t2', p.t2),
        ('t3', p.t3),
      ]) {
        expect(ratio(c, p.bg), greaterThanOrEqualTo(4.5), reason: '$name $n');
      }
    });
  }
}
