import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/garden.dart';
import '../theme/garden_themes.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'rename_dialog.dart';
import 'settings_screen.dart';
import 'theme_screen.dart';

/// Main menu: renameable profile, play, modes, difficulties, appearance,
/// settings, Pro, share.
class MenuScreen extends StatefulWidget {
  final SnakeAudio audio;
  final SnakeSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  GardenThemeDef get _t => GardenThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.gameswajiha.snake';

  @override
  void initState() {
    super.initState();
    // Music must start reliably on menu entry — never silently die.
    unawaited(widget.audio.startMenuMusic());
  }

  void _play() {
    unawaited(widget.audio.click());
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    ).then((_) {
      // Back from the run: the menu owns music again.
      if (mounted) widget.audio.startMenuMusic();
    });
  }

  Future<void> _rename() async {
    unawaited(widget.audio.click());
    await showRenameDialog(
      context: context,
      settings: widget.settings,
      audio: widget.audio,
      theme: _t,
    );
  }

  void _share() {
    unawaited(widget.audio.click());
    SharePlus.instance.share(
      ShareParams(
        text: '🐍 I\'m playing Snake by Wajiha — eat, grow, survive! Can you beat my score?\n$_storeUrl',
        subject: 'Snake by Wajiha',
      ),
    );
  }

  void _howToPlay() {
    unawaited(widget.audio.click());
    final t = _t;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.backdropMid,
        title: Text('How to play', style: Garden.display(22, theme: t)),
        content: SingleChildScrollView(
          child: Text(
            '• Swipe anywhere (or use the d-pad) to steer.\n'
            '• Gobble fruit to grow — each apple is worth 10 points.\n'
            '• Every 5th apple in a row earns a +25 streak bonus.\n'
            '• Watch for the GOLDEN apple: +50 points, but it vanishes!\n'
            '• The snake gets FASTER with every bite.\n'
            '• Classic mode: walls are deadly. Wrap modes: walls tunnel through.\n'
            '• Time Attack: 60 seconds, walls wrap, eat as fast as you can.\n'
            '• Biting your own tail ends the run.\n'
            '• Your best score per mode & difficulty is saved — chase it! 🏆',
            style: Garden.body(15, theme: t),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Got it!', style: Garden.label(14, theme: t)),
          ),
        ],
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
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  // Logo + title.
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: t.accent, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/snake_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                  Text('Snake', style: Garden.display(46, theme: t)),
                  const SizedBox(height: 2),
                  Text('THE MEADOW ARCADE',
                      style: Garden.label(12, theme: t)),
                  const SizedBox(height: 14),
                  // Renameable profile chip.
                  GestureDetector(
                    onTap: _rename,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: t.backdropDark.withValues(alpha: 0.7),
                        border: Border.all(
                            color: t.accent.withValues(alpha: 0.6),
                            width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, color: t.accentLight, size: 18),
                          const SizedBox(width: 8),
                          Text(s.playerName,
                              style: Garden.label(16, theme: t)),
                          const SizedBox(width: 6),
                          Icon(Icons.edit, color: t.accentLight, size: 15),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GardenButton(
                    label: '▶  PLAY',
                    width: 260,
                    fontSize: 24,
                    theme: t,
                    onTap: _play,
                  ),
                  const SizedBox(height: 22),
                  // Modes.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('MODE', style: Garden.label(14, theme: t)),
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0;
                      i < SnakeSettings.modes.length;
                      i++)
                    _ModeCard(
                      t: t,
                      title: SnakeSettings.modeNames[i],
                      desc: SnakeSettings.modeDescriptions[i],
                      selected: s.mode == SnakeSettings.modes[i],
                      locked: !s.isPro && SnakeSettings.modes[i] == 'attack',
                      best: s.bestScore(SnakeSettings.modes[i], s.difficulty),
                      onTap: () {
                        unawaited(widget.audio.click());
                        if (!s.isPro &&
                            SnakeSettings.modes[i] == 'attack') {
                          _goPro();
                          return;
                        }
                        unawaited(s.setMode(SnakeSettings.modes[i]));
                      },
                    ),
                  const SizedBox(height: 14),
                  // Difficulties.
                  Align(
                    alignment: Alignment.centerLeft,
                    child:
                        Text('DIFFICULTY', style: Garden.label(14, theme: t)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (int d = 0; d < 4; d++)
                        _DifficultyChip(
                          t: t,
                          label: SnakeSettings.difficulties[d],
                          sub: SnakeSettings.difficultyScores[d],
                          selected: s.difficulty == d,
                          locked: !s.isPro && d == 3,
                          onTap: () {
                            unawaited(widget.audio.click());
                            if (!s.isPro && d == 3) {
                              _goPro();
                              return;
                            }
                            unawaited(s.setDifficulty(d));
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Appearance / settings / pro / share.
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _IconTile(
                        t: t,
                        icon: Icons.palette,
                        label: 'Themes',
                        onTap: () {
                          unawaited(widget.audio.click());
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => ThemeScreen(
                                    audio: widget.audio,
                                    settings: widget.settings)),
                          );
                        },
                      ),
                      _IconTile(
                        t: t,
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () {
                          unawaited(widget.audio.click());
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => SettingsScreen(
                                    audio: widget.audio,
                                    settings: widget.settings)),
                          );
                        },
                      ),
                      _IconTile(
                        t: t,
                        icon: Icons.workspace_premium,
                        label: s.isPro ? 'PRO ✓' : 'PRO',
                        onTap: _goPro,
                      ),
                      _IconTile(
                        t: t,
                        icon: Icons.help_outline,
                        label: 'How to',
                        onTap: _howToPlay,
                      ),
                      _IconTile(
                        t: t,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: _share,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text('Made with ♥ by WAJIHA',
                      style: Garden.body(13,
                          theme: t,
                          color: t.ink.withValues(alpha: 0.6))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goPro() {
    unawaited(widget.audio.click());
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final GardenThemeDef t;
  final String title;
  final String desc;
  final bool selected;
  final bool locked;
  final int best;
  final VoidCallback onTap;
  const _ModeCard({
    required this.t,
    required this.title,
    required this.desc,
    required this.selected,
    required this.locked,
    required this.best,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: selected
                ? [t.frame, t.frameEdge]
                : [
                    t.backdropDark.withValues(alpha: 0.7),
                    t.backdropDark.withValues(alpha: 0.5)
                  ],
          ),
          border: Border.all(
              color: selected ? t.accentLight : t.accent.withValues(alpha: 0.5),
              width: selected ? 2.5 : 1.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: t.accent.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: Garden.display(18, theme: t)),
                      if (locked) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.lock,
                            size: 15,
                            color: t.accentLight.withValues(alpha: 0.8)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(desc,
                      style: Garden.body(12,
                          theme: t,
                          color: t.ink.withValues(alpha: 0.7))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                Text('BEST', style: Garden.label(10, theme: t)),
                Text('$best', style: Garden.display(20, theme: t)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final GardenThemeDef t;
  final String label;
  final String sub;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  const _DifficultyChip({
    required this.t,
    required this.label,
    required this.sub,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? t.accent.withValues(alpha: 0.85)
              : t.backdropDark.withValues(alpha: 0.7),
          border: Border.all(
              color: selected ? t.accentLight : t.accent.withValues(alpha: 0.5),
              width: selected ? 2 : 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: Garden.label(14,
                        theme: t,
                        color: selected ? t.backdropDark : null)),
                if (locked) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.lock,
                      size: 13,
                      color: selected
                          ? t.backdropDark
                          : t.accentLight.withValues(alpha: 0.8)),
                ],
              ],
            ),
            Text(sub,
                style: Garden.body(10,
                    theme: t,
                    color: selected
                        ? t.backdropDark.withValues(alpha: 0.8)
                        : t.ink.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final GardenThemeDef t;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _IconTile(
      {required this.t,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: t.backdropDark.withValues(alpha: 0.7),
          border:
              Border.all(color: t.accent.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: t.accentLight, size: 26),
            const SizedBox(height: 5),
            Text(label, style: Garden.label(12, theme: t)),
          ],
        ),
      ),
    );
  }
}
