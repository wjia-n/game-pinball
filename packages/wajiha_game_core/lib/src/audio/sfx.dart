import 'package:flutter/services.dart';

/// Tiny sound/haptic helper. Games call these at key moments -
/// they are safe no-ops where haptics are unavailable.
class Sfx {
  static void tap() => HapticFeedback.selectionClick();
  static void click() => HapticFeedback.lightImpact();
  static void move() => HapticFeedback.mediumImpact();
  static void win() => HapticFeedback.heavyImpact();
  static void lose() => HapticFeedback.vibrate();
}
