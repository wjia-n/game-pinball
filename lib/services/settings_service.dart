import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/ball_styles.dart';
import '../theme/pinball_themes.dart';

/// Game modes.
enum PinballMode { scoreAttack, endless, timeRush }

/// Difficulty tiers — speed/complexity scaling.
enum PinballDifficulty { gentle, parlor, lightning }

/// A renameable player profile: display name + high-score initials.
///
/// Order-safe storage: ONE order-preserving JSON string via setString under
/// [_kNamesJson] — `{"names": ["<name>"], "initials": "<initials>"}`.
/// Android stores StringLists as an unordered StringSet, so ordered data
/// must never use setStringList. Legacy keys are migrated once, then
/// dropped. Saves happen on every keystroke; the settings screen also
/// commits on focus loss.
@immutable
class PinballProfile {
  final String name;
  final String initials;

  const PinballProfile({required this.name, required this.initials});

  static const PinballProfile fallback =
      PinballProfile(name: 'Player', initials: 'YOU');

  String encode() =>
      jsonEncode({'names': [name], 'initials': initials});

  static PinballProfile decode(String? raw) {
    if (raw == null) return fallback;
    try {
      final d = jsonDecode(raw);
      if (d is Map) {
        // New format: {"names": ["<name>"], "initials": "<initials>"}.
        var name = fallback.name;
        final names = d['names'];
        if (names is List && names.isNotEmpty && names.first is String) {
          name = (names.first as String).trim();
        } else if (d['name'] is String) {
          // Legacy format from the first exemplar pass.
          name = (d['name'] as String).trim();
        }
        if (name.isEmpty) name = fallback.name;
        var initials = (d['initials'] is String)
            ? (d['initials'] as String).trim().toUpperCase()
            : fallback.initials;
        if (initials.isEmpty) initials = fallback.initials;
        initials = initials.substring(0, initials.length.clamp(1, 3).toInt());
        return PinballProfile(name: name, initials: initials);
      }
    } catch (_) {}
    return fallback;
  }
}

/// Persisted settings + stats for Pinball. Survives app restarts.
///
/// Stores: audio toggles, renameable player profile (one JSON string),
/// table theme + ball style choices (incl. custom colors), game-mode setup
/// (mode + difficulty), Pro unlock state, and lifetime stats.
class PinballSettings extends ChangeNotifier {
  static const _kMusic = 'pinball_music_on';
  static const _kSfx = 'pinball_sfx_on';
  static const _kVolume = 'pinball_volume';
  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so
  /// ordered name data must never use setStringList. Never use a
  /// StringList for ordered data on Android.
  static const _kNamesJson = 'pinball_player_names_json';
  static const _kTheme = 'pinball_theme_id';
  static const _kBallStyle = 'pinball_ball_style';
  static const _kCustomBall = 'pinball_custom_ball'; // ARGB int, Pro creator
  static const _kCustomPrefix = 'pinball_custom_theme_';
  static const _kMode = 'pinball_mode';
  static const _kDifficulty = 'pinball_difficulty';
  static const _kBestAttack = 'pinball_best_attack';
  static const _kBestEndless = 'pinball_best_endless';
  static const _kBestRush = 'pinball_best_rush';
  static const _kGames = 'pinball_games_played';
  static const _kTips = 'pinball_tips_given';
  static const _kIsPro = 'pinball_is_pro';
  // Legacy keys (migrated once, then dropped).
  static const _kLegacyBest = 'pinball_best';
  static const _kLegacyProfileJson = 'pinball_profile_json';

  static const Map<String, int> _defaultCustomTheme = {
    'woodDark': 0xFF3B2416,
    'woodMid': 0xFF6B4423,
    'woodLight': 0xFF9C6B3F,
    'felt': 0xFF1E4D3B,
    'rail': 0xFF8A6D3B,
    'bumperA': 0xFFC9A227,
    'bumperB': 0xFFA31621,
    'sling': 0xFFD9B36A,
    'laneLit': 0xFFFFD76A,
    'laneUnlit': 0xFF5A4A33,
    'flipper': 0xFFD9B36A,
    'ivory': 0xFFF5EFE0,
    'muted': 0xFFB9A98A,
    'accent': 0xFFC9A227,
  };

  PinballProfile profile = PinballProfile.fallback;
  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String themeId = 'classic-oak';
  String ballStyleId = 'chrome';
  int customBallColor = 0xFFC42E2E; // Pro custom ball creator color
  Map<String, int> customThemeColors = Map.of(_defaultCustomTheme);
  PinballMode mode = PinballMode.scoreAttack;
  PinballDifficulty difficulty = PinballDifficulty.parlor;
  int bestScoreAttack = 0;
  int bestEndless = 0;
  int bestTimeRush = 0;
  int gamesPlayed = 0;
  int tipsGiven = 0;
  bool isPro = false;

  /// Builds the user-designed custom table theme from stored colors.
  PinballThemeDef get customTheme {
    Color c(String k) => Color(customThemeColors[k] ?? 0xFF000000);
    return PinballThemeDef(
      id: 'custom',
      name: 'My Creation',
      isPro: true,
      woodDark: c('woodDark'),
      woodMid: c('woodMid'),
      woodLight: c('woodLight'),
      felt: c('felt'),
      rail: c('rail'),
      bumperA: c('bumperA'),
      bumperB: c('bumperB'),
      sling: c('sling'),
      laneLit: c('laneLit'),
      laneUnlit: c('laneUnlit'),
      flipper: c('flipper'),
      ivory: c('ivory'),
      muted: c('muted'),
      accent: c('accent'),
    );
  }

  /// Custom ball style from the Pro creator color.
  BallStyleDef get customBallStyle {
    final core = Color(customBallColor);
    return BallStyleDef(
      id: 'custom',
      name: 'My Creation',
      isPro: true,
      core: core,
      sheen: const Color(0xFFFFFFFF),
      rim: Color.fromARGB(255, (core.red * 0.4).round(),
          (core.green * 0.4).round(), (core.blue * 0.4).round()),
      trail: core.withValues(alpha: 0.6),
    );
  }

  PinballThemeDef get theme =>
      PinballThemes.byId(themeId, custom: customTheme);

  BallStyleDef get ballStyle =>
      BallStyles.byId(ballStyleId, custom: customBallStyle);

  int get bestForMode => switch (mode) {
        PinballMode.scoreAttack => bestScoreAttack,
        PinballMode.endless => bestEndless,
        PinballMode.timeRush => bestTimeRush,
      };

  /// Balls per game in score-attack mode: 3 free, 5 for Pro.
  int get attackBalls => isPro ? 5 : 3;

  /// Time-rush duration: Pro-only mode, 3 minutes.
  static const timeRushSeconds = 180;

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    // Order-safe names JSON; migrate the legacy key once, then drop it.
    final namesRaw = p.getString(_kNamesJson) ?? p.getString(_kLegacyProfileJson);
    profile = PinballProfile.decode(namesRaw);
    themeId = p.getString(_kTheme) ?? 'classic-oak';
    ballStyleId = p.getString(_kBallStyle) ?? 'chrome';
    customBallColor = p.getInt(_kCustomBall) ?? 0xFFC42E2E;
    for (final k in _defaultCustomTheme.keys) {
      customThemeColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomTheme[k]!;
    }
    mode = PinballMode.values[(p.getInt(_kMode) ?? 0).clamp(0, 2).toInt()];
    difficulty =
        PinballDifficulty.values[(p.getInt(_kDifficulty) ?? 1).clamp(0, 2).toInt()];
    // Legacy migration: the old build stored one int best score.
    final legacyBest = p.getInt(_kLegacyBest);
    bestScoreAttack = p.getInt(_kBestAttack) ?? legacyBest ?? 0;
    if (legacyBest != null) await p.remove(_kLegacyBest);
    bestEndless = p.getInt(_kBestEndless) ?? 0;
    bestTimeRush = p.getInt(_kBestRush) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    tipsGiven = p.getInt(_kTips) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kNamesJson, profile.encode());
    await p.remove(_kLegacyProfileJson); // drop the legacy key for good
    await p.setString(_kTheme, themeId);
    await p.setString(_kBallStyle, ballStyleId);
    await p.setInt(_kCustomBall, customBallColor);
    for (final e in customThemeColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
    await p.setInt(_kMode, mode.index);
    await p.setInt(_kDifficulty, difficulty.index);
    await p.setInt(_kBestAttack, bestScoreAttack);
    await p.setInt(_kBestEndless, bestEndless);
    await p.setInt(_kBestRush, bestTimeRush);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kTips, tipsGiven);
    await p.setBool(_kIsPro, isPro);
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || PinballThemes.isProTheme(themeId)) {
      themeId = 'classic-oak';
      changed = true;
    }
    if (ballStyleId == 'custom' || BallStyles.isProStyle(ballStyleId)) {
      ballStyleId = 'chrome';
      changed = true;
    }
    if (mode == PinballMode.timeRush) {
      mode = PinballMode.scoreAttack;
      changed = true;
    }
    if (difficulty == PinballDifficulty.lightning) {
      difficulty = PinballDifficulty.parlor;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setProfile(String name, String initials) async {
    profile = PinballProfile(
      name: name.trim().isEmpty ? PinballProfile.fallback.name : name.trim(),
      initials: initials.trim().isEmpty
          ? PinballProfile.fallback.initials
          : initials.trim().toUpperCase(),
    );
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
    volume = v.clamp(0.0, 1.0).toDouble();
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || PinballThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setBallStyle(String id) async {
    if (!isPro && (id == 'custom' || BallStyles.isProStyle(id))) return;
    ballStyleId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomBallColor(int argb) async {
    if (!isPro) return; // custom ball creator is a Pro feature
    customBallColor = argb;
    ballStyleId = 'custom';
    notifyListeners();
    await _save();
  }

  Future<void> setCustomThemeColor(String key, int argb) async {
    if (!isPro) return; // custom table theme creator is a Pro feature
    if (!_defaultCustomTheme.containsKey(key)) return;
    customThemeColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomTheme() async {
    customThemeColors = Map.of(_defaultCustomTheme);
    notifyListeners();
    await _save();
  }

  Future<void> setMode(PinballMode m) async {
    if (!isPro && m == PinballMode.timeRush) return; // Pro-only mode
    mode = m;
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(PinballDifficulty d) async {
    if (!isPro && d == PinballDifficulty.lightning) return; // Pro-only tier
    difficulty = d;
    notifyListeners();
    await _save();
  }

  /// Record a finished game; returns true when it is a new mode record.
  Future<bool> recordGame(int score) async {
    gamesPlayed++;
    var record = false;
    switch (mode) {
      case PinballMode.scoreAttack:
        if (score > bestScoreAttack) {
          bestScoreAttack = score;
          record = true;
        }
      case PinballMode.endless:
        if (score > bestEndless) {
          bestEndless = score;
          record = true;
        }
      case PinballMode.timeRush:
        if (score > bestTimeRush) {
          bestTimeRush = score;
          record = true;
        }
    }
    notifyListeners();
    await _save();
    return record;
  }

  Future<void> recordTip() async {
    tipsGiven++;
    notifyListeners();
    await _save();
  }

  Future<void> resetStats() async {
    bestScoreAttack = 0;
    bestEndless = 0;
    bestTimeRush = 0;
    gamesPlayed = 0;
    tipsGiven = 0;
    notifyListeners();
    await _save();
  }
}
