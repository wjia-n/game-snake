import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/garden.dart';
import '../theme/garden_themes.dart';
import 'pro_screen.dart';

/// Appearance: themes (15 + custom creator), snake styles (10), food styles (8).
class ThemeScreen extends StatefulWidget {
  final SnakeAudio audio;
  final SnakeSettings settings;
  const ThemeScreen({super.key, required this.audio, required this.settings});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  GardenThemeDef get _t => GardenThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  void _goPro() {
    unawaited(widget.audio.click());
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProScreen(audio: widget.audio, settings: widget.settings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return MeadowBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              unawaited(widget.audio.click());
              Navigator.of(context).pop();
            },
          ),
          title:
              Text('Themes & Styles', style: Garden.display(22, theme: t)),
          centerTitle: true,
        ),
        body: ListenableBuilder(
          listenable: s,
          builder: (_, _) => SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Meadow theme'),
                _ThemeGrid(t: t, s: s, audio: widget.audio, onPro: _goPro),
                const SizedBox(height: 6),
                const SectionTitle('Snake style'),
                _StyleRow(
                  t: t,
                  names: SnakeStyles.names,
                  descs: SnakeStyles.descriptions,
                  selected: s.snakeStyle,
                  isLocked: (i) =>
                      !s.isPro && SnakeStyles.isPro(i),
                  swatch: (i) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          SnakeStyles.heads[i],
                          SnakeStyles.bodies[i]
                        ],
                      ),
                      border:
                          Border.all(color: t.accent, width: 1.5),
                    ),
                  ),
                  onTap: (i) async {
                    unawaited(widget.audio.click());
                    if (!s.isPro && SnakeStyles.isPro(i)) {
                      _goPro();
                      return;
                    }
                    await s.setSnakeStyle(i);
                  },
                ),
                const SizedBox(height: 6),
                const SectionTitle('Food style'),
                _StyleRow(
                  t: t,
                  names: FoodStyles.names,
                  descs: FoodStyles.descriptions,
                  selected: s.foodStyle,
                  isLocked: (i) => !s.isPro && FoodStyles.isPro(i),
                  swatch: (i) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == 2
                          ? const Color(0xFF3E6FD8)
                          : i == 5
                              ? const Color(0xFFD9A62B)
                              : const Color(0xFFD64545),
                      border:
                          Border.all(color: t.accent, width: 1.5),
                    ),
                    child: const Center(
                        child: Text('🍎',
                            style: TextStyle(fontSize: 20))),
                  ),
                  onTap: (i) async {
                    unawaited(widget.audio.click());
                    if (!s.isPro && FoodStyles.isPro(i)) {
                      _goPro();
                      return;
                    }
                    await s.setFoodStyle(i);
                  },
                ),
                const SizedBox(height: 6),
                _CustomCard(t: t, s: s, audio: widget.audio, onPro: _goPro),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  final GardenThemeDef t;
  final SnakeSettings s;
  final SnakeAudio audio;
  final VoidCallback onPro;
  const _ThemeGrid(
      {required this.t,
      required this.s,
      required this.audio,
      required this.onPro});

  @override
  Widget build(BuildContext context) {
    final themes = [
      ...GardenThemes.all,
      GardenThemeDef(
        id: 'custom',
        name: 'My Creation',
        backdropDark: const Color(0xFF17230F),
        backdropMid: const Color(0xFF243818),
        boardLight: const Color(0xFF8FBF5F),
        boardDark: const Color(0xFF7DB04E),
        frame: const Color(0xFF5C3A21),
        frameEdge: const Color(0xFF3B2416),
        accent: const Color(0xFFF2CE6B),
        accentLight: const Color(0xFFFFE5A0),
        accentDark: const Color(0xFFA8812E),
        ink: const Color(0xFFF6F1DF),
        inkDim: const Color(0xFFD6CBA8),
        snakeHead: const Color(0xFF3FA34D),
        snakeBody: const Color(0xFF2E7D3A),
        food: const Color(0xFFD64545),
        golden: const Color(0xFFFFD23F),
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: themes.length,
      itemBuilder: (_, i) {
        final th = themes[i];
        final locked =
            !s.isPro && (GardenThemes.isProTheme(th.id) || th.id == 'custom');
        final selected = s.themeId == th.id;
        return GestureDetector(
          onTap: () async {
            unawaited(audio.click());
            if (locked) {
              onPro();
              return;
            }
            await s.setTheme(th.id);
          },
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: selected ? th.accentLight : Colors.transparent,
                      width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(0, 4),
                        blurRadius: 6),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: th.id == 'custom'
                          ? Container(
                              color: Colors.black.withValues(alpha: 0.5),
                              child: Icon(Icons.brush,
                                  color: t.accentLight, size: 28),
                            )
                          : Column(
                              children: [
                                Expanded(
                                    child: Container(color: th.boardLight)),
                                Expanded(
                                    child: Container(color: th.boardDark)),
                              ],
                            ),
                    ),
                    if (locked)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        child: Center(
                          child: Icon(Icons.lock,
                              color: t.accentLight, size: 22),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(th.name,
                  style: Garden.body(10,
                      theme: t,
                      color: selected
                          ? t.accentLight
                          : t.ink.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }
}

class _StyleRow extends StatelessWidget {
  final GardenThemeDef t;
  final List<String> names;
  final List<String> descs;
  final int selected;
  final bool Function(int) isLocked;
  final Widget Function(int) swatch;
  final void Function(int) onTap;
  const _StyleRow({
    required this.t,
    required this.names,
    required this.descs,
    required this.selected,
    required this.isLocked,
    required this.swatch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: names.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final locked = isLocked(i);
          final sel = selected == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              width: 92,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: sel
                    ? t.accent.withValues(alpha: 0.25)
                    : t.backdropDark.withValues(alpha: 0.6),
                border: Border.all(
                    color: sel
                        ? t.accentLight
                        : t.accent.withValues(alpha: 0.4),
                    width: sel ? 2.5 : 1.5),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      swatch(i),
                      if (locked)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Colors.black.withValues(alpha: 0.55),
                          ),
                          child: Icon(Icons.lock,
                              color: t.accentLight, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(names[i],
                      style: Garden.label(10, theme: t),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(descs[i],
                      style: Garden.body(8,
                          theme: t,
                          color: t.ink.withValues(alpha: 0.6)),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom theme creator (Pro): recolor the meadow to taste.
class _CustomCard extends StatelessWidget {
  final GardenThemeDef t;
  final SnakeSettings s;
  final SnakeAudio audio;
  final VoidCallback onPro;
  const _CustomCard(
      {required this.t,
      required this.s,
      required this.audio,
      required this.onPro});

  static const _keys = [
    'backdropDark',
    'backdropMid',
    'boardLight',
    'boardDark',
    'frame',
    'accent',
    'accentLight',
    'accentDark',
    'ink',
    'snakeHead',
    'snakeBody',
    'food',
    'golden',
  ];

  static const _labels = {
    'backdropDark': 'Night sky',
    'backdropMid': 'Meadow glow',
    'boardLight': 'Board light',
    'boardDark': 'Board dark',
    'frame': 'Wood frame',
    'accent': 'Brass',
    'accentLight': 'Brass light',
    'accentDark': 'Brass dark',
    'ink': 'Text ink',
    'snakeHead': 'Snake head',
    'snakeBody': 'Snake body',
    'food': 'Food',
    'golden': 'Golden food',
  };

  Future<void> _pickColor(
      BuildContext context, String key, int current) async {
    final palette = [
      0xFF3FA34D, 0xFF2E7D3A, 0xFF8FBF5F, 0xFFD9A62B, 0xFFF2CE6B, 0xFFFFD23F,
      0xFFD64545, 0xFFB83030, 0xFFB03A2E, 0xFF2E6FD8, 0xFF3E6FD8, 0xFF2E9E9A,
      0xFF8A5FB0, 0xFF5C3A21, 0xFF7A5A34, 0xFFF5EFE0, 0xFF17230F, 0xFF0C1520,
    ];
    final chosen = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.backdropMid,
        title: Text(_labels[key] ?? key, style: Garden.display(18, theme: t)),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in palette)
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(c),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: c == current
                            ? t.accentLight
                            : Colors.white24,
                        width: c == current ? 3 : 1.5),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: Garden.label(14, theme: t)),
          ),
        ],
      ),
    );
    if (chosen != null) {
      unawaited(audio.click());
      await s.setCustomColor(key, chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = s.themeId == 'custom';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            t.backdropMid.withValues(alpha: 0.9),
            t.backdropDark.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: t.accent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.brush, color: t.accentLight),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('Custom theme creator',
                      style: Garden.display(19, theme: t))),
              if (!s.isPro)
                Icon(Icons.lock, color: t.accentLight, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.isPro
                ? 'Recolor the whole meadow, then pick the "My Creation" theme above.'
                : 'A PRO workshop: mix your own meadow colors.',
            style: Garden.body(13,
                theme: t, color: t.ink.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final k in _keys)
                GestureDetector(
                  onTap: () {
                    if (!s.isPro) {
                      onPro();
                      return;
                    }
                    _pickColor(context, k, s.customColors[k]!);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Color(s.customColors[k]!),
                          shape: BoxShape.circle,
                          border: Border.all(color: t.accent, width: 2),
                        ),
                        child: !s.isPro
                            ? Icon(Icons.lock,
                                size: 16,
                                color:
                                    t.accentLight.withValues(alpha: 0.9))
                            : null,
                      ),
                      const SizedBox(height: 3),
                      Text(_labels[k]!,
                          style: Garden.body(9, theme: t),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GardenButton(
                  label: isCustom ? '✓ My Creation active' : 'Use My Creation',
                  fontSize: 15,
                  theme: t,
                  onTap: s.isPro
                      ? () async {
                          unawaited(audio.click());
                          await s.setTheme('custom');
                        }
                      : onPro,
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: s.isPro
                    ? () async {
                        unawaited(audio.click());
                        await s.resetCustomColors();
                      }
                    : onPro,
                child: Text('Reset', style: Garden.label(13, theme: t)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
