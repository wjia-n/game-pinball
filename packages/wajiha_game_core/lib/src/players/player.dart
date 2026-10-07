import 'package:flutter/material.dart';

/// A participant in a local match - a human on this device or a bot.
class Player {
  final String name;
  final Color color;
  final String emoji;
  final bool isBot;
  int score;

  Player({
    required this.name,
    required this.color,
    required this.emoji,
    this.isBot = false,
    this.score = 0,
  });

  Player copyWith({int? score}) => Player(
        name: name,
        color: color,
        emoji: emoji,
        isBot: isBot,
        score: score ?? this.score,
      );
}

/// Fun default identities for quick party setup.
class PlayerPresets {
  static const names = [
    'Nova', 'Pixel', 'Ziggy', 'Luna', 'Rocco', 'Mimi', 'Jax', 'Poppy',
    'Turbo', 'Sunny', 'Kiki', 'Bolt', 'Waffles', 'Echo',
  ];
  static const emojis = [
    '🦊', '🐼', '🦁', '🐸', '🐵', '🦄', '🐙', '🐝',
    '🦋', '🐢', '🦩', '🐳', '🍕', '🚀',
  ];
  static const colors = [
    Color(0xFFFF5DA2), Color(0xFF4CC9F0), Color(0xFF7BF1A8), Color(0xFFFFC531),
    Color(0xFFB967FF), Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFFFF9E4F),
  ];

  static Player make(int index, {bool isBot = false}) => Player(
        name: isBot ? 'Bot ${names[index % names.length]}' : names[index % names.length],
        color: colors[index % colors.length],
        emoji: emojis[index % emojis.length],
        isBot: isBot,
      );
}
