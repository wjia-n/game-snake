import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/garden.dart';
import '../theme/garden_themes.dart';
import 'menu_screen.dart';

/// Launch splash — a SINGLE splash moment in two beats:
/// 1. the WAJIHA company moment (official logo, never redrawn),
/// 2. the game splash: logo + name + animated loading line + "Credits: WAJIHA".
class SplashScreen extends StatefulWidget {
  final SnakeAudio audio;
  final SnakeSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyPhase = true;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the splash shows, then start menu music.
    unawaited(widget.audio.prewarm());
    unawaited(widget.audio.startMenuMusic());
    // Beat 1: the company moment.
    await Future.delayed(const Duration(milliseconds: 1150));
    if (!mounted) return;
    setState(() => _companyPhase = false);
    // Beat 2: the game splash with the animated loading line.
    unawaited(_loader.forward());
    await Future.delayed(const Duration(milliseconds: 1950));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GardenThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF101A0C),
      body: _companyPhase
          ? _CompanySplash(theme: theme)
          : _GameSplash(theme: theme, loader: _loader),
    );
  }
}

/// Beat 1: the WAJIHA company moment — official winged-W logo, unchanged.
class _CompanySplash extends StatelessWidget {
  final GardenThemeDef theme;
  const _CompanySplash({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/wajiha_logo.png',
            width: 130,
            height: 130,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 18),
          Text('WAJIHA', style: Garden.display(40, theme: theme)),
          const SizedBox(height: 6),
          Text('PLAYS · CREATES · DELIGHTS',
              style: Garden.label(12, theme: theme)),
        ],
      ),
    );
  }
}

/// Game splash: logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final GardenThemeDef theme;
  final AnimationController loader;
  const _GameSplash({required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return MeadowBackdrop(
      theme: theme,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.accent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/snake_logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(height: 22),
            Text('Snake', style: Garden.display(52, theme: theme)),
            const SizedBox(height: 6),
            Text(
              'THE MEADOW ARCADE',
              style: Garden.label(13, theme: theme),
            ),
            const SizedBox(height: 30),
            // Animated loading line.
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                            color: theme.accent.withValues(alpha: 0.5)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [
                                theme.accentLight,
                                theme.accent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loader.value < 1 ? 'Warming up the meadow…' : 'Ready!',
                      style: Garden.body(13,
                          theme: theme,
                          color: theme.ink.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'Credits: WAJIHA',
                  style: Garden.label(14, theme: theme),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
