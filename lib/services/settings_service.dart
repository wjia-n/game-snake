import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/garden_themes.dart';

/// Persisted settings + profile + stats for Snake.
///
/// Stores: audio toggles, the renameable player profile (ONE JSON string —
/// never a StringList, which Android stores as an unordered StringSet),
/// mode/difficulty choices, theme/appearance choices (incl. custom colors),
/// Pro unlock state, and per-mode best scores + lifetime stats.
///
/// Legacy migration: the original Snake build stored the best score as the
/// bare int key `snake_best`; on first load it is migrated into the new
/// per-mode best-score key and deleted.
class SnakeSettings extends ChangeNotifier {
  static const _kMusic = 'snake_music_on';
  static const _kSfx = 'snake_sfx_on';
  static const _kVolume = 'snake_volume';
  /// Player names: ONE order-preserving JSON string — NEVER setStringList,
  /// which Android backs with an unordered StringSet and scrambles slots
  /// across restarts. Stored as {"names":[...]} so multi-player games can
  /// share this exact pattern.
  static const _kProfile = 'snake_player_names_json';
  /// Legacy profile keys, migrated once then removed.
  static const _kLegacyProfileJson = 'snake_profile_json'; // {"name": "..."}
  static const _kLegacyProfileBare = 'snake_player_name'; // bare string
  static const _kLegacyProfileList = 'snake_player_names'; // setStringList era
  static const _kTheme = 'snake_theme_id';
  static const _kSnakeStyle = 'snake_snake_style';
  static const _kFoodStyle = 'snake_food_style';
  static const _kMode = 'snake_mode'; // 'classic' | 'wrap' | 'attack'
  static const _kDifficulty = 'snake_difficulty'; // 0..3
  static const _kIsPro = 'snake_is_pro';
  static const _kGames = 'snake_games_played';
  static const _kApples = 'snake_apples_eaten';
  static const _kBestPrefix = 'snake_best_'; // + '<mode>_<difficulty>'
  static const _kCustomPrefix = 'snake_custom_';
  static const _kReviewCount = 'snake_review_count';

  /// Legacy keys migrated once, then removed.
  static const _kLegacyBest = 'snake_best';

  static const defaultName = 'Player';

  static const modes = ['classic', 'wrap', 'attack'];
  static const modeNames = ['Classic Arcade', 'Wrap World', 'Time Attack'];
  static const modeDescriptions = [
    'Endless run. Walls are deadly — classic rules.',
    'Endless run. Walls wrap around — slip through the edge.',
    '60 seconds on the clock. Walls wrap. Eat fast, score big!',
  ];
  static const difficulties = ['Relaxed', 'Classic', 'Speedy', 'Insane'];
  static const difficultyIntervals = [175, 125, 85, 60];
  static const difficultyScores = ['Chill pace', 'True arcade', 'Hot reflexes', 'PRO only'];

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String playerName = defaultName;
  String themeId = 'garden';
  int snakeStyle = 0;
  int foodStyle = 0;
  String mode = 'classic';
  int difficulty = 1;
  bool isPro = true; // everything unlocked — no Pro version
  int gamesPlayed = 0;
  int applesEaten = 0;
  int reviewCount = 0;

  /// Custom theme colors (ARGB ints). Defaults mirror Garden Classic.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'backdropDark': 0xFF17230F,
    'backdropMid': 0xFF243818,
    'boardLight': 0xFF8FBF5F,
    'boardDark': 0xFF7DB04E,
    'frame': 0xFF5C3A21,
    'accent': 0xFFD9A62B,
    'accentLight': 0xFFF2CE6B,
    'accentDark': 0xFF8A6717,
    'ink': 0xFFF6F1DF,
    'snakeHead': 0xFF3FA34D,
    'snakeBody': 0xFF2E7D3A,
    'food': 0xFFD64545,
    'golden': 0xFFFFD23F,
  };

  GardenThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return GardenThemeDef(
      id: 'custom',
      name: 'My Creation',
      backdropDark: c('backdropDark'),
      backdropMid: c('backdropMid'),
      boardLight: c('boardLight'),
      boardDark: c('boardDark'),
      frame: c('frame'),
      frameEdge: c('backdropDark'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      ink: c('ink'),
      inkDim: c('ink'),
      snakeHead: c('snakeHead'),
      snakeBody: c('snakeBody'),
      food: c('food'),
      golden: c('golden'),
    );
  }

  SharedPreferences? _prefs;

  String _bestKey(String m, int d) => '$_kBestPrefix${m}_$d';

  int bestScore(String m, int d) =>
      _prefs?.getInt(_bestKey(m, d)) ?? 0;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    await _migrateProfile(p);
    playerName = _decodeNames(p.getString(_kProfile));
    themeId = p.getString(_kTheme) ?? 'garden';
    snakeStyle = (p.getInt(_kSnakeStyle) ?? 0).clamp(0, SnakeStyles.names.length - 1);
    foodStyle = (p.getInt(_kFoodStyle) ?? 0).clamp(0, FoodStyles.names.length - 1);
    final m = p.getString(_kMode) ?? 'classic';
    mode = modes.contains(m) ? m : 'classic';
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 3);
    isPro = true; // everything unlocked
    gamesPlayed = p.getInt(_kGames) ?? 0;
    applesEaten = p.getInt(_kApples) ?? 0;
    reviewCount = p.getInt(_kReviewCount) ?? 0;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    // One-time legacy migration: the very first Snake build stored the best
    // score as a bare int. Fold it into the new per-mode key and drop it.
    final legacyBest = p.getInt(_kLegacyBest);
    if (legacyBest != null) {
      final cur = p.getInt(_bestKey('classic', 1)) ?? 0;
      if (legacyBest > cur) {
        await p.setInt(_bestKey('classic', 1), legacyBest);
      }
      await p.remove(_kLegacyBest);
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  /// Encode the name list as one order-preserving JSON string.
  static String encodeNames(List<String> names) =>
      jsonEncode({'names': names});

  /// Decode, tolerating the current {"names":[...]} shape and the old
  /// {"name":"..."} single-profile shape.
  static String _decodeNames(String? raw) {
    if (raw == null) return defaultName;
    try {
      final d = jsonDecode(raw);
      if (d is Map) {
        final n = d['names'];
        if (n is List && n.isNotEmpty) {
          final first = n.first.toString().trim();
          return first.isEmpty ? defaultName : first;
        }
        final single = (d['name'] as String?)?.trim() ?? '';
        return single.isEmpty ? defaultName : single;
      }
    } catch (_) {}
    return defaultName;
  }

  /// One-time migration of every legacy profile key into the canonical
  /// `snake_player_names_json` key. Runs before the first read.
  Future<void> _migrateProfile(SharedPreferences p) async {
    if (p.getString(_kProfile) != null) {
      // Already on the canonical key — still scrub legacy keys.
      await p.remove(_kLegacyProfileJson);
      await p.remove(_kLegacyProfileBare);
      await p.remove(_kLegacyProfileList);
      return;
    }
    String name = '';
    final legacyJson = p.getString(_kLegacyProfileJson);
    if (legacyJson != null) {
      name = _decodeNames(legacyJson);
    }
    final bare = p.getString(_kLegacyProfileBare);
    if (name.isEmpty || name == defaultName) {
      if (bare != null && bare.trim().isNotEmpty) name = bare.trim();
    }
    if (name.isEmpty || name == defaultName) {
      try {
        final legacyList = p.getStringList(_kLegacyProfileList);
        if (legacyList != null && legacyList.isNotEmpty) {
          name = legacyList.first.trim();
        }
      } catch (_) {}
    }
    if (name.isNotEmpty && name != defaultName) {
      await p.setString(_kProfile, encodeNames([name]));
    }
    await p.remove(_kLegacyProfileJson);
    await p.remove(_kLegacyProfileBare);
    await p.remove(_kLegacyProfileList);
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kProfile, encodeNames([playerName]));
    await p.setString(_kTheme, themeId);
    await p.setInt(_kSnakeStyle, snakeStyle);
    await p.setInt(_kFoodStyle, foodStyle);
    await p.setString(_kMode, mode);
    await p.setInt(_kDifficulty, difficulty);
    await p.setBool(_kIsPro, isPro);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kApples, applesEaten);
    await p.setInt(_kReviewCount, reviewCount);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || GardenThemes.isProTheme(themeId)) {
      themeId = 'garden';
      changed = true;
    }
    if (SnakeStyles.isPro(snakeStyle)) {
      snakeStyle = 0;
      changed = true;
    }
    if (FoodStyles.isPro(foodStyle)) {
      foodStyle = 0;
      changed = true;
    }
    if (difficulty > 2) {
      difficulty = 1;
      changed = true;
    }
    if (mode == 'attack') {
      mode = 'classic';
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      unawaited(_save());
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(String name) async {
    final clean = name.trim();
    playerName = clean.isEmpty ? defaultName : clean;
    notifyListeners();
    await _save();
  }

  /// Draft write for live-editing fields: persists EVERY keystroke
  /// immediately (no notify — the typing field owns its own controller, so
  /// a rebuild loop would just fight the keyboard).
  Future<void> saveNameDraft(String name) async {
    playerName = name;
    final p = _prefs;
    if (p == null) return;
    await p.setString(_kProfile, encodeNames([name]));
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || GardenThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setSnakeStyle(int v) async {
    v = v.clamp(0, SnakeStyles.names.length - 1);
    if (!isPro && SnakeStyles.isPro(v)) return;
    snakeStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setFoodStyle(int v) async {
    v = v.clamp(0, FoodStyles.names.length - 1);
    if (!isPro && FoodStyles.isPro(v)) return;
    foodStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setMode(String m) async {
    if (!modes.contains(m)) return;
    if (!isPro && m == 'attack') return; // Time Attack is a Pro mode
    mode = m;
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int d) async {
    d = d.clamp(0, 3);
    if (!isPro && d > 2) return; // Insane is Pro
    difficulty = d;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  /// Record a finished run. Returns true when [score] is a new best.
  Future<bool> recordRun({
    required String m,
    required int d,
    required int score,
    required int apples,
  }) async {
    gamesPlayed++;
    applesEaten += apples;
    var newBest = false;
    if (score > 0) {
      final cur = bestScore(m, d);
      if (score > cur) {
        await _prefs?.setInt(_bestKey(m, d), score);
        newBest = true;
      }
    }
    notifyListeners();
    await _save();
    return newBest;
  }

  /// True when it is a sensible moment to ask for a store review.
  bool get shouldAskReview => {3, 10, 25, 60}.contains(gamesPlayed);

  Future<void> bumpReviewCount() async {
    reviewCount++;
    notifyListeners();
    await _save();
  }

  Future<void> resetStats() async {
    gamesPlayed = 0;
    applesEaten = 0;
    for (final m in modes) {
      for (int d = 0; d < 4; d++) {
        await _prefs?.remove(_bestKey(m, d));
      }
    }
    notifyListeners();
    await _save();
  }
}
