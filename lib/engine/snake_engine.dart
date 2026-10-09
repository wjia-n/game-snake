import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Phases owned entirely by the engine. The UI only renders.
/// - idle: board shown, tap/swipe to start.
/// - countdown: 3·2·1·GO before the snake moves.
/// - running: the tick timer owns movement; input is steering.
/// - paused: timers frozen; resume re-arms the current phase.
/// - dying: crash animation plays; input locked; leads to [over].
/// - over: run finished, final score settled.
enum Phase { idle, countdown, running, paused, dying, over }

/// UI hook for sounds / haptics / floating feedback. Set by the screen.
enum SnakeEvent {
  start,
  steer,
  eat,
  golden,
  goldenSpawn,
  countdownTick,
  death,
  timeUp,
  invalid,
}

/// Snake engine: deterministic rules, tick loop, golden food, streaks.
/// UI-agnostic — it notifies listeners and the screen renders.
class SnakeEngine extends ChangeNotifier {
  static const n = 20; // 20x20 board
  static const attackSeconds = 60;

  final String mode; // 'classic' | 'wrap' | 'attack'
  final int difficulty; // 0..3
  final int tickMs; // base interval for this difficulty

  List<Point<int>> snake = [];
  Point<int> food = const Point(10, 10);
  Point<int>? golden;
  int _goldenTicksLeft = 0;
  int _goldenSpawnIn = 0;

  Point<int> dir = const Point(1, 0);
  Point<int> nextDir = const Point(1, 0);

  Phase phase = Phase.idle;
  Phase _resumePhase = Phase.running; // phase to return to after pausing
  int score = 0;
  int apples = 0;
  int streak = 0;
  int countdown = 0;
  int ticks = 0;
  int attackTicksLeft = attackSeconds * 1000 ~/ 125;
  bool newBest = false;
  String banner = '';
  String deathCause = '';

  /// UI hook for sounds / haptics. Set by the screen.
  void Function(SnakeEvent event)? onEvent;

  final _rand = Random();
  Timer? _timer; // single phase-transition / tick timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;

  bool get wrapWalls => mode != 'classic';
  bool get isAttack => mode == 'attack';
  int get intervalMs =>
      max(45, tickMs - apples * 3); // speeds up as you eat

  SnakeEngine({
    required this.mode,
    required this.difficulty,
    required this.tickMs,
  }) {
    _reset();
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) => _recover());
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _reset() {
    snake = [
      const Point(10, 10),
      const Point(9, 10),
      const Point(8, 10),
    ];
    dir = const Point(1, 0);
    nextDir = const Point(1, 0);
    golden = null;
    _goldenTicksLeft = 0;
    _goldenSpawnIn = _goldenSpawnInterval();
    score = 0;
    apples = 0;
    streak = 0;
    countdown = 0;
    ticks = 0;
    attackTicksLeft = attackSeconds * 1000 ~/ tickMs;
    newBest = false;
    deathCause = '';
    phase = Phase.idle;
    banner = isAttack
        ? 'Eat fast — $attackSeconds seconds on the clock!'
        : wrapWalls
            ? 'Slip through the walls — they wrap around!'
            : 'Eat apples, dodge walls and your own tail!';
    _placeFood();
  }

  int _goldenSpawnInterval() =>
      (isAttack ? 7000 : 14000) ~/ tickMs; // ticks between golden spawns

  void _placeFood() {
    final free = <Point<int>>[];
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        final p = Point(x, y);
        if (!snake.contains(p) && p != golden) free.add(p);
      }
    }
    if (free.isEmpty) return; // board full: you win by filling it
    food = free[_rand.nextInt(free.length)];
  }

  // -------------------------------------------------------------- timers
  /// Arm (or re-arm) the single engine timer. Paused engines never arm.
  void _arm(Duration d, void Function() fn) {
    if (_disposed || phase == Phase.paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && phase != Phase.paused) fn();
    });
  }

  /// Watchdog: if the single timer ever dies without progress, recover.
  /// This makes stuck states impossible by construction. Respects [paused].
  void _recover() {
    if (_disposed || phase == Phase.paused || _timer != null) return;
    switch (phase) {
      case Phase.running:
        _tick(); // tick loop died: step immediately, timer re-arms
      case Phase.countdown:
        _countdownStep();
      case Phase.dying:
        _finish();
      case Phase.idle:
      case Phase.over:
      case Phase.paused:
        break; // quiescent phases need no timer
    }
  }

  // -------------------------------------------------------------- control
  /// Player taps the board: start / skip countdown / resume.
  void tap() {
    switch (phase) {
      case Phase.idle:
        start();
      case Phase.countdown:
        _skipCountdown();
      case Phase.paused:
        setPaused(false);
      case Phase.running:
      case Phase.dying:
      case Phase.over:
        break; // nothing to do
    }
  }

  /// Begin a run: countdown then go.
  void start() {
    if (phase != Phase.idle && phase != Phase.over) return;
    if (phase == Phase.over) _reset();
    countdown = 3;
    phase = Phase.countdown;
    banner = 'Get ready…';
    onEvent?.call(SnakeEvent.start);
    notifyListeners();
    _arm(const Duration(milliseconds: 550), _countdownStep);
  }

  void _skipCountdown() {
    _timer?.cancel();
    countdown = 0;
    phase = Phase.running;
    banner = '';
    notifyListeners();
    _arm(Duration(milliseconds: intervalMs), _tick);
  }

  void _countdownStep() {
    if (_disposed || phase != Phase.countdown) return;
    countdown--;
    if (countdown > 0) {
      onEvent?.call(SnakeEvent.countdownTick);
      notifyListeners();
      _arm(const Duration(milliseconds: 550), _countdownStep);
    } else {
      onEvent?.call(SnakeEvent.countdownTick);
      phase = Phase.running;
      banner = '';
      notifyListeners();
      _arm(Duration(milliseconds: intervalMs), _tick);
    }
  }

  /// Steering input. Reversing into your own neck is illegal and ignored
  /// (the snake keeps gliding) — RULES §5.
  void steer(Point<int> d) {
    if (phase != Phase.running) {
      // Helpful: a first swipe also starts the game.
      if (phase == Phase.idle) start();
      return;
    }
    if (d.x == -dir.x && d.y == -dir.y) {
      onEvent?.call(SnakeEvent.invalid);
      return;
    }
    if (d == dir || d == nextDir) return;
    nextDir = d;
    onEvent?.call(SnakeEvent.steer);
  }

  /// Pause: freeze the timer. Resume re-arms the current phase.
  void setPaused(bool v) {
    if (_disposed) return;
    if (v) {
      if (phase != Phase.running && phase != Phase.countdown) return;
      _resumePhase = phase;
      phase = Phase.paused;
      _timer?.cancel();
      _timer = null;
    } else {
      if (phase != Phase.paused) return;
      phase = _resumePhase;
      _recover();
    }
    notifyListeners();
  }

  /// Restart from scratch back to idle.
  void restart() {
    _timer?.cancel();
    _reset();
    notifyListeners();
  }

  // ----------------------------------------------------------------- ticks
  void _tick() {
    if (_disposed || phase != Phase.running) return;
    dir = nextDir;
    ticks++;
    if (isAttack) {
      attackTicksLeft--;
      if (attackTicksLeft <= 0) {
        _timeUp();
        return;
      }
    }
    _updateGolden();
    final head = snake.first + dir;
    final wrapped = _wrap(head);
    // Wall collision (classic mode only — wrap modes tunnel through).
    if (!wrapWalls &&
        (head.x < 0 || head.y < 0 || head.x >= n || head.y >= n)) {
      deathCause = 'wall';
      _die();
      return;
    }
    final eating = wrapped == food;
    final eatingGolden = golden != null && wrapped == golden;
    // Self collision (the tail tip moves away unless we are growing).
    final body = (eating || eatingGolden)
        ? snake
        : snake.sublist(0, snake.length - 1);
    if (body.contains(wrapped)) {
      deathCause = 'tail';
      _die();
      return;
    }
    snake = [wrapped, ...body];
    if (eating) {
      _eatApple();
    } else if (eatingGolden) {
      _eatGolden();
    }
    // Board full = legendary win.
    if (snake.length >= n * n) {
      deathCause = 'board-full';
      _die();
      return;
    }
    notifyListeners();
    _arm(Duration(milliseconds: intervalMs), _tick);
  }

  Point<int> _wrap(Point<int> p) {
    if (wrapWalls) {
      return Point((p.x % n + n) % n, (p.y % n + n) % n);
    }
    return p;
  }

  void _eatApple() {
    apples++;
    streak++;
    var gained = 10;
    if (streak % 5 == 0) {
      gained += 25; // streak bonus every 5th apple in a row
      banner = 'Streak x$streak! +$gained';
    }
    score += gained;
    _placeFood();
    onEvent?.call(SnakeEvent.eat);
  }

  void _eatGolden() {
    apples++;
    streak = 0; // golden resets the streak counter
    score += 50;
    golden = null;
    _goldenTicksLeft = 0;
    _goldenSpawnIn = _goldenSpawnInterval();
    banner = 'Golden apple! +50';
    onEvent?.call(SnakeEvent.golden);
  }

  void _updateGolden() {
    if (golden != null) {
      _goldenTicksLeft--;
      if (_goldenTicksLeft <= 0) {
        golden = null;
        _goldenSpawnIn = _goldenSpawnInterval();
      }
    } else {
      _goldenSpawnIn--;
      if (_goldenSpawnIn <= 0) {
        final free = <Point<int>>[];
        for (int y = 0; y < n; y++) {
          for (int x = 0; x < n; x++) {
            final p = Point(x, y);
            if (!snake.contains(p) && p != food) free.add(p);
          }
        }
        if (free.isNotEmpty) {
          golden = free[_rand.nextInt(free.length)];
          _goldenTicksLeft = (isAttack ? 6000 : 8000) ~/ tickMs;
          onEvent?.call(SnakeEvent.goldenSpawn);
        }
        _goldenSpawnIn = _goldenSpawnInterval();
      }
    }
  }

  void _die() {
    if (phase != Phase.running) return;
    phase = Phase.dying;
    banner = switch (deathCause) {
      'wall' => 'Ouch — wall crash!',
      'tail' => 'Ouch — tail bite!',
      'board-full' => 'Legendary — the board is FULL!',
      _ => 'Run over!',
    };
    onEvent?.call(SnakeEvent.death);
    notifyListeners();
    _arm(const Duration(milliseconds: 1100), _finish);
  }

  void _timeUp() {
    phase = Phase.dying; // brief flourish before the results card
    banner = 'Time\'s up!';
    deathCause = 'time';
    onEvent?.call(SnakeEvent.timeUp);
    notifyListeners();
    _arm(const Duration(milliseconds: 800), _finish);
  }

  void _finish() {
    if (_disposed || phase == Phase.over) return;
    phase = Phase.over;
    notifyListeners();
  }
}
