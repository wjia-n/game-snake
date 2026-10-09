import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../engine/snake_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/garden.dart';
import '../theme/garden_themes.dart';

/// The arcade screen: engine-owned phases, juicy feedback for every action.
class GameScreen extends StatefulWidget {
  final SnakeAudio audio;
  final SnakeSettings settings;
  const GameScreen({super.key, required this.audio, required this.settings});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late SnakeEngine engine;
  late AnimationController _shake;
  final List<_Popup> _popups = [];
  bool _recorded = false;
  int _countdownShown = 0;

  GardenThemeDef get _t => GardenThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    engine = SnakeEngine(
      mode: widget.settings.mode,
      difficulty: widget.settings.difficulty,
      tickMs: SnakeSettings
          .difficultyIntervals[widget.settings.difficulty.clamp(0, 3)],
    );
    engine.onEvent = _onEvent;
    engine.addListener(_onEngine);
    unawaited(widget.audio.startGameMusic());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    engine.removeListener(_onEngine);
    engine.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Freeze the run when the app goes away; the player resumes manually.
    if (state == AppLifecycleState.paused) {
      engine.setPaused(true);
    }
  }

  void _onEngine() {
    if (!mounted) return;
    setState(() {});
    if (engine.phase == Phase.over && !_recorded) {
      _recorded = true;
      _finishRun();
    }
  }

  void _onEvent(SnakeEvent e) {
    final audio = widget.audio;
    switch (e) {
      case SnakeEvent.start:
        unawaited(audio.gameStart());
      case SnakeEvent.steer:
        unawaited(audio.steer());
      case SnakeEvent.eat:
        unawaited(audio.chomp());
        _popup('+10', _t.food);
      case SnakeEvent.golden:
        unawaited(audio.golden());
        _popup('+50', _t.golden);
      case SnakeEvent.goldenSpawn:
        unawaited(audio.spawn());
      case SnakeEvent.countdownTick:
        unawaited(audio.tick());
      case SnakeEvent.death:
        unawaited(audio.death());
        _shake.forward(from: 0);
      case SnakeEvent.timeUp:
        unawaited(audio.gameOver());
      case SnakeEvent.invalid:
        unawaited(audio.invalid());
    }
  }

  void _popup(String text, Color color) {
    if (engine.snake.isEmpty) return;
    final head = engine.snake.first;
    setState(() {
      _popups.add(_Popup(
        text: text,
        color: color,
        x: (head.x + 0.5) / SnakeEngine.n,
        y: (head.y + 0.5) / SnakeEngine.n,
      ));
    });
    unawaited(Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      setState(() {
        if (_popups.isNotEmpty) _popups.removeAt(0);
      });
    }));
  }

  Future<void> _finishRun() async {
    final s = widget.settings;
    final isNewBest = await s.recordRun(
      m: engine.mode,
      d: engine.difficulty,
      score: engine.score,
      apples: engine.apples,
    );
    engine.newBest = isNewBest;
    if (isNewBest && engine.score > 0) {
      unawaited(widget.audio.newBest());
    }
    // Ask for a store review at sensible moments (graceful when not on Play).
    if (s.shouldAskReview) {
      await s.bumpReviewCount();
      try {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        }
      } catch (_) {}
    }
    if (mounted) setState(() {});
    // Drift back to menu music behind the results card.
    unawaited(widget.audio.startMenuMusic());
  }

  void _steer(Point<int> d) => engine.steer(d);

  @override
  Widget build(BuildContext context) {
    final t = _t;
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
          title: Text(
              '${SnakeSettings.modeNames[SnakeSettings.modes.indexOf(widget.settings.mode)]} · ${SnakeSettings.difficulties[widget.settings.difficulty]}',
              style: Garden.display(17, theme: t)),
          centerTitle: true,
          actions: [
            if (engine.phase == Phase.running ||
                engine.phase == Phase.paused)
              IconButton(
                icon: Icon(
                    engine.phase == Phase.paused
                        ? Icons.play_arrow
                        : Icons.pause,
                    color: t.accentLight),
                onPressed: () {
                  unawaited(widget.audio.click());
                  engine.setPaused(engine.phase != Phase.paused);
                },
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _hud(t),
              const SizedBox(height: 8),
              Expanded(child: _board(t)),
              const SizedBox(height: 10),
              _dpad(t),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hud(GardenThemeDef t) {
    final best = widget.settings.bestScore(engine.mode, engine.difficulty);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatChip(
              t: t, label: 'SCORE', value: '${engine.score}', big: true),
          const SizedBox(width: 8),
          _StatChip(t: t, label: 'BEST', value: '$best'),
          const SizedBox(width: 8),
          _StatChip(t: t, label: '🍎', value: '${engine.apples}'),
          const Spacer(),
          if (engine.isAttack)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _attackSecondsLeft <= 10
                    ? t.food.withValues(alpha: 0.85)
                    : t.backdropDark.withValues(alpha: 0.7),
                border: Border.all(color: t.accent, width: 1.5),
              ),
              child: Text('⏱ $_attackSecondsLeft',
                  style: Garden.label(16, theme: t)),
            )
          else if (engine.banner.isNotEmpty)
            Flexible(
              child: Text(engine.banner,
                  style: Garden.body(13,
                      theme: t, color: t.ink.withValues(alpha: 0.85)),
                  textAlign: TextAlign.right),
            ),
        ],
      ),
    );
  }

  int get _attackSecondsLeft =>
      (engine.attackTicksLeft * engine.tickMs / 1000).ceil().clamp(0, 60);

  Widget _board(GardenThemeDef t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _shake,
            builder: (_, child) {
              final s = sin(_shake.value * pi * 4) * 14 * (1 - _shake.value);
              return Transform.translate(
                  offset: Offset(s, s * 0.6), child: child);
            },
            child: GestureDetector(
              onTap: engine.tap,
              onPanUpdate: (d) {
                final v = d.delta;
                if (v.distance < 6) return;
                if (v.dx.abs() > v.dy.abs()) {
                  _steer(Point(v.dx > 0 ? 1 : -1, 0));
                } else {
                  _steer(Point(0, v.dy > 0 ? 1 : -1));
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.frame, width: 8),
                  boxShadow: [
                    BoxShadow(
                      color: t.frame.withValues(alpha: 0.25),
                      blurRadius: 2,
                      offset: const Offset(0, -2),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _MeadowPainter(
                        engine: engine,
                        theme: t,
                        snakeStyle: widget.settings.snakeStyle,
                        foodStyle: widget.settings.foodStyle,
                      ),
                    ),
                    for (final p in _popups) _popupWidget(t, p),
                    if (engine.phase == Phase.idle) _idleHint(t),
                    if (engine.phase == Phase.countdown)
                      _countdownOverlay(t),
                    if (engine.phase == Phase.dying) _deathFlash(t),
                    if (engine.phase == Phase.paused) _pausedOverlay(t),
                    if (engine.phase == Phase.over) _gameOver(t),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _popupWidget(GardenThemeDef t, _Popup p) {
    return Positioned.fill(
      child: IgnorePointer(
        child: FractionallySizedBox(
          alignment: Alignment(p.x * 2 - 1, p.y * 2 - 1),
          widthFactor: 1,
          heightFactor: 1,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: -28),
              duration: const Duration(milliseconds: 850),
              builder: (_, dy, child) => Transform.translate(
                offset: Offset(0, dy),
                child: Opacity(
                  opacity: (1 - (-dy / 28) * 0.7).clamp(0.0, 1.0),
                  child: child,
                ),
              ),
              child: Text(p.text,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: p.color,
                    shadows: const [
                      Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 2),
                          blurRadius: 4)
                    ],
                  )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _idleHint(GardenThemeDef t) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: t.backdropDark.withValues(alpha: 0.9),
            border: Border.all(color: t.accent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('👆', style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 6),
              Text('Tap or swipe to slither!',
                  style: Garden.display(19, theme: t),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(engine.banner,
                  style: Garden.body(13,
                      theme: t,
                      color: t.ink.withValues(alpha: 0.75)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countdownOverlay(GardenThemeDef t) {
    final label = engine.countdown > 0 ? '${engine.countdown}' : 'GO!';
    if (engine.countdown != _countdownShown) {
      _countdownShown = engine.countdown;
    }
    return Container(
      color: Colors.black.withValues(alpha: 0.25),
      child: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(label),
          tween: Tween(begin: 1.6, end: 1.0),
          duration: const Duration(milliseconds: 450),
          builder: (_, s, child) =>
              Transform.scale(scale: s, child: child),
          child: Text(label,
              style: Garden.display(84, theme: t)),
        ),
      ),
    );
  }

  Widget _deathFlash(GardenThemeDef t) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.transparent,
              t.food.withValues(alpha: 0.45),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pausedOverlay(GardenThemeDef t) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Paused', style: Garden.display(40, theme: t)),
            const SizedBox(height: 18),
            GardenButton(
              label: '▶ Resume',
              theme: t,
              onTap: () {
                unawaited(widget.audio.click());
                engine.setPaused(false);
              },
            ),
            const SizedBox(height: 12),
            GardenButton(
              label: '↺ Restart',
              primary: false,
              theme: t,
              onTap: () {
                unawaited(widget.audio.click());
                engine.restart();
                engine.start();
              },
            ),
            const SizedBox(height: 12),
            GardenButton(
              label: '🏠 Menu',
              primary: false,
              theme: t,
              onTap: () {
                unawaited(widget.audio.click());
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameOver(GardenThemeDef t) {
    final best = widget.settings.bestScore(engine.mode, engine.difficulty);
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [t.backdropMid, t.backdropDark],
              ),
              border: Border.all(color: t.accent, width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(0, 8),
                    blurRadius: 16),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (engine.newBest && engine.score > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: t.golden.withValues(alpha: 0.22),
                      border: Border.all(color: t.golden),
                    ),
                    child: Text('🏆 NEW BEST! 🏆',
                        style: Garden.label(16, theme: t)),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(engine.deathCause == 'time' ? 'Time!' : 'Game Over',
                    style: Garden.display(34, theme: t)),
                const SizedBox(height: 6),
                Text(engine.banner.isNotEmpty ? engine.banner : '',
                    style: Garden.body(14,
                        theme: t,
                        color: t.ink.withValues(alpha: 0.75)),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text('${engine.score}',
                    style: Garden.display(56, theme: t)),
                Text('BEST $best',
                    style: Garden.label(14, theme: t)),
                const SizedBox(height: 8),
                Text('🍎 ${engine.apples} apples munched',
                    style: Garden.body(14, theme: t)),
                const SizedBox(height: 18),
                GardenButton(
                  label: '↺ Play Again',
                  theme: t,
                  onTap: () {
                    unawaited(widget.audio.click());
                    _recorded = false;
                    engine.restart();
                    engine.start();
                  },
                ),
                const SizedBox(height: 12),
                GardenButton(
                  label: '🏠 Menu',
                  primary: false,
                  theme: t,
                  onTap: () {
                    unawaited(widget.audio.click());
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dpad(GardenThemeDef t) {
    Widget btn(IconData icon, Point<int> d) => Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _steer(d),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: t.backdropDark.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: t.accent.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(icon, color: t.accentLight, size: 28),
            ),
          ),
        );
    return SizedBox(
      height: 196,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.keyboard_arrow_up, const Point(0, -1)),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              btn(Icons.keyboard_arrow_left, const Point(-1, 0)),
              const SizedBox(width: 70),
              btn(Icons.keyboard_arrow_right, const Point(1, 0)),
            ],
          ),
          const SizedBox(height: 6),
          btn(Icons.keyboard_arrow_down, const Point(0, 1)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final GardenThemeDef t;
  final String label;
  final String value;
  final bool big;
  const _StatChip(
      {required this.t,
      required this.label,
      required this.value,
      this.big = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: big ? 16 : 12, vertical: big ? 8 : 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: t.backdropDark.withValues(alpha: 0.7),
        border: Border.all(color: t.accent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: Garden.label(big ? 11 : 10, theme: t)),
          Text(value,
              style: Garden.display(big ? 24 : 18, theme: t)),
        ],
      ),
    );
  }
}

class _Popup {
  final String text;
  final Color color;
  final double x;
  final double y;
  _Popup(
      {required this.text,
      required this.color,
      required this.x,
      required this.y});
}

// ---------------------------------------------------------------------------
/// Board painter: checker meadow, styled food, patterned snake with head.
class _MeadowPainter extends CustomPainter {
  final SnakeEngine engine;
  final GardenThemeDef theme;
  final int snakeStyle;
  final int foodStyle;

  _MeadowPainter({
    required this.engine,
    required this.theme,
    required this.snakeStyle,
    required this.foodStyle,
  });

  Color get _headColor => theme.id == 'custom'
      ? theme.snakeHead
      : SnakeStyles.heads[snakeStyle.clamp(0, SnakeStyles.heads.length - 1)];
  Color get _bodyColor => theme.id == 'custom'
      ? theme.snakeBody
      : SnakeStyles.bodies[snakeStyle.clamp(0, SnakeStyles.bodies.length - 1)];
  int get _pattern =>
      SnakeStyles.patterns[snakeStyle.clamp(0, SnakeStyles.patterns.length - 1)];

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / SnakeEngine.n;
    // Checker meadow.
    final paint = Paint();
    for (int y = 0; y < SnakeEngine.n; y++) {
      for (int x = 0; x < SnakeEngine.n; x++) {
        paint.color = (x + y).isEven ? theme.boardLight : theme.boardDark;
        canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
      }
    }
    _drawFood(canvas, cell, engine.food, theme.food, false);
    if (engine.golden != null) {
      _drawFood(canvas, cell, engine.golden!, theme.golden, true);
    }
    _drawSnake(canvas, cell);
  }

  void _drawFood(
      Canvas canvas, double cell, Point<int> p, Color color, bool golden) {
    final c = Offset((p.x + 0.5) * cell, (p.y + 0.5) * cell);
    final r = cell * 0.32;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(c, r * 1.35, glow);
    final style = foodStyle.clamp(0, 7);
    switch (style) {
      case 0:
        _apple(canvas, c, r, color, golden);
      case 1:
        _cherry(canvas, c, r, color, golden);
      case 2:
        _blueberry(canvas, c, r, color, golden);
      case 3:
        _starFruit(canvas, c, r, color, golden);
      case 4:
        _cookie(canvas, c, r, color, golden);
      case 5:
        _mushroom(canvas, c, r, color, golden);
      case 6:
        _gem(canvas, c, r, color, golden);
      default:
        _sprout(canvas, c, r, color, golden);
    }
    if (golden) {
      // sparkles
      final sp = Paint()..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(c + Offset(r * 0.9, -r * 0.9), cell * 0.05, sp);
      canvas.drawCircle(c + Offset(-r * 0.8, r * 0.7), cell * 0.04, sp);
    }
  }

  void _apple(Canvas canvas, Offset c, double r, Color color, bool golden) {
    final p = Paint()..color = color;
    canvas.drawCircle(c, r, p);
    // highlight
    canvas.drawCircle(
        c + Offset(-r * 0.3, -r * 0.35),
        r * 0.28,
        Paint()..color = Colors.white.withValues(alpha: 0.35));
    // stem
    canvas.drawRect(
        Rect.fromCenter(center: c + Offset(0, -r * 1.05), width: r * 0.14, height: r * 0.5),
        Paint()..color = const Color(0xFF5C3A21));
    // leaf
    final leaf = Path()
      ..moveTo(c.dx + r * 0.05, c.dy - r * 1.1)
      ..quadraticBezierTo(
          c.dx + r * 0.75, c.dy - r * 1.5, c.dx + r * 0.85, c.dy - r * 0.95)
      ..quadraticBezierTo(
          c.dx + r * 0.45, c.dy - r * 0.85, c.dx + r * 0.05, c.dy - r * 1.1);
    canvas.drawPath(
        leaf,
        Paint()
          ..color = golden ? Colors.white : const Color(0xFF3FA34D));
  }

  void _cherry(Canvas canvas, Offset c, double r, Color color, bool golden) {
    final p = Paint()..color = color;
    canvas.drawCircle(c + Offset(-r * 0.45, r * 0.3), r * 0.62, p);
    canvas.drawCircle(c + Offset(r * 0.45, r * 0.35), r * 0.62, p);
    final stem = Paint()
      ..color = golden ? Colors.white : const Color(0xFF5C3A21)
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + Offset(-r * 0.45, -r * 0.2), c + Offset(0, -r * 1.1), stem);
    canvas.drawLine(c + Offset(r * 0.45, -r * 0.15), c + Offset(0, -r * 1.1), stem);
    canvas.drawCircle(
        c + Offset(-r * 0.7, r * 0.05),
        r * 0.16,
        Paint()..color = Colors.white.withValues(alpha: 0.4));
  }

  void _blueberry(Canvas canvas, Offset c, double r, Color color, bool golden) {
    final p = Paint()..color = color;
    for (final o in [
      const Offset(0, 0),
      Offset(-r * 0.6, r * 0.25),
      Offset(r * 0.6, r * 0.25),
      Offset(0, -r * 0.55),
    ]) {
      canvas.drawCircle(c + o, r * 0.52, p);
    }
    canvas.drawCircle(
        c + Offset(-r * 0.2, -r * 0.2),
        r * 0.16,
        Paint()..color = Colors.white.withValues(alpha: 0.4));
    // crown
    final crown = Paint()
      ..color = golden ? Colors.white : const Color(0xFF3A5A2A);
    canvas.drawCircle(c + Offset(0, -r * 1.0), r * 0.2, crown);
  }

  void _starFruit(Canvas canvas, Offset c, double r, Color color, bool golden) {
    final p = Paint()..color = color;
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final ang = -pi / 2 + i * pi / 5;
      final rr = i.isEven ? r * 1.05 : r * 0.5;
      final pt = c + Offset(cos(ang) * rr, sin(ang) * rr);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, p);
    canvas.drawCircle(c, r * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.45));
  }

  void _cookie(Canvas canvas, Offset c, double r, Color color, bool golden) {
    final p = Paint()..color = color;
    canvas.drawCircle(c, r, p);
    canvas.drawCircle(c, r * 0.78,
        Paint()..color = color.withValues(alpha: 0.6));
    final chip = Paint()
      ..color = golden ? Colors.white : const Color(0xFF3B2416);
    canvas.drawCircle(c + Offset(-r * 0.3, -r * 0.2), r * 0.12, chip);
    canvas.drawCircle(c + Offset(r * 0.35, r * 0.1), r * 0.12, chip);
    canvas.drawCircle(c + Offset(0, r * 0.45), r * 0.12, chip);
  }

  void _mushroom(Canvas canvas, Offset c, double r, Color color, bool golden) {
    final cap = Paint()..color = color;
    canvas.drawArc(
        Rect.fromCircle(center: c + Offset(0, r * 0.15), radius: r),
        pi,
        pi,
        true,
        cap);
    final stem = Paint()
      ..color = golden ? Colors.white : const Color(0xFFF5EFE0);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: c + Offset(0, r * 0.55),
                width: r * 0.6,
                height: r * 0.9),
            Radius.circular(r * 0.25)),
        stem);
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(c + Offset(-r * 0.35, -r * 0.35), r * 0.12, dot);
    canvas.drawCircle(c + Offset(r * 0.3, -r * 0.5), r * 0.1, dot);
  }

  void _gem(Canvas canvas, Offset c, double r, Color color, bool golden) {
    final p = Paint()..color = color;
    final path = Path()
      ..moveTo(c.dx, c.dy - r * 1.05)
      ..lineTo(c.dx + r * 0.8, c.dy)
      ..lineTo(c.dx, c.dy + r * 1.05)
      ..lineTo(c.dx - r * 0.8, c.dy)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawLine(
        Offset(c.dx - r * 0.8, c.dy),
        Offset(c.dx + r * 0.8, c.dy),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = r * 0.1);
    canvas.drawCircle(
        c + Offset(-r * 0.2, -r * 0.4),
        r * 0.14,
        Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  void _sprout(Canvas canvas, Offset c, double r, Color color, bool golden) {
    final stem = Paint()
      ..color = color
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + Offset(0, r * 0.9), c + Offset(0, -r * 0.6), stem);
    final leaf = Paint()..color = color.withValues(alpha: 0.85);
    for (final sgn in [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(c.dx, c.dy - r * 0.1)
        ..quadraticBezierTo(c.dx + sgn * r * 0.9, c.dy - r * 0.2,
            c.dx + sgn * r * 0.95, c.dy - r * 0.85)
        ..quadraticBezierTo(c.dx + sgn * r * 0.4, c.dy - r * 0.75, c.dx,
            c.dy - r * 0.1);
      canvas.drawPath(path, leaf);
    }
  }

  void _drawSnake(Canvas canvas, double cell) {
    final snake = engine.snake;
    final head = _headColor;
    final body = _bodyColor;
    // Tail to head so the head draws on top.
    for (int i = snake.length - 1; i >= 0; i--) {
      final p = snake[i];
      final rect = Rect.fromLTWH(
          p.x * cell + 1.5, p.y * cell + 1.5, cell - 3, cell - 3);
      Color fill;
      if (i == 0) {
        fill = head;
      } else {
        switch (_pattern) {
          case 1: // stripes
            fill = i.isEven ? body : Color.lerp(body, Colors.white, 0.28)!;
          case 2: // scales
            fill = Color.lerp(body, Colors.black, (i % 3) * 0.12)!;
          case 3: // rings
            fill = i % 4 == 0 ? head : body;
          default:
            fill = Color.lerp(body, head, 0.25 * (1 - i / snake.length))!;
        }
      }
      // glossy 3D ball: base, top highlight
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.42)),
          Paint()..color = fill);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(rect.left + cell * 0.16, rect.top + cell * 0.1,
                  cell * 0.36, cell * 0.26),
              Radius.circular(cell * 0.13)),
          Paint()..color = Colors.white.withValues(alpha: 0.35));
    }
    // Head eyes, looking in the travel direction.
    if (snake.isNotEmpty) {
      final h = snake.first;
      final c = Offset((h.x + 0.5) * cell, (h.y + 0.5) * cell);
      final fwd = Offset(engine.dir.x.toDouble(), engine.dir.y.toDouble());
      final side = Offset(-fwd.dy, fwd.dx);
      final eyeBase = c + fwd * cell * 0.16;
      final eye = Paint()..color = Colors.white;
      final pupil = Paint()..color = const Color(0xFF1A1A1A);
      for (final sgn in [-1.0, 1.0]) {
        final e = eyeBase + side * cell * 0.2 * sgn;
        canvas.drawCircle(e, cell * 0.14, eye);
        canvas.drawCircle(e + fwd * cell * 0.04, cell * 0.07, pupil);
      }
      // tongue flick
      final tongue = Paint()
        ..color = const Color(0xFFE86A6A)
        ..strokeWidth = cell * 0.07
        ..strokeCap = StrokeCap.round;
      final tip = c + fwd * cell * 0.52;
      canvas.drawLine(c + fwd * cell * 0.38, tip, tongue);
      canvas.drawLine(
          tip, tip + fwd * cell * 0.08 + side * cell * 0.06, tongue);
      canvas.drawLine(
          tip, tip + fwd * cell * 0.08 - side * cell * 0.06, tongue);
    }
  }

  @override
  bool shouldRepaint(covariant _MeadowPainter old) => true;
}
