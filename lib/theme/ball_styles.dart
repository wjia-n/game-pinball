import 'package:flutter/material.dart';

/// Ball + plunger styles for Pinball. Physical materials only — chrome,
/// brass, copper, ivory, wood, marble. The plunger rod matches the ball.
@immutable
class BallStyleDef {
  final String id;
  final String name;
  final bool isPro;
  final Color core; // main ball color
  final Color sheen; // highlight color
  final Color rim; // edge color
  final Color trail; // trail color

  const BallStyleDef({
    required this.id,
    required this.name,
    this.isPro = false,
    required this.core,
    required this.sheen,
    required this.rim,
    required this.trail,
  });
}

class BallStyles {
  static const List<BallStyleDef> all = [
    BallStyleDef(
      id: 'chrome',
      name: 'Chrome',
      core: Color(0xFFC8CCD4),
      sheen: Color(0xFFFFFFFF),
      rim: Color(0xFF5A6068),
      trail: Color(0xFF9AA2AC),
    ),
    BallStyleDef(
      id: 'brass',
      name: 'Brass',
      core: Color(0xFFD9A441),
      sheen: Color(0xFFFFE8A0),
      rim: Color(0xFF8A6420),
      trail: Color(0xFFC99B5F),
    ),
    BallStyleDef(
      id: 'ivory',
      name: 'Ivory Pearl',
      core: Color(0xFFF5EFE0),
      sheen: Color(0xFFFFFFFF),
      rim: Color(0xFFB4A888),
      trail: Color(0xFFD8CCB0),
    ),
    BallStyleDef(
      id: 'wooden',
      name: 'Maple Wood',
      core: Color(0xFF9C6B3F),
      sheen: Color(0xFFD9A878),
      rim: Color(0xFF5E3A1E),
      trail: Color(0xFF8A5E2E),
    ),
    // ---------------- Pro styles ----------------
    BallStyleDef(
      id: 'copper',
      name: 'Copper',
      isPro: true,
      core: Color(0xFFC8784A),
      sheen: Color(0xFFFFC898),
      rim: Color(0xFF7A3E20),
      trail: Color(0xFFB06838),
    ),
    BallStyleDef(
      id: 'obsidian',
      name: 'Obsidian',
      isPro: true,
      core: Color(0xFF2E2E34),
      sheen: Color(0xFF8A8A98),
      rim: Color(0xFF0E0E12),
      trail: Color(0xFF5A5A64),
    ),
    BallStyleDef(
      id: 'marble',
      name: 'Marble',
      isPro: true,
      core: Color(0xFFE8E4DC),
      sheen: Color(0xFFFFFFFF),
      rim: Color(0xFF8A8E94),
      trail: Color(0xFFB4B8BE),
    ),
    BallStyleDef(
      id: 'candy',
      name: 'Candy Red',
      isPro: true,
      core: Color(0xFFC42E2E),
      sheen: Color(0xFFFF9A8A),
      rim: Color(0xFF6E1414),
      trail: Color(0xFFA82828),
    ),
    BallStyleDef(
      id: 'ocean',
      name: 'Ocean Blue',
      isPro: true,
      core: Color(0xFF2E5E8A),
      sheen: Color(0xFF9AC8E8),
      rim: Color(0xFF142E44),
      trail: Color(0xFF4A7AA8),
    ),
  ];

  static BallStyleDef byId(String id, {BallStyleDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final s in all) {
      if (s.id == id) return s;
    }
    return all.first;
  }

  static bool isProStyle(String id) =>
      all.any((s) => s.id == id && s.isPro);
}
