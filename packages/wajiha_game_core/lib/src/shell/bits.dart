import 'package:flutter/material.dart';
import '../players/player.dart';
import '../theme/game_theme.dart';
import 'shell_variants.dart';

/// Big friendly button — renders through the active shell variant's skin.
class WajihaButton extends StatelessWidget {
  final String label;
  final String? emoji;
  final VoidCallback onTap;
  final bool primary;
  final double fontSize;

  const WajihaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.emoji,
    this.primary = true,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return ShellVariantScope.skinOf(context).buildButton(
      context,
      t,
      label: label,
      emoji: emoji,
      onTap: onTap,
      primary: primary,
      fontSize: fontSize,
    );
  }
}

/// Round icon button for the home-screen action row — skinned.
class CircleAction extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const CircleAction({super.key, required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return ShellVariantScope.skinOf(context)
        .buildActionButton(context, t, emoji, label, onTap);
  }
}

/// Row of player score chips shown above the board — skinned.
class ScoreChips extends StatelessWidget {
  final List<Player> players;
  final int activeIndex;

  const ScoreChips({super.key, required this.players, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return ShellVariantScope.skinOf(context)
        .buildScoreChips(context, t, players, activeIndex);
  }
}

/// Banner announcing whose turn it is (pass-and-play party helper) — skinned.
class TurnBanner extends StatelessWidget {
  final Player player;
  final String action;

  const TurnBanner({super.key, required this.player, required this.action});

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return ShellVariantScope.skinOf(context)
        .buildTurnBanner(context, t, player, action);
  }
}

/// Simple themed dialog shell — skinned.
class WajihaDialog extends StatelessWidget {
  final String title;
  final String? emoji;
  final List<Widget> children;

  const WajihaDialog({super.key, required this.title, this.emoji, required this.children});

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return ShellVariantScope.skinOf(context)
        .buildDialog(context, t, title: title, emoji: emoji, children: children);
  }
}
