import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const PinballApp());

class PinballApp extends StatelessWidget {
  const PinballApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.retroCabinet,
      title: 'Pinball',
      tagline: 'Flip, bump and chase the high score on neon tables',
      emoji: '🔴',
      slug: 'pinball',
      howToPlay: '• Hold PLUNGE to charge, release to launch\n'
          '• Hold LEFT / RIGHT to swing the flippers\n'
          '• Light all 3 top lanes to raise your multiplier\n'
          '• Nudge carefully — 3 quick nudges = TILT!',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          PinballScreen(players: players, callbacks: cb),
    );
  }
}
