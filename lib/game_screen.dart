import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Snake — solo real-time arcade. Swipe or d-pad, eat apples, don't die.
class SnakeScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const SnakeScreen({super.key, required this.players, required this.callbacks});

  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen> {
  static const _n = 20;
  static const _bestKey = 'snake_best';

  final _rand = Random();
  List<Point<int>> snake = [];
  Point<int> apple = const Point(10, 10);
  Point<int> dir = const Point(1, 0);
  Point<int> nextDir = const Point(1, 0);
  Timer? timer;
  bool over = false;
  bool started = false;
  int best = 0;
  int apples = 0;

  @override
  void initState() {
    super.initState();
    _loadBest();
    _reset();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => best = prefs.getInt(_bestKey) ?? 0);
  }

  void _reset() {
    snake = [const Point(10, 10), const Point(9, 10), const Point(8, 10)];
    dir = const Point(1, 0);
    nextDir = const Point(1, 0);
    over = false;
    started = false;
    apples = 0;
    widget.players[0].score = 0;
    _placeApple();
    timer?.cancel();
    timer = null;
    widget.callbacks.refreshHud();
  }

  void _placeApple() {
    final free = <Point<int>>[];
    for (int y = 0; y < _n; y++) {
      for (int x = 0; x < _n; x++) {
        final p = Point(x, y);
        if (!snake.contains(p)) free.add(p);
      }
    }
    if (free.isEmpty) return;
    apple = free[_rand.nextInt(free.length)];
  }

  Duration get _interval =>
      Duration(milliseconds: max(65, 145 - apples * 4));

  void _ensureRunning() {
    if (started || over) return;
    started = true;
    _startTimer();
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(_interval, (_) => _tick());
  }

  void _steer(Point<int> d) {
    // No reversing into your own neck.
    if (d.x == -dir.x && d.y == -dir.y) return;
    if (d == dir) return;
    nextDir = d;
    _ensureRunning();
    Sfx.tap();
  }

  void _tick() {
    if (over || !mounted) return;
    dir = nextDir;
    final head = snake.first + dir;
    // Wall collision.
    if (head.x < 0 || head.y < 0 || head.x >= _n || head.y >= _n) {
      _die();
      return;
    }
    final eating = head == apple;
    // Self collision (tail tip moves away unless eating).
    final body = eating ? snake : snake.sublist(0, snake.length - 1);
    if (body.contains(head)) {
      _die();
      return;
    }
    setState(() {
      snake = [head, ...body];
      if (eating) {
        apples++;
        widget.players[0].score += 10;
        widget.callbacks.refreshHud();
        _placeApple();
        Sfx.move();
        _startTimer(); // speed up!
      }
    });
  }

  Future<void> _die() async {
    if (over) return;
    setState(() => over = true);
    timer?.cancel();
    Sfx.lose();
    final score = widget.players[0].score;
    final isBest = score > best;
    if (isBest) {
      best = score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestKey, best);
    }
    widget.callbacks.finish(
      headline: 'Score: $score! 🐍',
      subline: isBest ? 'NEW BEST! You absolute legend 🏆' : 'Best: $best — one more run?',
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          ScoreChips(players: widget.players, activeIndex: 0),
          const SizedBox(height: 8),
          Text('BEST: $best  🏆',
              style: TextStyle(color: t.accent, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: GestureDetector(
                  onPanUpdate: (d) {
                    final v = d.delta;
                    if (v.dx.abs() > v.dy.abs()) {
                      _steer(Point(v.dx > 0 ? 1 : -1, 0));
                    } else if (v.dy != 0) {
                      _steer(Point(0, v.dy > 0 ? 1 : -1));
                    }
                  },
                  onTap: _ensureRunning,
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: t.radius,
                      boxShadow: [
                        BoxShadow(
                          color: t.primary.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: t.radius,
                      child: CustomPaint(
                        painter: _SnakePainter(
                          snake: snake,
                          apple: apple,
                          started: started,
                          bg: t.background,
                          snakeColor: widget.players[0].color,
                          appleColor: t.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _dpad(t),
          const SizedBox(height: 8),
          Text('Swipe the board or tap the d-pad 🐍',
              style: TextStyle(color: t.muted, fontSize: 13)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _dpad(GameTheme t) {
    Widget btn(IconData icon, Point<int> d) => Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _steer(d),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: t.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.primary.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Icon(icon, color: t.primary, size: 26),
            ),
          ),
        );
    return SizedBox(
      height: 172,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.keyboard_arrow_up, const Point(0, -1)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              btn(Icons.keyboard_arrow_left, const Point(-1, 0)),
              const SizedBox(width: 64),
              btn(Icons.keyboard_arrow_right, const Point(1, 0)),
            ],
          ),
          const SizedBox(height: 4),
          btn(Icons.keyboard_arrow_down, const Point(0, 1)),
        ],
      ),
    );
  }
}

class _SnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int> apple;
  final bool started;
  final Color bg;
  final Color snakeColor;
  final Color appleColor;

  _SnakePainter({
    required this.snake,
    required this.apple,
    required this.started,
    required this.bg,
    required this.snakeColor,
    required this.appleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 20;
    // faint grid
    final gridPaint = Paint()
      ..color = bg.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    for (int y = 0; y < 20; y++) {
      for (int x = 0; x < 20; x++) {
        if ((x + y).isEven) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), gridPaint);
        }
      }
    }
    // apple with glow
    final appleC = Offset((apple.x + 0.5) * cell, (apple.y + 0.5) * cell);
    final glow = Paint()
      ..color = appleColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(appleC, cell * 0.42, glow);
    canvas.drawCircle(appleC, cell * 0.3, Paint()..color = appleColor);
    // leaf
    canvas.drawCircle(
      appleC + Offset(cell * 0.14, -cell * 0.3),
      cell * 0.1,
      Paint()..color = snakeColor,
    );
    // snake body (tail to head so head draws on top)
    for (int i = snake.length - 1; i >= 0; i--) {
      final p = snake[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(p.x * cell + 1, p.y * cell + 1, cell - 2, cell - 2),
        Radius.circular(cell * (i == 0 ? 0.45 : 0.3)),
      );
      final shade = i == 0
          ? snakeColor
          : Color.lerp(snakeColor, bg, (i / snake.length) * 0.55)!;
      canvas.drawRRect(rect, Paint()..color = shade);
    }
    // head eyes
    if (snake.isNotEmpty) {
      final h = snake.first;
      final c = Offset((h.x + 0.5) * cell, (h.y + 0.5) * cell);
      final eyePaint = Paint()..color = bg;
      final r = cell * 0.09;
      canvas.drawCircle(c + Offset(-cell * 0.14, -cell * 0.1), r, eyePaint);
      canvas.drawCircle(c + Offset(cell * 0.14, -cell * 0.1), r, eyePaint);
    }
    // tap-to-start hint
    if (!started) {
      final tp = TextPainter(
        text: const TextSpan(
          text: '👆 tap or swipe to slither!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: tp.width + 28, height: tp.height + 20),
        const Radius.circular(16),
      );
      canvas.drawRRect(bgRect, Paint()..color = Colors.black54);
      tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _SnakePainter old) =>
      old.snake != snake || old.apple != apple || old.started != started;
}
