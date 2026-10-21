import 'package:flutter/painting.dart';

/// Colour tokens transcribed from design/develop/drk.css (.th-dark / .th-light).
class DrkPalette {
  const DrkPalette({
    required this.bg,
    required this.s1,
    required this.s2,
    required this.ln,
    required this.ln2,
    required this.fg,
    required this.mut,
    required this.dim,
    required this.inv,
    required this.t1,
    required this.t2,
    required this.t3,
  });

  final Color bg, s1, s2, ln, ln2, fg, mut, dim, inv, t1, t2, t3;

  Color tank(int slot) => switch (slot) {
    1 => t1,
    2 => t2,
    _ => t3,
  };

  static const dark = DrkPalette(
    bg: Color(0xFF0D0C0A),
    s1: Color(0xFF15130F),
    s2: Color(0xFF1E1B15),
    ln: Color(0xFF2B2720),
    ln2: Color(0xFF463F33),
    fg: Color(0xFFECE6D8),
    mut: Color(0xFFA39B8A),
    dim: Color(0xFF6E675A),
    inv: Color(0xFF0D0C0A),
    t1: Color(0xFFF2A93B),
    t2: Color(0xFF5FC6CF),
    t3: Color(0xFFB9A5F3),
  );

  static const light = DrkPalette(
    bg: Color(0xFFF3EFE6),
    s1: Color(0xFFFBF9F4),
    s2: Color(0xFFE8E3D6),
    ln: Color(0xFFD9D2C3),
    ln2: Color(0xFFB0A895),
    fg: Color(0xFF17150F),
    mut: Color(0xFF5C5649),
    dim: Color(0xFF8F8879),
    inv: Color(0xFFF3EFE6),
    t1: Color(0xFF955500),
    t2: Color(0xFF00707A),
    t3: Color(0xFF5A44B6),
  );

  /// `.th-red` (safelight, red channel only). Used for the Print-mode preview
  /// only; there is no red app theme in Part 1.
  static const red = DrkPalette(
    bg: Color(0xFF000000),
    s1: Color(0xFF0C0000),
    s2: Color(0xFF160000),
    ln: Color(0xFF2A0000),
    ln2: Color(0xFF4D0000),
    fg: Color(0xFFFF0000),
    mut: Color(0xFFF00000),
    dim: Color(0xFF7A0000),
    inv: Color(0xFF000000),
    t1: Color(0xFFFF0000),
    t2: Color(0xFFFF0000),
    t3: Color(0xFFFF0000),
  );
}

const fontFamily = 'JetBrainsMono';

/// Type scale (drk.css): size / line height / weight / letter spacing in em.
class DrkType {
  const DrkType._();

  static const fontFeatures = [FontFeature.tabularFigures()];

  static TextStyle _s(double size, double line, FontWeight w, double ls) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: line / size,
        fontWeight: w,
        letterSpacing: ls * size,
        fontFeatures: fontFeatures,
      );

  static final tx = _s(124, 124, FontWeight.w700, -.05);
  static final tl = _s(64, 64, FontWeight.w700, -.045);
  static final tm = _s(34, 34, FontWeight.w700, -.04);
  static final dp = _s(28, 32, FontWeight.w700, -.02);
  static final ti = _s(20, 26, FontWeight.w700, -.01);
  static final bd = _s(15, 22, FontWeight.w400, 0);
  static final sm = _s(13, 19, FontWeight.w400, 0);
  static final lbl = _s(11, 16, FontWeight.w600, .14);
}

/// Spacing scale, radius and target sizes.
class DrkSpace {
  const DrkSpace._();

  static const s4 = 4.0, s8 = 8.0, s12 = 12.0, s16 = 16.0;
  static const s20 = 20.0, s24 = 24.0, s32 = 32.0, s40 = 40.0, s48 = 48.0;
  static const radius = 3.0;

  /// Secondary controls / primary session buttons / the Next and Start button.
  static const target = 44.0, targetSession = 72.0, targetNext = 112.0;
}
