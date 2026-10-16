import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/garden.dart';
import '../theme/garden_themes.dart';
import 'rename_dialog.dart';
import '../transfer/transfer_ui.dart';

/// Settings: profile, sound, stats, reset.
class SettingsScreen extends StatefulWidget {
  final SnakeAudio audio;
  final SnakeSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  GardenThemeDef get _t => GardenThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  void _applyAudio() {
    final s = widget.settings;
    widget.audio.configure(
        musicOn: s.musicOn, sfxOn: s.sfxOn, volume: s.volume);
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

  Future<void> _resetStats() async {
    unawaited(widget.audio.click());
    final t = _t;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.backdropMid,
        title: Text('Reset stats?', style: Garden.display(20, theme: t)),
        content: Text(
            'This clears your games played, apples eaten and all best scores. This cannot be undone.',
            style: Garden.body(15, theme: t)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep', style: Garden.label(14, theme: t)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Reset',
                style: Garden.label(14, theme: t, color: t.food)),
          ),
        ],
      ),
    );
    if (yes == true) {
      await widget.settings.resetStats();
      unawaited(widget.audio.click());
    }
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
          title: Text('Settings', style: Garden.display(22, theme: t)),
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
              TransferSaveTile(gameSlug: 'snake'),
                const SectionTitle('Player'),
                SettingRow(
                  theme: t,
                  label: 'Name',
                  control: GestureDetector(
                    onTap: _rename,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.playerName,
                            style: Garden.label(15, theme: t)),
                        const SizedBox(width: 6),
                        Icon(Icons.edit,
                            color: t.accentLight, size: 16),
                      ],
                    ),
                  ),
                ),
                const SectionTitle('Sound'),
                SettingRow(
                  theme: t,
                  label: 'Music',
                  control: GardenToggle(
                    theme: t,
                    value: s.musicOn,
                    onChanged: (v) async {
                      unawaited(widget.audio.click());
                      await s.setMusic(v);
                      _applyAudio();
                      if (v) {
                        unawaited(widget.audio.startMenuMusic());
                      } else {
                        unawaited(widget.audio.stopMusic());
                      }
                    },
                  ),
                ),
                SettingRow(
                  theme: t,
                  label: 'Sound effects',
                  control: GardenToggle(
                    theme: t,
                    value: s.sfxOn,
                    onChanged: (v) async {
                      unawaited(widget.audio.click());
                      await s.setSfx(v);
                      _applyAudio();
                    },
                  ),
                ),
                SettingRow(
                  theme: t,
                  label: 'Volume',
                  control: SizedBox(
                    width: 160,
                    child: BeadSlider(
                      theme: t,
                      value: s.volume,
                      onChanged: (v) async {
                        await s.setVolume(v);
                        _applyAudio();
                      },
                    ),
                  ),
                ),
                const SectionTitle('Lifetime stats'),
                SettingRow(
                  theme: t,
                  label: 'Runs played',
                  control: Text('${s.gamesPlayed}',
                      style: Garden.label(16, theme: t)),
                ),
                SettingRow(
                  theme: t,
                  label: 'Apples eaten',
                  control: Text('${s.applesEaten}',
                      style: Garden.label(16, theme: t)),
                ),
                const SectionTitle('Best scores'),
                for (final m in SnakeSettings.modes)
                  for (int d = 0; d < 4; d++)
                    SettingRow(
                      theme: t,
                      label:
                          '${SnakeSettings.modeNames[SnakeSettings.modes.indexOf(m)]} · ${SnakeSettings.difficulties[d]}',
                      control: Text('${s.bestScore(m, d)}',
                          style: Garden.label(15, theme: t)),
                    ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: _resetStats,
                    child: Text('Reset stats',
                        style: Garden.label(13,
                            theme: t, color: t.food)),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text('Snake 1.0.0 · Made with ♥ by WAJIHA',
                      style: Garden.body(12,
                          theme: t,
                          color: t.ink.withValues(alpha: 0.55)),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
