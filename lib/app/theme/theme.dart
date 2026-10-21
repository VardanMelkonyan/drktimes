import 'package:flutter/material.dart';

import 'tokens.dart';

/// The three screen-states that differ in numeral weight and chip shape
/// (design/develop/Main.dc.html §04).
enum SessionVisual {
  ready,
  agitate,
  rest,
  final10,
  dumpPour,
  wash,
  paused,
  done,
}

enum ChipShape {
  outline, // Ready, Wash
  filled, // Agitate
  hairline, // Rest
  hatched, // Last 10 s
  doubleRule, // Dump → pour
  striped, // Paused
  checked, // Done
}

class DrkTokens extends ThemeExtension<DrkTokens> {
  const DrkTokens(this.palette);

  final DrkPalette palette;

  ChipShape chipShape(SessionVisual v) => switch (v) {
    SessionVisual.ready || SessionVisual.wash => ChipShape.outline,
    SessionVisual.agitate => ChipShape.filled,
    SessionVisual.rest => ChipShape.hairline,
    SessionVisual.final10 => ChipShape.hatched,
    SessionVisual.dumpPour => ChipShape.doubleRule,
    SessionVisual.paused => ChipShape.striped,
    SessionVisual.done => ChipShape.checked,
  };

  /// 800 act / 700 running / 300 rest, with ready / paused / done as drawn.
  FontWeight numeralWeight(SessionVisual v) => switch (v) {
    SessionVisual.agitate || SessionVisual.final10 => FontWeight.w800,
    SessionVisual.dumpPour || SessionVisual.wash => FontWeight.w700,
    SessionVisual.rest => FontWeight.w300,
    SessionVisual.ready || SessionVisual.paused => FontWeight.w400,
    SessionVisual.done => FontWeight.w500,
  };

  /// Tank identity: the glyph and number carry it, hue is a bonus (§05).
  Color tankColor(int slot) => palette.tank(slot);

  @override
  DrkTokens copyWith({DrkPalette? palette}) =>
      DrkTokens(palette ?? this.palette);

  @override
  DrkTokens lerp(DrkTokens? other, double t) => t < .5 ? this : other ?? this;
}

/// Tank glyphs: circle, triangle, square.
enum TankGlyph { circle, triangle, square }

TankGlyph tankGlyph(int slot) => switch (slot) {
  1 => TankGlyph.circle,
  2 => TankGlyph.triangle,
  _ => TankGlyph.square,
};

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? DrkPalette.dark : DrkPalette.light;
  final base = TextStyle(fontFamily: fontFamily, color: p.fg);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    splashFactory: NoSplash.splashFactory,
    shadowColor: Colors.transparent,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: p.fg,
      onPrimary: p.inv,
      secondary: p.mut,
      onSecondary: p.inv,
      error: p.fg,
      onError: p.inv,
      surface: p.bg,
      onSurface: p.fg,
      surfaceContainerHighest: p.s2,
      outline: p.ln2,
      outlineVariant: p.ln,
    ),
    textTheme: TextTheme(
      displayLarge: DrkType.tx.copyWith(color: p.fg),
      displayMedium: DrkType.tl.copyWith(color: p.fg),
      displaySmall: DrkType.tm.copyWith(color: p.fg),
      headlineMedium: DrkType.dp.copyWith(color: p.fg),
      titleMedium: DrkType.ti.copyWith(color: p.fg),
      bodyMedium: DrkType.bd.copyWith(color: p.fg),
      bodySmall: DrkType.sm.copyWith(color: p.mut),
      labelSmall: DrkType.lbl.copyWith(color: p.mut),
      labelLarge: base,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.fg,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerColor: p.ln2,
    extensions: [DrkTokens(p)],
  );
}

final ThemeData darkTheme = buildTheme(Brightness.dark);
final ThemeData lightTheme = buildTheme(Brightness.light);

extension DrkContext on BuildContext {
  DrkTokens get drk => Theme.of(this).extension<DrkTokens>()!;
  DrkPalette get pal => drk.palette;
}
