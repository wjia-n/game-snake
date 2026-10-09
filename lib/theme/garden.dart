import 'package:flutter/material.dart';
import 'garden_themes.dart';

/// Garden visual system for Snake: handcrafted meadow materials —
/// carved wood, polished stone, juicy fruit. Physical depth, real shadows,
/// no neon, no cyberpunk, no generic Material look.
///
/// All widgets accept an optional [GardenThemeDef]; they default to the
/// Garden Classic theme so call sites keep working.
class Garden {
  static TextStyle display(double size,
          {Color? color, GardenThemeDef? theme}) =>
      TextStyle(
        fontFamily: 'serif',
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFF2CE6B),
        letterSpacing: 1.1,
        shadows: const [
          Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle body(double size, {Color? color, GardenThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? theme?.ink ?? const Color(0xFFF6F1DF),
        height: 1.35,
      );

  static TextStyle label(double size, {Color? color, GardenThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFF2CE6B),
        letterSpacing: 0.8,
      );

  static ThemeData theme([GardenThemeDef? t]) {
    t ??= GardenThemes.byId('garden');
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.backdropDark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: t.accent,
        onPrimary: t.backdropDark,
        secondary: t.accentLight,
        onSecondary: t.backdropDark,
        surface: t.backdropMid,
        onSurface: t.ink,
        error: t.food,
        onError: t.ink,
      ),
      textTheme: TextTheme(
        displayLarge: display(34, theme: t),
        displayMedium: display(26, theme: t),
        titleLarge: display(22, theme: t),
        bodyLarge: body(16, theme: t),
        bodyMedium: body(14, theme: t),
        labelLarge: label(14, theme: t),
      ),
      dialogTheme: DialogThemeData(backgroundColor: t.backdropMid),
    );
  }
}

/// Meadow backdrop: grass-blade texture under a warm vignette, theme-aware.
class MeadowBackdrop extends StatelessWidget {
  final Widget child;
  final GardenThemeDef? theme;
  const MeadowBackdrop({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? GardenThemes.byId('garden');
    return Container(
      decoration: BoxDecoration(color: t.backdropDark),
      child: CustomPaint(
        painter: _MeadowPainter(t),
        child: child,
      ),
    );
  }
}

class _MeadowPainter extends CustomPainter {
  final GardenThemeDef t;
  _MeadowPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final vignette = RadialGradient(
      center: const Alignment(0, -0.25),
      radius: 1.2,
      colors: [
        t.backdropMid.withValues(alpha: 0.6),
        t.backdropDark.withValues(alpha: 0.0),
        Colors.black.withValues(alpha: 0.55),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = vignette.createShader(Offset.zero & size),
    );
    // Soft grass blades along the bottom edge.
    final blade = Paint()
      ..color = t.backdropMid.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final n = (size.width / 22).round();
    for (int i = 0; i < n; i++) {
      final x = (i + 0.5) * size.width / n;
      final h = 14 + (i % 3) * 9.0;
      final lean = (i % 2 == 0 ? 6 : -6).toDouble();
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + lean, size.height - h),
        blade,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A chunky carved-wood button with brass trim — physically pressable.
class GardenButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double width;
  final double fontSize;
  final bool primary;
  final GardenThemeDef? theme;

  const GardenButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 240,
    this.fontSize = 19,
    this.primary = true,
    this.theme,
  });

  @override
  State<GardenButton> createState() => _GardenButtonState();
}

class _GardenButtonState extends State<GardenButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme ?? GardenThemes.byId('garden');
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 15),
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: enabled
                ? widget.primary
                    ? [t.frame, t.frameEdge]
                    : [t.backdropMid, t.backdropDark]
                : [
                    t.backdropDark.withValues(alpha: 0.7),
                    t.backdropDark.withValues(alpha: 0.5)
                  ],
          ),
          border: Border.all(color: t.accent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: t.accentLight.withValues(alpha: _pressed ? 0.05 : 0.22),
              offset: const Offset(0, -2),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              offset: Offset(0, _pressed ? 2 : 6),
              blurRadius: _pressed ? 4 : 10,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: Garden.display(widget.fontSize,
              theme: t,
              color: enabled ? t.ink : t.inkDim.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

/// A polished-stone toggle.
class GardenToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final GardenThemeDef? theme;
  const GardenToggle(
      {super.key, required this.value, required this.onChanged, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? GardenThemes.byId('garden');
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 64,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: value ? t.accentDark : t.backdropDark,
          border: Border.all(color: t.accent, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 3),
                blurRadius: 5),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.accentLight, t.accent, t.accentDark],
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 2),
                    blurRadius: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A wooden-bead volume slider on a brass rail.
class BeadSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final GardenThemeDef? theme;
  const BeadSlider(
      {super.key, required this.value, required this.onChanged, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? GardenThemes.byId('garden');
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: t.accent,
        inactiveTrackColor: t.backdropDark,
        thumbShape: _BeadThumb(t),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(value: value, onChanged: onChanged),
    );
  }
}

class _BeadThumb extends SliderComponentShape {
  final GardenThemeDef t;
  const _BeadThumb(this.t);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(26, 26);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    canvas.drawCircle(
        center + const Offset(0, 2),
        12,
        Paint()..color = Colors.black.withValues(alpha: 0.6));
    canvas.drawCircle(
        center,
        11,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.0,
            colors: [t.accentLight, t.accent, t.accentDark],
          ).createShader(Rect.fromCircle(center: center, radius: 11)));
  }
}

/// A carved-wood plaque for titles.
class WoodPlaque extends StatelessWidget {
  final String title;
  final String? subtitle;
  final GardenThemeDef? theme;
  const WoodPlaque({super.key, required this.title, this.subtitle, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? GardenThemes.byId('garden');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.frameEdge, t.frame],
        ),
        border: Border.all(color: t.accent, width: 3),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(0, 6),
              blurRadius: 12),
          BoxShadow(
              color: t.accentLight.withValues(alpha: 0.7),
              offset: const Offset(0, -1),
              blurRadius: 1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: Garden.display(30, theme: t),
              textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                style: Garden.body(14,
                    theme: t, color: t.ink.withValues(alpha: 0.75)),
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// Small helper: a labeled settings row.
class SettingRow extends StatelessWidget {
  final String label;
  final Widget control;
  final GardenThemeDef? theme;
  const SettingRow(
      {super.key, required this.label, required this.control, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? GardenThemes.byId('garden');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: t.backdropDark.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Garden.body(16, theme: t))),
          control,
        ],
      ),
    );
  }
}

/// A section heading for settings-style screens.
class SectionTitle extends StatelessWidget {
  final String title;
  final GardenThemeDef? theme;
  const SectionTitle(this.title, {super.key, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? GardenThemes.byId('garden');
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 4, left: 4),
      child: Text(title, style: Garden.label(15, theme: t)),
    );
  }
}
