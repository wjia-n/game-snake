import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'theme/garden.dart';
import 'theme/garden_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = SnakeSettings();
  await settings.load();
  final audio = SnakeAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(SnakeApp(settings: settings, audio: audio));
}

class SnakeApp extends StatefulWidget {
  final SnakeSettings settings;
  final SnakeAudio audio;
  const SnakeApp({super.key, required this.settings, required this.audio});

  @override
  State<SnakeApp> createState() => _SnakeAppState();
}

class _SnakeAppState extends State<SnakeApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.audio.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      unawaited(widget.audio.onAppPaused());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(widget.audio.onAppResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Snake',
        debugShowCheckedModeBanner: false,
        theme: Garden.theme(GardenThemes.byId(
            widget.settings.themeId,
            custom: widget.settings.customTheme)),
        home: SplashScreen(audio: widget.audio, settings: widget.settings),
      ),
    );
  }
}
