import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Visual shape language a theme uses.
enum ShapeStyle { rounded, sharp, bubble, stadium }

/// One complete visual theme. Every game ships all of these and the
/// player can switch any time - maximum design variety, zero extra work
/// for the individual game.
class GameTheme {
  final String id;
  final String name;
  final String emoji;
  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color text;
  final Color muted;
  final ShapeStyle shape;
  final bool dark;

  const GameTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.text,
    required this.muted,
    required this.shape,
    required this.dark,
  });

  BorderRadius get radius {
    switch (shape) {
      case ShapeStyle.rounded:
        return BorderRadius.circular(18);
      case ShapeStyle.sharp:
        return BorderRadius.circular(4);
      case ShapeStyle.bubble:
        return BorderRadius.circular(28);
      case ShapeStyle.stadium:
        return BorderRadius.circular(999);
    }
  }

  double get elevation => dark ? 6 : 3;

  LinearGradient get headerGradient =>
      LinearGradient(colors: [primary, secondary], begin: Alignment.topLeft, end: Alignment.bottomRight);

  ThemeData get materialTheme {
    final scheme = ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: dark ? Colors.black : Colors.white,
      secondary: secondary,
      onSecondary: dark ? Colors.black : Colors.white,
      tertiary: accent,
      surface: surface,
      onSurface: text,
      error: const Color(0xFFE5484D),
      onError: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Nunito',
      textTheme: TextTheme(
        displayLarge: TextStyle(color: text, fontWeight: FontWeight.w900),
        headlineMedium: TextStyle(color: text, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(color: text, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: muted),
      ),
    );
  }
}

/// The full built-in theme catalogue.
class GameThemes {
  static const List<GameTheme> all = [
    GameTheme(
      id: 'neon', name: 'Midnight Neon', emoji: '🌃',
      background: Color(0xFF0B0B1A), surface: Color(0xFF171730),
      primary: Color(0xFF00F5D4), secondary: Color(0xFF7B2FF7),
      accent: Color(0xFFFF2E88), text: Color(0xFFF4F4FF), muted: Color(0xFF9A9AC0),
      shape: ShapeStyle.rounded, dark: true,
    ),
    GameTheme(
      id: 'candy', name: 'Candy Pop', emoji: '🍬',
      background: Color(0xFFFFF3F8), surface: Color(0xFFFFFFFF),
      primary: Color(0xFFFF5DA2), secondary: Color(0xFF7C5CFF),
      accent: Color(0xFFFFC531), text: Color(0xFF3A2340), muted: Color(0xFF9A7FA3),
      shape: ShapeStyle.bubble, dark: false,
    ),
    GameTheme(
      id: 'forest', name: 'Forest Calm', emoji: '🌲',
      background: Color(0xFF0E1F16), surface: Color(0xFF1A3325),
      primary: Color(0xFF7BF1A8), secondary: Color(0xFF2E9E6B),
      accent: Color(0xFFFFD166), text: Color(0xFFF1FBEF), muted: Color(0xFF8FAE9A),
      shape: ShapeStyle.rounded, dark: true,
    ),
    GameTheme(
      id: 'ocean', name: 'Ocean Deep', emoji: '🌊',
      background: Color(0xFF041C2C), surface: Color(0xFF0A2E47),
      primary: Color(0xFF4CC9F0), secondary: Color(0xFF4361EE),
      accent: Color(0xFFF72585), text: Color(0xFFEAF6FF), muted: Color(0xFF7FA8C4),
      shape: ShapeStyle.stadium, dark: true,
    ),
    GameTheme(
      id: 'sunset', name: 'Sunset Glow', emoji: '🌅',
      background: Color(0xFF2B0F1E), surface: Color(0xFF3F1830),
      primary: Color(0xFFFF9E4F), secondary: Color(0xFFFF4D6D),
      accent: Color(0xFFFFD166), text: Color(0xFFFFF3E8), muted: Color(0xFFC49AA8),
      shape: ShapeStyle.rounded, dark: true,
    ),
    GameTheme(
      id: 'mono', name: 'Ink Mono', emoji: '🖋️',
      background: Color(0xFFFAFAFA), surface: Color(0xFFFFFFFF),
      primary: Color(0xFF111111), secondary: Color(0xFF555555),
      accent: Color(0xFFE5484D), text: Color(0xFF111111), muted: Color(0xFF888888),
      shape: ShapeStyle.sharp, dark: false,
    ),
    GameTheme(
      id: 'royal', name: 'Royal Purple', emoji: '👑',
      background: Color(0xFF1A0B2E), surface: Color(0xFF2A1545),
      primary: Color(0xFFB967FF), secondary: Color(0xFF5C2E9E),
      accent: Color(0xFF05FFA1), text: Color(0xFFF6EEFF), muted: Color(0xFFA98BC9),
      shape: ShapeStyle.bubble, dark: true,
    ),
    GameTheme(
      id: 'citrus', name: 'Citrus Zing', emoji: '🍋',
      background: Color(0xFFFFFBEB), surface: Color(0xFFFFFFFF),
      primary: Color(0xFFF59E0B), secondary: Color(0xFF84CC16),
      accent: Color(0xFFEF4444), text: Color(0xFF422006), muted: Color(0xFFA16207),
      shape: ShapeStyle.stadium, dark: false,
    ),
  ];

  static GameTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);
}

/// Holds the active theme, persists the choice, notifies listeners.
class ThemeController extends ChangeNotifier {
  static const _key = 'wajiha_theme_id';
  GameTheme _theme = GameThemes.all.first;

  GameTheme get theme => _theme;

  /// Reach the nearest controller. The app must be wrapped in [ThemeScope]
  /// (GameShell does this automatically).
  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ThemeScope>();
    assert(scope != null, 'ThemeController.of() called with no ThemeScope ancestor.');
    return scope!.controller;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_key);
    if (id != null) _theme = GameThemes.byId(id);
    notifyListeners();
  }

  Future<void> setTheme(GameTheme theme) async {
    _theme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.id);
  }
}

class _ThemeScope extends InheritedWidget {
  final ThemeController controller;
  const _ThemeScope({required this.controller, required super.child});

  @override
  bool updateShouldNotify(_ThemeScope old) => old.controller != controller;
}

/// Wraps the app so every game screen can reach the ThemeController.
class ThemeScope extends StatelessWidget {
  final ThemeController controller;
  final Widget child;
  const ThemeScope({super.key, required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    return _ThemeScope(controller: controller, child: child);
  }
}
