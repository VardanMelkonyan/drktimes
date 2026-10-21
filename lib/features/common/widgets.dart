import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';

TextStyle labelStyle(BuildContext c, {bool fg = false}) =>
    DrkType.lbl.copyWith(color: fg ? c.pal.fg : c.pal.mut);

/// `.btn` family: 48 px default, `large` 72 px, `xl` 112 px.
enum DrkButtonKind { plain, primary, outline, quiet }

enum DrkButtonSize { normal, large, xl }

class DrkButton extends StatelessWidget {
  const DrkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = DrkButtonKind.plain,
    this.size = DrkButtonSize.normal,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final DrkButtonKind kind;
  final DrkButtonSize size;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final h = switch (size) {
      DrkButtonSize.normal => 48.0,
      DrkButtonSize.large => DrkSpace.targetSession,
      DrkButtonSize.xl => DrkSpace.targetNext,
    };
    final fontSize = switch (size) {
      DrkButtonSize.normal => 13.0,
      DrkButtonSize.large => 16.0,
      DrkButtonSize.xl => 24.0,
    };
    final spacing = switch (size) {
      DrkButtonSize.xl => .18,
      _ => .14,
    };
    final (bg, fg, border, width) = switch (kind) {
      DrkButtonKind.primary => (p.fg, p.inv, p.fg, 2.0),
      DrkButtonKind.outline => (Colors.transparent, p.fg, p.fg, 2.0),
      DrkButtonKind.quiet => (
        Colors.transparent,
        p.mut,
        Colors.transparent,
        1.0,
      ),
      DrkButtonKind.plain => (Colors.transparent, p.fg, p.ln2, 1.0),
    };
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : .4,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DrkSpace.radius),
            side: BorderSide(color: border, width: width),
          ),
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: h,
                minWidth: expand ? double.infinity : 0,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: fg),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        label.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: fontSize,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: fontSize * spacing,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.sect.lbl`: a small caps label followed by a dashed rule.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.bottom = 0});

  final String text;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Row(
        children: [
          Text(text.toUpperCase(), style: labelStyle(context)),
          const SizedBox(width: 10),
          Expanded(child: DashedLine(color: context.pal.ln2)),
        ],
      ),
    );
  }
}

class DashedLine extends StatelessWidget {
  const DashedLine({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 1, child: CustomPaint(painter: _Dash(color)));
}

class _Dash extends CustomPainter {
  _Dash(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + 3, 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_Dash old) => old.color != color;
}

/// `.li`: a tappable list row with a dashed bottom rule.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.child,
    this.onTap,
    this.minHeight = 64,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
    this.selected = false,
    this.boxed = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double minHeight;
  final EdgeInsets padding;
  final bool selected;
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final decoration = boxed || selected
        ? BoxDecoration(
            border: Border.all(
              color: selected ? p.fg : p.ln2,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(DrkSpace.radius),
          )
        : BoxDecoration(
            border: Border(
              bottom: BorderSide(color: p.ln2, style: BorderStyle.solid),
            ),
          );
    return Padding(
      padding: EdgeInsets.only(bottom: boxed || selected ? 4 : 0),
      child: Semantics(
        button: onTap != null,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight),
            padding: padding,
            decoration: decoration,
            child: DefaultTextStyle.merge(
              style: DrkType.bd.copyWith(color: p.fg),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// `.seg`: a segmented control.
class Seg extends StatelessWidget {
  const Seg({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: p.ln2),
        borderRadius: BorderRadius.circular(DrkSpace.radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final (i, l) in labels.indexed)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                child: InkWell(
                  onTap: () => onChanged(i),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? p.fg : Colors.transparent,
                      border: i == 0
                          ? null
                          : Border(left: BorderSide(color: p.ln2)),
                    ),
                    child: Text(
                      l.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 12 * .12,
                        color: i == selected ? p.inv : p.mut,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.step`: − value + stepper.
class DrkStepper extends StatelessWidget {
  const DrkStepper({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.height = 52,
    this.fontSize = 20,
    this.minusLabel = 'One degree colder',
    this.plusLabel = 'One degree warmer',
  });

  final String value;
  final VoidCallback? onMinus, onPlus;
  final double height, fontSize;
  final String minusLabel, plusLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget btn(
      String glyph,
      String label,
      VoidCallback? cb, {
      required bool left,
    }) => SizedBox(
      width: height + 4,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: cb,
          child: Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: left ? BorderSide(color: p.ln2) : BorderSide.none,
                left: left ? BorderSide.none : BorderSide(color: p.ln2),
              ),
            ),
            child: Text(
              glyph,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: cb == null ? p.dim : p.fg,
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: p.ln2),
        borderRadius: BorderRadius.circular(DrkSpace.radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          btn('−', minusLabel, onMinus, left: true),
          Expanded(
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.02 * fontSize,
                  color: p.fg,
                ),
              ),
            ),
          ),
          btn('+', plusLabel, onPlus, left: false),
        ],
      ),
    );
  }
}

/// `.chip`: outlined caps label.
class DrkChip extends StatelessWidget {
  const DrkChip(this.text, {super.key, this.small = false, this.muted = false});

  final String text;
  final bool small;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = muted ? p.mut : p.fg;
    return Container(
      height: small ? 24 : 30,
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: muted ? p.ln2 : c),
        borderRadius: BorderRadius.circular(DrkSpace.radius),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w800,
          letterSpacing: (small ? 10 : 11) * .16,
          color: c,
        ),
      ),
    );
  }
}

/// Circle / triangle / square plus the tank number carry identity; hue is a
/// bonus (design §05).
class TankTag extends StatelessWidget {
  const TankTag({super.key, required this.slot, this.label, this.size = 12});

  final int slot;
  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.drk.tankColor(slot);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TankGlyphMark(slot: slot, size: size, color: color),
        const SizedBox(width: 8),
        Text(
          (label ?? 'Tank $slot').toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 12 * .14,
            color: color,
          ),
        ),
      ],
    );
  }
}

class TankGlyphMark extends StatelessWidget {
  const TankGlyphMark({
    super.key,
    required this.slot,
    required this.size,
    required this.color,
  });

  final int slot;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _GlyphPainter(tankGlyph(slot), color)),
  );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);

  final TankGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    switch (glyph) {
      case TankGlyph.circle:
        canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);
      case TankGlyph.triangle:
        canvas.drawPath(
          Path()
            ..moveTo(size.width / 2, 0)
            ..lineTo(size.width, size.height)
            ..lineTo(0, size.height)
            ..close(),
          paint,
        );
      case TankGlyph.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(1)),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}

/// Header of the four-step picker (`.appbar` + `.wiz`).
class WizHeader extends StatelessWidget {
  const WizHeader({super.key, required this.step, this.onBack, this.onClose});

  /// 1–4.
  final int step;
  final VoidCallback? onBack, onClose;

  static const _labels = ['Film', 'Developer', 'ISO', 'Dil · temp'];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              Text('STEP $step / 4', style: labelStyle(context, fg: true)),
              IconButton(
                tooltip: 'Close',
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const SizedBox(height: DrkSpace.s16),
        Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 6, color: i < step ? p.fg : p.ln2),
                      const SizedBox(height: 6),
                      Text(
                        _labels[i].toUpperCase(),
                        style: DrkType.lbl.copyWith(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: i == step - 1 ? p.fg : p.mut,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The big `tm` numerals used on rows.
Text timeText(
  BuildContext context,
  String t, {
  double size = 28,
  FontWeight weight = FontWeight.w700,
  Color? color,
}) {
  return Text(
    t,
    style: DrkType.tm.copyWith(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: -.04 * size,
      color: color ?? context.pal.fg,
    ),
  );
}

/// Text field in the design's `.field` style.
class DrkField extends StatelessWidget {
  const DrkField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.prefix,
    this.heavyBorder = false,
    this.keyboardType,
    this.autofocus = false,
    this.onSubmitted,
    this.label,
  });

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged, onSubmitted;
  final Widget? prefix;
  final bool heavyBorder;
  final TextInputType? keyboardType;
  final bool autofocus;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DrkSpace.radius),
      borderSide: BorderSide(
        color: heavyBorder ? p.fg : p.ln2,
        width: heavyBorder ? 2 : 1,
      ),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      autofocus: autofocus,
      style: DrkType.bd.copyWith(color: p.fg),
      cursorColor: p.fg,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: DrkType.bd.copyWith(color: p.mut),
        filled: true,
        fillColor: p.s1,
        prefixIcon: prefix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DrkSpace.radius),
          borderSide: BorderSide(color: p.fg, width: 2),
        ),
      ),
    );
  }
}
