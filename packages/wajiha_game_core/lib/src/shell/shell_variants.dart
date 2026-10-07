import 'package:flutter/material.dart';
import '../audio/sfx.dart';
import '../players/player.dart';
import '../theme/game_theme.dart';
import '../marketing/cross_promo.dart';

/// Twelve completely distinct visual identities for the game shell.
/// Each game app picks one via `GameShell(variant: ...)` so no two
/// games feel like they came from the same template.
enum ShellVariant {
  neonArcade,
  cozyPaper,
  zenStone,
  comicBurst,
  retroCabinet,
  softBlob,
  midnightNeon,
  playfulPop,
  elegantSerif,
  graffitiWall,
  aquaDepth,
  candyShop,
}

/// Maps a variant to its skin instance.
extension ShellVariantSkin on ShellVariant {
  ShellSkin get skin => switch (this) {
        ShellVariant.neonArcade => const NeonArcadeSkin(),
        ShellVariant.cozyPaper => const CozyPaperSkin(),
        ShellVariant.zenStone => const ZenStoneSkin(),
        ShellVariant.comicBurst => const ComicBurstSkin(),
        ShellVariant.retroCabinet => const RetroCabinetSkin(),
        ShellVariant.softBlob => const SoftBlobSkin(),
        ShellVariant.midnightNeon => const MidnightNeonSkin(),
        ShellVariant.playfulPop => const PlayfulPopSkin(),
        ShellVariant.elegantSerif => const ElegantSerifSkin(),
        ShellVariant.graffitiWall => const GraffitiWallSkin(),
        ShellVariant.aquaDepth => const AquaDepthSkin(),
        ShellVariant.candyShop => const CandyShopSkin(),
      };

  String get displayName => switch (this) {
        ShellVariant.neonArcade => 'Neon Arcade',
        ShellVariant.cozyPaper => 'Cozy Paper',
        ShellVariant.zenStone => 'Zen Stone',
        ShellVariant.comicBurst => 'Comic Burst',
        ShellVariant.retroCabinet => 'Retro Cabinet',
        ShellVariant.softBlob => 'Soft Blob',
        ShellVariant.midnightNeon => 'Midnight Neon',
        ShellVariant.playfulPop => 'Playful Pop',
        ShellVariant.elegantSerif => 'Elegant Serif',
        ShellVariant.graffitiWall => 'Graffiti Wall',
        ShellVariant.aquaDepth => 'Aqua Depth',
        ShellVariant.candyShop => 'Candy Shop',
      };
}

/// Provides the active [ShellSkin] down the widget tree (like ThemeScope).
class ShellVariantScope extends InheritedWidget {
  final ShellSkin skin;
  const ShellVariantScope({super.key, required this.skin, required super.child});

  /// Returns the active skin, falling back to Playful Pop outside a scope.
  static ShellSkin skinOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShellVariantScope>();
    return scope?.skin ?? ShellVariant.playfulPop.skin;
  }

  @override
  bool updateShouldNotify(ShellVariantScope old) => old.skin != skin;
}

/// Everything a home screen needs, handed to the skin's home builder.
class ShellHomeData {
  final String title;
  final String tagline;
  final String emoji;
  final String slug;
  final VoidCallback onPlay;
  final VoidCallback onHowTo;
  final VoidCallback onThemes;
  final VoidCallback onTipJar;
  final VoidCallback onMoreGames;

  const ShellHomeData({
    required this.title,
    required this.tagline,
    required this.emoji,
    required this.slug,
    required this.onPlay,
    required this.onHowTo,
    required this.onThemes,
    required this.onTipJar,
    required this.onMoreGames,
  });
}

/// Observable player-setup state shared by every variant's setup screen.
class PlayerSetupModel extends ChangeNotifier {
  final List<int> options;
  final bool supportsBots;
  late int count;
  late int seats;
  late List<bool> bots;
  int shuffleSeed = 0;

  PlayerSetupModel({required this.options, required this.supportsBots}) {
    _configure(options.first);
  }

  void _configure(int c) {
    count = c;
    if (c == 1 && supportsBots) {
      seats = 2;
      bots = [false, true];
    } else {
      seats = c;
      bots = List.filled(c, false);
    }
  }

  void setCount(int c) {
    _configure(c);
    Sfx.tap();
    notifyListeners();
  }

  void setBot(int i, bool v) {
    bots[i] = v;
    Sfx.tap();
    notifyListeners();
  }

  void reseed() {
    shuffleSeed++;
    Sfx.tap();
    notifyListeners();
  }

  List<Player> buildPlayers() => [
        for (int i = 0; i < seats; i++) PlayerPresets.make(i + shuffleSeed * 7, isBot: bots[i]),
      ];
}

/// A complete visual identity for the shell. Subclasses override the
/// builders they want to restyle; everything else falls back to the
/// classic look. All game functionality stays identical.
abstract class ShellSkin {
  const ShellSkin();

  String get name;

  // ---------- signature screens (each variant defines its own) ----------
  Widget buildSplash(BuildContext context, GameTheme t, String title, String emoji);
  Widget buildHome(BuildContext context, GameTheme t, ShellHomeData data);

  // ---------- chrome ----------
  Widget buildBackground(BuildContext context, GameTheme t, Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.background, t.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }

  TextStyle buildTitleStyle(GameTheme t) => const TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      );

  TextStyle buildHeadingStyle(GameTheme t) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: t.text,
      );

  // ---------- controls ----------
  Widget buildButton(
    BuildContext context,
    GameTheme t, {
    required String label,
    String? emoji,
    required VoidCallback onTap,
    bool primary = true,
    double fontSize = 20,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        decoration: BoxDecoration(
          gradient: primary ? t.headerGradient : null,
          color: primary ? null : t.surface,
          borderRadius: t.radius,
          border: primary ? null : Border.all(color: t.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: (primary ? t.primary : t.muted).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          '${emoji ?? ''} $label'.trim(),
          style: TextStyle(
            color: primary ? (t.dark ? Colors.black : Colors.white) : t.text,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget buildActionButton(BuildContext context, GameTheme t, String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: t.radius,
              border: Border.all(color: t.primary.withValues(alpha: 0.4), width: 2),
              boxShadow: [
                BoxShadow(color: t.primary.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: t.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget buildDialog(
    BuildContext context,
    GameTheme t, {
    required String title,
    String? emoji,
    required List<Widget> children,
  }) {
    return Dialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(borderRadius: t.radius),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: t.text),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget buildSheet(BuildContext context, GameTheme t, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: child,
    );
  }

  // ---------- in-game chrome ----------
  Widget buildScoreChips(BuildContext context, GameTheme t, List<Player> players, int activeIndex) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (int i = 0; i < players.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: i == activeIndex ? players[i].color.withValues(alpha: 0.25) : t.surface,
              borderRadius: t.radius,
              border: Border.all(
                color: i == activeIndex ? players[i].color : t.muted.withValues(alpha: 0.3),
                width: i == activeIndex ? 2.5 : 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(players[i].emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '${players[i].name} • ${players[i].score}',
                  style: TextStyle(
                    color: t.text,
                    fontWeight: i == activeIndex ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget buildTurnBanner(BuildContext context, GameTheme t, Player player, String action) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [player.color.withValues(alpha: 0.85), player.color.withValues(alpha: 0.55)]),
        borderRadius: t.radius,
      ),
      child: Text(
        '${player.emoji} ${player.name}$action',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
      ),
    );
  }

  // ---------- flows (built from the skin's own dialog/button so variants inherit styling) ----------
  Widget buildSetup(
    BuildContext context,
    GameTheme t,
    PlayerSetupModel model,
    void Function(List<Player>) onStart,
    VoidCallback onBack,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Who's playing?",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: t.text)),
            const SizedBox(height: 6),
            Text('Pass-and-play on this device. No internet needed! 📱',
                style: TextStyle(color: t.muted)),
            const SizedBox(height: 20),
            Text('PLAYERS',
                style: TextStyle(color: t.muted, fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                for (final o in model.options)
                  GestureDetector(
                    onTap: () => model.setCount(o),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: o == model.count ? t.headerGradient : null,
                        color: o == model.count ? null : t.surface,
                        borderRadius: t.radius,
                        border: Border.all(
                            color: o == model.count
                                ? Colors.transparent
                                : t.muted.withValues(alpha: 0.4),
                            width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text('$o',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: o == model.count
                                  ? (t.dark ? Colors.black : Colors.white)
                                  : t.text)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('SQUAD',
                    style: TextStyle(color: t.muted, fontWeight: FontWeight.w800, fontSize: 12)),
                const Spacer(),
                GestureDetector(
                  onTap: model.reseed,
                  child: Text('🔀 shuffle',
                      style: TextStyle(color: t.primary, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: model.seats,
                itemBuilder: (_, i) {
                  final p = PlayerPresets.make(i + model.shuffleSeed * 7, isBot: model.bots[i]);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: t.radius,
                        border: Border.all(color: p.color.withValues(alpha: 0.5), width: 2)),
                    child: Row(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: TextStyle(
                                      color: t.text, fontWeight: FontWeight.w800, fontSize: 16)),
                              Text(model.bots[i] ? '🤖 Bot opponent' : '🙂 Human (this device)',
                                  style: TextStyle(color: t.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (model.supportsBots && i > 0)
                          Switch(
                            value: model.bots[i],
                            activeThumbColor: t.primary,
                            onChanged: (v) => model.setBot(i, v),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Center(
                child: buildButton(context, t,
                    label: 'Start game',
                    emoji: '🚀',
                    onTap: () {
                      Sfx.click();
                      onStart(model.buildPlayers());
                    })),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget buildPauseDialog(
    BuildContext context,
    GameTheme t, {
    required VoidCallback onResume,
    required VoidCallback onRestart,
    required VoidCallback onHowTo,
    required VoidCallback onQuit,
  }) {
    return buildDialog(
      context,
      t,
      emoji: '⏸️',
      title: 'Paused',
      children: [
        buildButton(context, t, label: 'Resume', emoji: '▶️', onTap: onResume),
        const SizedBox(height: 10),
        buildButton(context, t, label: 'Restart', emoji: '🔁', primary: false, onTap: onRestart),
        const SizedBox(height: 10),
        buildButton(context, t, label: 'How to play', emoji: '❓', primary: false, onTap: onHowTo),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onQuit,
          child: Text('Quit to menu',
              style: TextStyle(color: t.muted, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget buildGameOverDialog(
    BuildContext context,
    GameTheme t, {
    Player? winner,
    String? headline,
    String? subline,
    required List<Player> players,
    required VoidCallback onRematch,
    required VoidCallback onShare,
    required VoidCallback onMenu,
  }) {
    return buildDialog(
      context,
      t,
      emoji: winner != null ? winner.emoji : '🎉',
      title: headline ?? (winner != null ? '${winner.name} wins!' : 'Game over!'),
      children: [
        if (subline != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(subline,
                textAlign: TextAlign.center, style: TextStyle(color: t.muted)),
          ),
        if (winner == null && players.length > 1) _finalScores(t, players),
        const SizedBox(height: 8),
        buildButton(context, t, label: 'Rematch', emoji: '🔁', onTap: onRematch),
        const SizedBox(height: 10),
        buildButton(context, t, label: 'Share', emoji: '📣', primary: false, onTap: onShare),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onMenu,
          child: Text('Back to menu',
              style: TextStyle(color: t.muted, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _finalScores(GameTheme t, List<Player> players) {
    final ranked = [...players]..sort((a, b) => b.score.compareTo(a.score));
    return Column(
      children: [
        for (final p in ranked)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(p.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(p.name,
                    style: TextStyle(color: t.text, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text('${p.score} pts',
                    style: TextStyle(color: t.muted, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Shared home footer.
  Widget buildFooter(GameTheme t) {
    return Text('Made with 💛 by Wajiha • 100% free forever',
        style: TextStyle(color: t.muted.withValues(alpha: 0.7), fontSize: 12));
  }

  /// Shared promo banner slot for home screens.
  Widget buildPromo(String slug) => PromoBanner(currentSlug: slug);
}

// ===========================================================================
// Shared painters & animated helpers
// ===========================================================================

/// Faint grid lines (arcade / blueprint feel).
class _GridPainter extends CustomPainter {
  final Color color;
    const _GridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.color != color;
}

/// Halftone comic dots.
class _HalftonePainter extends CustomPainter {
  final Color color;
  const _HalftonePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (double y = 11; y < size.height; y += 22) {
      for (double x = 11; x < size.width; x += 22) {
        canvas.drawCircle(Offset(x, y), 3.2, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HalftonePainter old) => old.color != color;
}

/// CRT scanlines.
class _ScanlinePainter extends CustomPainter {
  final Color color;
  const _ScanlinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 2;
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter old) => old.color != color;
}

/// Scattered confetti dots.
class _ConfettiPainter extends CustomPainter {
  final List<Color> colors;
  const _ConfettiPainter({required this.colors});
  @override
  void paint(Canvas canvas, Size size) {
    var s = 7;
    double rnd() {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      return s / 0x7fffffff;
    }

    for (int i = 0; i < 46; i++) {
      final p = Paint()..color = colors[i % colors.length].withValues(alpha: 0.5);
      canvas.drawCircle(
          Offset(rnd() * size.width, rnd() * size.height), 2.5 + rnd() * 4, p);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => false;
}

/// Faint ruled notebook lines.
class _RuledLinesPainter extends CustomPainter {
  final Color color;
  const _RuledLinesPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 1;
    for (double y = 28; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _RuledLinesPainter old) => old.color != color;
}

/// Subtle vertical pinstripes.
class _PinstripePainter extends CustomPainter {
  final Color color;
  const _PinstripePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 3;
    for (double x = 12; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant _PinstripePainter old) => old.color != color;
}

/// Graffiti wall blocks.
class _WallPainter extends CustomPainter {
  final Color block;
  final Color line;
  const _WallPainter({required this.block, required this.line});
  @override
  void paint(Canvas canvas, Size size) {
    final b = Paint()..color = block;
    final l = Paint()
      ..color = line
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const bh = 64.0;
    for (double y = 0; y < size.height; y += bh) {
      final off = ((y / bh).round() % 2) * 60.0;
      for (double x = -60; x < size.width + 60; x += 120) {
        canvas.drawRect(Rect.fromLTWH(x + off, y, 120, bh), b);
        canvas.drawRect(Rect.fromLTWH(x + off, y, 120, bh), l);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WallPainter old) => old.block != block;
}

/// Candy sprinkles.
class _SprinklePainter extends CustomPainter {
  final List<Color> colors;
  const _SprinklePainter({required this.colors});
  @override
  void paint(Canvas canvas, Size size) {
    var s = 1234567;
    double rnd() {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      return s / 0x7fffffff;
    }

    for (int i = 0; i < 60; i++) {
      final p = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.65)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final c = Offset(rnd() * size.width, rnd() * size.height);
      final a = rnd() * 3.14;
      canvas.drawLine(
          c - Offset.fromDirection(a, 7), c + Offset.fromDirection(a, 7), p);
    }
  }

  @override
  bool shouldRepaint(covariant _SprinklePainter old) => false;
}

/// Comic starburst badge.
class _StarburstPainter extends CustomPainter {
  final Color color;
  const _StarburstPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final path = Path();
    for (int i = 0; i < 32; i++) {
      final rr = i.isEven ? r : r * 0.78;
      final a = (i / 32) * 6.2832 - 1.5708;
      final pt = c + Offset.fromDirection(a, rr);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StarburstPainter old) => old.color != color;
}

/// Soft radial glow.
class _GlowPainter extends CustomPainter {
  final Color color;
  const _GlowPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(
        c,
        size.shortestSide / 2,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: c, radius: size.shortestSide / 2)));
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) => old.color != color;
}

/// Blinking widget (INSERT COIN energy).
class _Blink extends StatefulWidget {
  final Widget child;
  final Duration period;
  const _Blink({required this.child, this.period = const Duration(milliseconds: 900)});
  @override
  State<_Blink> createState() => _BlinkState();
}

class _BlinkState extends State<_Blink> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: Tween(begin: 1.0, end: 0.25).animate(_c), child: widget.child);
}

/// Slowly rising bubbles (underwater vibe).
class _RisingBubbles extends StatefulWidget {
  final Color color;
  const _RisingBubbles({required this.color});
  @override
  State<_RisingBubbles> createState() => _RisingBubblesState();
}

class _RisingBubblesState extends State<_RisingBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 7))
        ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        painter: _BubbleFieldPainter(progress: _c.value, color: widget.color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BubbleFieldPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _BubbleFieldPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    var s = 4242;
    double rnd() {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      return s / 0x7fffffff;
    }

    for (int i = 0; i < 26; i++) {
      final x = rnd() * size.width;
      final r = 3 + rnd() * 9;
      final speed = 0.25 + rnd() * 0.5;
      final y = size.height - ((progress * speed + rnd()) % 1.0) * (size.height + 40) + 20;
      canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..color = color.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleFieldPainter old) =>
      old.progress != progress || old.color != color;
}

/// Expanding ripple rings (splash flourish).
class _RippleRings extends StatelessWidget {
  final Color color;
  const _RippleRings({required this.color});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1400),
      builder: (_, v, __) => CustomPaint(
        painter: _RingsPainter(progress: v, color: color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingsPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (int i = 0; i < 3; i++) {
      final p = (progress + i / 3) % 1.0;
      canvas.drawCircle(
          c,
          p * size.shortestSide * 0.7,
          Paint()
            ..color = color.withValues(alpha: (1 - p) * 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.progress != progress;
}

/// Gentle floating motion for decorative blobs.
class _Floaty extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration duration;
  const _Floaty(
      {required this.child,
      this.amplitude = 12,
      this.duration = const Duration(seconds: 4)});
  @override
  State<_Floaty> createState() => _FloatyState();
}

class _FloatyState extends State<_Floaty> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)
        ..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, (_c.value - 0.5) * 2 * widget.amplitude),
          child: widget.child,
        ),
      );
}

// ===========================================================================
// 1. NEON ARCADE — dark room, glowing marquee, neon-tube buttons
// ===========================================================================
class NeonArcadeSkin extends ShellSkin {
  const NeonArcadeSkin();
  @override
  String get name => 'Neon Arcade';

  @override
  TextStyle buildTitleStyle(GameTheme t) => TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        letterSpacing: 4,
        color: Colors.white,
        shadows: [
          Shadow(color: t.primary, blurRadius: 18),
          Shadow(color: t.primary.withValues(alpha: 0.8), blurRadius: 42),
        ],
      );

  @override
  Widget buildBackground(BuildContext context, GameTheme t, Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF080812), Color(0xFF141428)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
                painter: _GridPainter(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child,
        ],
      ),
    );
  }

  @override
  Widget buildSplash(BuildContext context, GameTheme t, String title, String emoji) {
    return Stack(
      children: [
        Positioned.fill(
            child:
                CustomPaint(painter: _GridPainter(color: t.primary.withValues(alpha: 0.12)))),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (_, v, __) => Transform.scale(
                  scale: v,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: t.primary.withValues(alpha: 0.7), blurRadius: 44),
                      ],
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 84)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(title.toUpperCase(),
                  textAlign: TextAlign.center, style: buildTitleStyle(t)),
              const SizedBox(height: 14),
              _Blink(
                child: Text('▶ INSERT COIN ◀',
                    style: TextStyle(
                        color: t.accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        shadows: [Shadow(color: t.accent, blurRadius: 12)])),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget buildHome(BuildContext context, GameTheme t, ShellHomeData data) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 28),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.primary, width: 2),
                boxShadow: [
                  BoxShadow(color: t.primary.withValues(alpha: 0.45), blurRadius: 24),
                ],
              ),
              child: Column(
                children: [
                  Text(data.emoji, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 8),
                  Text(data.title.toUpperCase(),
                      textAlign: TextAlign.center, style: buildTitleStyle(t)),
                  const SizedBox(height: 8),
                  Text(data.tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            buildButton(context, t,
                label: 'START GAME', emoji: '🕹️', onTap: data.onPlay, fontSize: 22),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _neonTile(t, data.emoji, 'HOW', data.onHowTo, '❓'),
                  _neonTile(t, data.emoji, 'STYLE', data.onThemes, '🎨'),
                  _neonTile(t, data.emoji, 'TIP', data.onTipJar, '☕'),
                  _neonTile(t, data.emoji, 'GAMES', data.onMoreGames, '🎮'),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: buildPromo(data.slug),
            ),
            const SizedBox(height: 18),
            buildFooter(t),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _neonTile(GameTheme t, String _, String label, VoidCallback onTap, String icon) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.primary.withValues(alpha: 0.8), width: 1.5),
          boxShadow: [
            BoxShadow(color: t.primary.withValues(alpha: 0.35), blurRadius: 14),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: t.primary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildButton(BuildContext context, GameTheme t,
      {required String label,
      String? emoji,
      required VoidCallback onTap,
      bool primary = true,
      double fontSize = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: primary ? 18 : 14),
        decoration: BoxDecoration(
          color: primary ? t.primary.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary ? t.primary : t.muted, width: 2),
          boxShadow: primary
              ? [
                  BoxShadow(color: t.primary.withValues(alpha: 0.55), blurRadius: 22),
                  BoxShadow(
                      color: t.primary.withValues(alpha: 0.25), blurRadius: 44),
                ]
              : null,
        ),
        child: Text(
          '${emoji ?? ''} $label'.trim().toUpperCase(),
          style: TextStyle(
            color: primary ? t.primary : t.muted,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            shadows: primary ? [Shadow(color: t.primary, blurRadius: 10)] : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildDialog(BuildContext context, GameTheme t,
      {required String title, String? emoji, required List<Widget> children}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - v)),
          child: Dialog(
            backgroundColor: const Color(0xFF12121E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: t.primary, width: 2),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: t.primary.withValues(alpha: 0.35), blurRadius: 30),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji != null) Text(emoji, style: const TextStyle(fontSize: 44)),
                  const SizedBox(height: 8),
                  Text(title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                          shadows: [Shadow(color: t.primary, blurRadius: 12)])),
                  const SizedBox(height: 12),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildSheet(BuildContext context, GameTheme t, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: t.primary, width: 3)),
        boxShadow: [
          BoxShadow(color: t.primary.withValues(alpha: 0.4), blurRadius: 30),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: child,
    );
  }

  @override
  Widget buildSetup(BuildContext context, GameTheme t, PlayerSetupModel model,
      void Function(List<Player>) onStart, VoidCallback onBack) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack,
              child: Text('‹ BACK',
                  style: TextStyle(
                      color: t.primary, fontWeight: FontWeight.w800, letterSpacing: 2)),
            ),
            const SizedBox(height: 14),
            Text('SELECT PLAYERS',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Colors.white,
                    shadows: [Shadow(color: t.primary, blurRadius: 14)])),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              children: [
                for (final o in model.options)
                  GestureDetector(
                    onTap: () => model.setCount(o),
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: o == model.count
                            ? t.primary.withValues(alpha: 0.25)
                            : Colors.transparent,
                        border: Border.all(
                            color: o == model.count ? t.primary : t.muted, width: 2),
                        boxShadow: o == model.count
                            ? [
                                BoxShadow(
                                    color: t.primary.withValues(alpha: 0.6),
                                    blurRadius: 16)
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text('$o',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: o == model.count ? t.primary : t.muted)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: model.seats,
                itemBuilder: (_, i) {
                  final p =
                      PlayerPresets.make(i + model.shuffleSeed * 7, isBot: model.bots[i]);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.color.withValues(alpha: 0.7), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(p.name.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                        ),
                        if (model.supportsBots && i > 0)
                          Switch(
                              value: model.bots[i],
                              activeThumbColor: t.primary,
                              onChanged: (v) => model.setBot(i, v)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Center(
                child: buildButton(context, t,
                    label: 'Insert coin — start',
                    emoji: '🕹️',
                    onTap: () {
                      Sfx.click();
                      onStart(model.buildPlayers());
                    })),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 2. COZY PAPER — warm craft paper, hard cut-paper shadows, serif warmth
// ===========================================================================
class CozyPaperSkin extends ShellSkin {
  const CozyPaperSkin();
  @override
  String get name => 'Cozy Paper';

  @override
  TextStyle buildTitleStyle(GameTheme t) => TextStyle(
        fontFamily: 'serif',
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: t.text,
        letterSpacing: 0.5,
      );

  @override
  Widget buildBackground(BuildContext context, GameTheme t, Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF6EEDC),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
                painter: _RuledLinesPainter(
                    color: const Color(0xFF8A6D3B).withValues(alpha: 0.10))),
          ),
          child,
        ],
      ),
    );
  }

  BoxDecoration _paperCard(GameTheme t) => BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3D3AE), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD9C49A), blurRadius: 0, offset: Offset(5, 5)),
        ],
      );

  @override
  Widget buildSplash(BuildContext context, GameTheme t, String title, String emoji) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOut,
        builder: (_, v, __) => Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 26 * (1 - v)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: _paperCard(t),
                  child: Text(emoji, style: const TextStyle(fontSize: 76)),
                ),
                const SizedBox(height: 20),
                Text(title,
                    textAlign: TextAlign.center, style: buildTitleStyle(t)),
                const SizedBox(height: 8),
                const Text('a cozy little game 📜',
                    style: TextStyle(
                        color: Color(0xFF8A6D3B), fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildHome(BuildContext context, GameTheme t, ShellHomeData data) {
    const ink = Color(0xFF5C4520);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
              decoration: _paperCard(t),
              child: Column(
                children: [
                  Text(data.emoji, style: const TextStyle(fontSize: 66)),
                  const SizedBox(height: 10),
                  Text(data.title,
                      textAlign: TextAlign.center, style: buildTitleStyle(t)),
                  const SizedBox(height: 8),
                  Text(data.tagline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: ink, fontStyle: FontStyle.italic, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 26),
            buildButton(context, t,
                label: 'Play', emoji: '▶️', onTap: data.onPlay, fontSize: 22),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _paperAction('❓', 'How to', data.onHowTo),
                _paperAction('🎨', 'Themes', data.onThemes),
                _paperAction('☕', 'Tip jar', data.onTipJar),
                _paperAction('🎮', 'More', data.onMoreGames),
              ],
            ),
            const SizedBox(height: 24),
            buildPromo(data.slug),
            const SizedBox(height: 16),
            const Text('Made with 💛 by Wajiha • 100% free forever',
                style: TextStyle(color: ink, fontSize: 12)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _paperAction(String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE3D3AE), width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Color(0xFFD9C49A), blurRadius: 0, offset: Offset(3, 3)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF5C4520),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget buildButton(BuildContext context, GameTheme t,
      {required String label,
      String? emoji,
      required VoidCallback onTap,
      bool primary = true,
      double fontSize = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 16),
        decoration: BoxDecoration(
          color: primary ? const Color(0xFFB07D3C) : const Color(0xFFFFFBF0),
          borderRadius: BorderRadius.circular(12),
          border: primary
              ? null
              : Border.all(color: const Color(0xFFB07D3C), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0xFF8A5A22), blurRadius: 0, offset: Offset(0, 5)),
          ],
        ),
        child: Text(
          '${emoji ?? ''} $label'.trim(),
          style: TextStyle(
            color: primary ? Colors.white : const Color(0xFF5C4520),
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            fontFamily: 'serif',
          ),
        ),
      ),
    );
  }

  @override
  Widget buildDialog(BuildContext context, GameTheme t,
      {required String title, String? emoji, required List<Widget> children}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (_, v, __) => Transform.scale(
        scale: v,
        child: Dialog(
          backgroundColor: const Color(0xFFFFFBF0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE3D3AE), width: 1.5),
          ),
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                    color: Color(0xFFD9C49A), blurRadius: 0, offset: Offset(6, 6)),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null)
                  Text(emoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4A3620))),
                const SizedBox(height: 12),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildSheet(BuildContext context, GameTheme t, Widget child) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBF0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFFE3D3AE), width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: child,
    );
  }

  @override
  Widget buildSetup(BuildContext context, GameTheme t, PlayerSetupModel model,
      void Function(List<Player>) onStart, VoidCallback onBack) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack,
              child: const Text('‹ back',
                  style: TextStyle(
                      color: Color(0xFFB07D3C),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 12),
            const Text("Who's playing?",
                style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A3620))),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              children: [
                for (final o in model.options)
                  GestureDetector(
                    onTap: () => model.setCount(o),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: o == model.count
                            ? const Color(0xFFB07D3C)
                            : const Color(0xFFFFFBF0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE3D3AE), width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0xFFD9C49A),
                              blurRadius: 0,
                              offset: Offset(3, 3)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text('$o',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'serif',
                              color: o == model.count
                                  ? Colors.white
                                  : const Color(0xFF5C4520))),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: model.seats,
                itemBuilder: (_, i) {
                  final p =
                      PlayerPresets.make(i + model.shuffleSeed * 7, isBot: model.bots[i]);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: _paperCard(t),
                    child: Row(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(p.name,
                              style: const TextStyle(
                                  fontFamily: 'serif',
                                  color: Color(0xFF4A3620),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                        ),
                        if (model.supportsBots && i > 0)
                          Switch(
                              value: model.bots[i],
                              activeThumbColor: const Color(0xFFB07D3C),
                              onChanged: (v) => model.setBot(i, v)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Center(
                child: buildButton(context, t,
                    label: 'Start game',
                    emoji: '🚀',
                    onTap: () {
                      Sfx.click();
                      onStart(model.buildPlayers());
                    })),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 3. ZEN STONE — whisper-quiet minimalism, hairlines, breathing room
// ===========================================================================
class ZenStoneSkin extends ShellSkin {
  const ZenStoneSkin();
  @override
  String get name => 'Zen Stone';

  @override
  TextStyle buildTitleStyle(GameTheme t) => TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w300,
        letterSpacing: 7,
        color: t.text,
      );

  @override
  Widget buildBackground(BuildContext context, GameTheme t, Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: t.background,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: t.primary.withValues(alpha: 0.10), width: 1.5),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: t.primary.withValues(alpha: 0.08), width: 1),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  @override
  Widget buildSplash(BuildContext context, GameTheme t, String title, String emoji) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1600),
        curve: Curves.easeInOut,
        builder: (_, v, __) => Opacity(
          opacity: v,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 26),
              Text(title.toUpperCase(),
                  textAlign: TextAlign.center, style: buildTitleStyle(t)),
              const SizedBox(height: 20),
              Container(width: 64, height: 1, color: t.primary.withValues(alpha: 0.6)),
              const SizedBox(height: 20),
              Text('breathe in • play',
                  style: TextStyle(
                      color: t.muted, letterSpacing: 3, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget buildHome(BuildContext context, GameTheme t, ShellHomeData data) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          children: [
            const SizedBox(height: 72),
            Text(data.emoji, style: const TextStyle(fontSize: 54)),
            const SizedBox(height: 26),
            Text(data.title.toUpperCase(),
                textAlign: TextAlign.center, style: buildTitleStyle(t)),
            const SizedBox(height: 18),
            Container(width: 48, height: 1, color: t.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 18),
            Text(data.tagline,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.muted, height: 1.8, fontSize: 14)),
            const SizedBox(height: 44),
            buildButton(context, t, label: 'begin', onTap: data.onPlay),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _zenLink(t, 'guide', data.onHowTo),
                _zenDot(t),
                _zenLink(t, 'themes', data.onThemes),
                _zenDot(t),
                _zenLink(t, 'tip jar', data.onTipJar),
                _zenDot(t),
                _zenLink(t, 'more', data.onMoreGames),
              ],
            ),
            const SizedBox(height: 44),
            buildPromo(data.slug),
            const SizedBox(height: 30),
            buildFooter(t),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _zenLink(GameTheme t, String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(label,
              style: TextStyle(
                  color: t.muted,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600)),
        ),
      );

  Widget _zenDot(GameTheme t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
            width: 3,
            height: 3,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: t.muted)),
      );

  @override
  Widget buildButton(BuildContext context, GameTheme t,
      {required String label,
      String? emoji,
      required VoidCallback onTap,
      bool primary = true,
      double fontSize = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: primary
                  ? t.primary.withValues(alpha: 0.8)
                  : t.muted.withValues(alpha: 0.5),
              width: 1.2),
        ),
        child: Text(
          (emoji != null ? '$emoji ' : '') + label.toUpperCase(),
          style: TextStyle(
            color: primary ? t.primary : t.muted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildDialog(BuildContext context, GameTheme t,
      {required String title, String? emoji, required List<Widget> children}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Dialog(
          backgroundColor: t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: t.muted.withValues(alpha: 0.35), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null)
                  Text(emoji, style: const TextStyle(fontSize: 36)),
                if (emoji != null) const SizedBox(height: 14),
                Text(title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 4,
                        color: t.text)),
                Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    width: 40,
                    height: 1,
                    color: t.primary.withValues(alpha: 0.6)),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildSheet(BuildContext context, GameTheme t, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(top: BorderSide(color: t.muted.withValues(alpha: 0.3))),
      ),
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
      child: child,
    );
  }

  @override
  Widget buildActionButton(BuildContext context, GameTheme t, String emoji,
      String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(label,
            style: TextStyle(
                color: t.muted,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget buildSetup(BuildContext context, GameTheme t, PlayerSetupModel model,
      void Function(List<Player>) onStart, VoidCallback onBack) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack,
              child: Text('‹ back',
                  style: TextStyle(color: t.muted, letterSpacing: 2, fontSize: 13)),
            ),
            const SizedBox(height: 30),
            Text('WHO IS PLAYING',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 5,
                    color: t.text)),
            const SizedBox(height: 26),
            Row(
              children: [
                for (final o in model.options)
                  Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: GestureDetector(
                      onTap: () => model.setCount(o),
                      child: Text('$o',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: o == model.count
                                  ? FontWeight.w700
                                  : FontWeight.w300,
                              color: o == model.count ? t.primary : t.muted)),
                    ),
                  ),
              ],
            ),
            Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                height: 1,
                color: t.muted.withValues(alpha: 0.25)),
            Expanded(
              child: ListView.builder(
                itemCount: model.seats,
                itemBuilder: (_, i) {
                  final p =
                      PlayerPresets.make(i + model.shuffleSeed * 7, isBot: model.bots[i]);
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: t.muted.withValues(alpha: 0.2)))),
                    child: Row(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(p.name,
                              style: TextStyle(
                                  color: t.text,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 1)),
                        ),
                        if (model.supportsBots && i > 0)
                          Switch(
                              value: model.bots[i],
                              activeThumbColor: t.primary,
                              onChanged: (v) => model.setBot(i, v)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Center(
                child: buildButton(context, t,
                    label: 'begin',
                    onTap: () {
                      Sfx.click();
                      onStart(model.buildPlayers());
                    })),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildScoreChips(
      BuildContext context, GameTheme t, List<Player> players, int activeIndex) {
    return Wrap(
      spacing: 18,
      alignment: WrapAlignment.center,
      children: [
        for (int i = 0; i < players.length; i++)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(players[i].emoji, style: const TextStyle(fontSize: 20)),
              Text('${players[i].score}',
                  style: TextStyle(
                      color: i == activeIndex ? t.primary : t.muted,
                      fontWeight: FontWeight.w700)),
              Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 28,
                  height: 2,
                  color: i == activeIndex
                      ? t.primary
                      : t.muted.withValues(alpha: 0.3)),
            ],
          ),
      ],
    );
  }
}

// ===========================================================================
// 4. COMIC BURST — halftone, thick ink, POW! energy
// ===========================================================================
class ComicBurstSkin extends ShellSkin {
  const ComicBurstSkin();
  @override
  String get name => 'Comic Burst';

  @override
  TextStyle buildTitleStyle(GameTheme t) => TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: Colors.white,
        letterSpacing: 1,
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
          Shadow(color: Colors.black, offset: Offset(-1, -1), blurRadius: 0),
        ],
      );

  @override
  Widget buildBackground(BuildContext context, GameTheme t, Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.primary, t.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
                painter:
                    _HalftonePainter(color: Colors.black.withValues(alpha: 0.10))),
          ),
          child,
        ],
      ),
    );
  }

  @override
  Widget buildSplash(BuildContext context, GameTheme t, String title, String emoji) {
    return Stack(
      children: [
        Positioned.fill(
            child: CustomPaint(
                painter: _HalftonePainter(
                    color: Colors.white.withValues(alpha: 0.16)))),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, __) => Transform.scale(
              scale: v,
              child: Transform.rotate(
                angle: -0.06 * v,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 190,
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                              size: const Size(190, 190),
                              painter: const _StarburstPainter(
                                  color: Color(0xFFFFD23F))),
                          Text(emoji, style: const TextStyle(fontSize: 80)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(title.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildHome(BuildContext context, GameTheme t, ShellHomeData data) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 34),
            Transform.rotate(
              angle: -0.04,
              child: SizedBox(
                width: 300,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                        size: const Size(300, 240),
                        painter: const _StarburstPainter(color: Color(0xFFFFD23F))),
                    Padding(
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(data.emoji, style: const TextStyle(fontSize: 52)),
                          Text(data.title.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 3),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
                  ],
                ),
                child: Text(data.tagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        height: 1.4)),
              ),
            ),
            const SizedBox(height: 26),
            buildButton(context, t,
                label: 'PLAY!', emoji: '💥', onTap: data.onPlay, fontSize: 24),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _comicPanel('❓', 'HOW', data.onHowTo),
                const SizedBox(width: 12),
                _comicPanel('🎨', 'LOOK', data.onThemes),
                const SizedBox(width: 12),
                _comicPanel('☕', 'TIP', data.onTipJar),
                const SizedBox(width: 12),
                _comicPanel('🎮', 'MORE', data.onMoreGames),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: buildPromo(data.slug),
            ),
            const SizedBox(height: 16),
            const Text('Made with 💛 by Wajiha • 100% free forever',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    shadows: [
                      Shadow(
                          color: Colors.black,
                          offset: Offset(1, 1),
                          blurRadius: 0),
                    ])),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _comicPanel(String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.black)),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildButton(BuildContext context, GameTheme t,
      {required String label,
      String? emoji,
      required VoidCallback onTap,
      bool primary = true,
      double fontSize = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        decoration: BoxDecoration(
          color: primary ? const Color(0xFFFFD23F) : Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(5, 5), blurRadius: 0),
          ],
        ),
        child: Text(
          '${emoji ?? ''} $label'.trim().toUpperCase(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildDialog(BuildContext context, GameTheme t,
      {required String title, String? emoji, required List<Widget> children}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.elasticOut,
      builder: (_, v, __) => Transform.scale(
        scale: 0.6 + 0.4 * v,
        child: Transform.rotate(
          angle: 0.05 * (1 - v),
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.black, width: 4),
            ),
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black, offset: Offset(7, 7), blurRadius: 0),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji != null)
                    Text(emoji, style: const TextStyle(fontSize: 46)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5D5D),
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 14),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildSheet(BuildContext context, GameTheme t, Widget child) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(top: BorderSide(color: Colors.black, width: 4)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: child,
    );
  }

  @override
  Widget buildSetup(BuildContext context, GameTheme t, PlayerSetupModel model,
      void Function(List<Player>) onStart, VoidCallback onBack) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('‹ BACK',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic)),
              ),
            ),
            const SizedBox(height: 16),
            Transform.rotate(
              angle: -0.03,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD23F),
                  border: Border.all(color: Colors.black, width: 3),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
                  ],
                ),
                child: const Text("WHO'S PLAYING?!",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.black)),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              children: [
                for (final o in model.options)
                  GestureDetector(
                    onTap: () => model.setCount(o),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: o == model.count
                            ? const Color(0xFFFF5D5D)
                            : Colors.white,
                        border: Border.all(color: Colors.black, width: 3),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black,
                              offset: Offset(3, 3),
                              blurRadius: 0),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text('$o',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: o == model.count
                                  ? Colors.white
                                  : Colors.black)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.builder(
                itemCount: model.seats,
                itemBuilder: (_, i) {
                  final p =
                      PlayerPresets.make(i + model.shuffleSeed * 7, isBot: model.bots[i]);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 3),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black,
                            offset: Offset(4, 4),
                            blurRadius: 0),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(p.name.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic)),
                        ),
                        if (model.supportsBots && i > 0)
                          Switch(
                              value: model.bots[i],
                              activeThumbColor: const Color(0xFFFF5D5D),
                              onChanged: (v) => model.setBot(i, v)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Center(
                child: buildButton(context, t,
                    label: 'GO GO GO!',
                    emoji: '💥',
                    onTap: () {
                      Sfx.click();
                      onStart(model.buildPlayers());
                    })),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 5. RETRO CABINET — CRT glow, chunky 3D buttons, marquee header
// ===========================================================================
class RetroCabinetSkin extends ShellSkin {
  const RetroCabinetSkin();
  @override
  String get name => 'Retro Cabinet';

  @override
  TextStyle buildTitleStyle(GameTheme t) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: 3,
        color: t.primary,
        shadows: [Shadow(color: t.primary, blurRadius: 16)],
      );

  @override
  Widget buildBackground(BuildContext context, GameTheme t, Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF0B0B10),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
                painter: _ScanlinePainter(
                    color: Colors.white.withValues(alpha: 0.035))),
          ),
          Positioned.fill(
            child: CustomPaint(
                painter: _GlowPainter(
                    color: t.primary.withValues(alpha: 0.10))),
          ),
          child,
        ],
      ),
    );
  }

  @override
  Widget buildSplash(BuildContext context, GameTheme t, String title, String emoji) {
    return Stack(
      children: [
        Positioned.fill(
            child: CustomPaint(
                painter: _ScanlinePainter(
                    color: t.primary.withValues(alpha: 0.08)))),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, 120 * (1 - v)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 80)),
                    const SizedBox(height: 16),
                    Text(title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: buildTitleStyle(t)),
                    const SizedBox(height: 18),
                    _Blink(
                      child: Text('· PRESS START ·',
                          style: TextStyle(
                              fontFamily: 'monospace',
                              color: t.accent,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(color: t.accent, blurRadius: 12)
                              ])),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildHome(BuildContext context, GameTheme t, ShellHomeData data) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // marquee
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: t.primary.withValues(alpha: 0.5), blurRadius: 20),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < 7; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: _Blink(
                            period: Duration(milliseconds: 700 + i * 120),
                            child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: t.accent,
                                    boxShadow: [
                                      BoxShadow(
                                          color: t.accent, blurRadius: 8)
                                    ])),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(data.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: buildTitleStyle(t)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // bezel screen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: const Color(0xFF3A3A4A), width: 6),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: RadialGradient(
                    colors: [
                      t.primary.withValues(alpha: 0.16),
                      Colors.black,
                    ],
                    radius: 1.1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(data.emoji, style: const TextStyle(fontSize: 60)),
                    const SizedBox(height: 10),
                    Text(data.tagline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.6)),
                    const SizedBox(height: 20),
                    buildButton(context, t,
                        label: 'START', emoji: '▶', onTap: data.onPlay),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _cabinetBtn(t, '❓', 'HELP', data.onHowTo),
                _cabinetBtn(t, '🎨', 'STYLE', data.onThemes),
                _cabinetBtn(t, '☕', 'TIP', data.onTipJar),
                _cabinetBtn(t, '🎮', 'GAMES', data.onMoreGames),
              ],
            ),
            const SizedBox(height: 20),
            buildPromo(data.slug),
            const SizedBox(height: 14),
            Text('© WAJIHA • FREE PLAY',
                style: TextStyle(
                    fontFamily: 'monospace',
                    color: t.muted,
                    fontSize: 11,
                    letterSpacing: 2)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _cabinetBtn(
      GameTheme t, String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C26),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.primary.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                    color: t.primary.withValues(alpha: 0.25), blurRadius: 10),
              ],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontFamily: 'monospace',
                  color: t.muted,
                  fontSize: 9,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  @override
  Widget buildButton(BuildContext context, GameTheme t,
      {required String label,
      String? emoji,
      required VoidCallback onTap,
      bool primary = true,
      double fontSize = 20}) {
    final base = primary ? t.primary : const Color(0xFF2A2A38);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 14),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(8),
          border: Border(
              bottom: BorderSide(
                  color: primary
                      ? t.secondary.withValues(alpha: 0.9)
                      : Colors.black,
                  width: 5)),
          boxShadow: [
            BoxShadow(
                color: (primary ? t.primary : Colors.black)
                    .withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Text(
          '${emoji ?? ''} $label'.trim().toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            color: primary
                ? (t.dark ? Colors.black : Colors.white)
                : Colors.white70,
            fontSize: fontSize - 2,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildDialog(BuildContext context, GameTheme t,
      {required String title, String? emoji, required List<Widget> children}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 60 * (1 - v)),
          child: Dialog(
            backgroundColor: const Color(0xFF101018),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: t.primary, width: 2),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF3A3A4A), width: 4),
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (emoji != null)
                      Text(emoji, style: const TextStyle(fontSize: 42)),
                    const SizedBox(height: 8),
                    Text(title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: t.primary,
                            shadows: [
                              Shadow(color: t.primary, blurRadius: 10)
                            ])),
                    const SizedBox(height: 12),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildSheet(BuildContext context, GameTheme t, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101018),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: t.primary.withValues(alpha: 0.6), width: 2),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: child,
    );
  }

  @override
  Widget buildSetup(BuildContext context, GameTheme t, PlayerSetupModel model,
      void Function(List<Player>) onStart, VoidCallback onBack) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack,
              child: Text('‹ BACK',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      color: t.primary,
                      letterSpacing: 2)),
            ),
            const SizedBox(height: 16),
            Text('> SELECT_PLAYERS_',
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: t.primary,
                    shadows: [Shadow(color: t.primary, blurRadius: 10)])),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              children: [
                for (final o in model.options)
                  GestureDetector(
                    onTap: () => model.setCount(o),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: o == model.count
                            ? t.primary.withValues(alpha: 0.3)
                            : Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: o == model.count
                                ? t.primary
                                : const Color(0xFF3A3A4A),
                            width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text('$o',
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: o == model.count
                                  ? t.primary
                                  : const Color(0xFF777788))),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: model.seats,
                itemBuilder: (_, i) {
                  final p =
                      PlayerPresets.make(i + model.shuffleSeed * 7, isBot: model.bots[i]);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: p.color.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('P${i + 1}_${p.name.toUpperCase()}',
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
                        if (model.supportsBots && i > 0)
                          Switch(
                              value: model.bots[i],
                              activeThumbColor: t.primary,
                              onChanged: (v) => model.setBot(i, v)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Center(
                child: buildButton(context, t,
                    label: 'START GAME',
                    emoji: '▶',
                    onTap: () {
                      Sfx.click();
                      onStart(model.buildPlayers());
                    })),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 6. SOFT BLOB — organic pastel blobs, squishy and calm
// ===========================================================================
class SoftBlobSkin extends ShellSkin {
  const SoftBlobSkin();
  @override
  String get name => 'Soft Blob';

  static const _blob = BorderRadius.only(
    topLeft: Radius.circular(34),
    topRight: Radius.circular(14),
    bottomLeft: Radius.circular(14),
    bottomRight: Radius.circular(34),
  );
  static const _blobFlip = BorderRadius.only(
    topLeft: Radius.circular(14),
    topRight: Radius.circular(34),
    bottomLeft: Radius.circular(34),
    bottomRight: Radius.circular(14),
  );

  @override
  TextStyle buildTitleStyle(GameTheme t) => TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: t.text,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
              color: t.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      );

  @override
  Widget buildBackground(BuildContext context, GameTheme t, Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: t.background,
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -70,
            child: _Floaty(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: _blob,
                  gradient: RadialGradient(colors: [
                    t.primary.withValues(alpha: 0.30),
                    t.primary.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: _Floaty(
              duration: const Duration(seconds: 5),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: _blobFlip,
                  gradient: RadialGradient(colors: [
                    t.secondary.withValues(alpha: 0.28),
                    t.secondary.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -40,
            child: _Floaty(
              duration: const Duration(seconds: 6),
              amplitude: 18,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: _blob,
                  gradient: RadialGradient(colors: [
                    t.accent.withValues(alpha: 0.20),
                    t.accent.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  @override
  Widget buildSplash(BuildContext context, GameTheme t, String title, String emoji) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.elasticOut,
        builder: (_, v, __) => Transform.scale(
          scale: v,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  borderRadius: _blob,
                  gradient: LinearGradient(
                      colors: [t.primary, t.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  boxShadow: [
                    BoxShadow(
                        color: t.primary.withValues(alpha: 0.45),
                        blurRadius: 30,
                        offset: const Offset(0, 12)),
                  ],
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 72)),
              ),
              const SizedBox(height: 22),
              Text(title,
                  textAlign: TextAlign.center, style: buildTitleStyle(t)),
              const SizedBox(height: 8),
              Text('soft • squishy • fun',
                  style: TextStyle(color: t.muted, letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget buildHome(BuildContext context, GameTheme t, ShellHomeData data) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 44),
            _Floaty(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: _blobFlip,
                  color: t.surface.withValues(alpha: 0.85),
                  boxShadow: [
                    BoxShadow(
                        color: t.primary.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: Text(data.emoji, style: const TextStyle(fontSize: 64)),
              ),
            ),
            const SizedBox(height: 20),
            Text(data.title,
                textAlign: TextAlign.center, style: buildTitleStyle(t)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(data.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.muted, height: 1.6)),
            ),
            const SizedBox(height: 30),
            buildButton(context, t,
                label: 'Play', emoji: '▶️', onTap: data.onPlay, fontSize: 22),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildActionButton(context, t, '❓', 'How to', data.onHowTo),
                buildActionButton(context, t, '🎨', 'Themes', data.onThemes),
                buildActionButton(context, t, '☕', 'Tip jar', data.onTipJar),
                buildActionButton(context, t, '🎮', 'More', data.onMoreGames),
              ],
            ),
            const SizedBox(height: 26),
            buildPromo(data.slug),
            const SizedBox(height: 18),
            buildFooter(t),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildButton(BuildContext context, GameTheme t,
      {required String label,
      String? emoji,
      required VoidCallback onTap,
      bool primary = true,
      double fontSize = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 17),
        decoration: BoxDecoration(
          gradient: primary ? t.headerGradient : null,
          color: primary ? null : t.surface,
          borderRadius: _blob,
          border: primary
              ? null
              : Border.all(color: t.primary.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: (primary ? t.primary : t.muted).withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          '${emoji ?? ''} $label'.trim(),
          style: TextStyle(
            color: primary ? Colors.white : t.text,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildDialog(BuildContext context, GameTheme t,
      {required String title, String? emoji, required List<Widget> children}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      builder: (_, v, __) => Transform.scale(
        scale: v,
        child: Dialog(
          backgroundColor: t.surface,
          shape: RoundedRectangleBorder(borderRadius: _blob),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: _blob,
              boxShadow: [
                BoxShadow(
                    color: t.primary.withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 14)),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null)
                  Text(emoji, style: const TextStyle(fontSize: 46)),
                const SizedBox(height: 10),
                Text(title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800, color: t.text)),
                const SizedBox(height: 14),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildSheet(BuildContext context, GameTheme t, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.elliptical(220, 36)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: child,
    );
  }

  @override
  Widget buildActionButton(BuildContext context, GameTheme t, String emoji,
      String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: _blob,
              color: t.surface,
              border: Border.all(
                  color: t.primary.withValues(alpha: 0.35), width: 2),
              boxShadow: [
                BoxShadow(
                    color: t.primary.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 6)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: t.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget buildSetup(BuildContext context, GameTheme t, PlayerSetupModel model,
      void Function(List<Player>) onStart, VoidCallback onBack) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    borderRadius: _blobFlip,
                    color: t.surface,
                    border: Border.all(
                        color: t.primary.withValues(alpha: 0.4))),
                child: Text('‹ back',
                    style: TextStyle(
                        color: t.primary, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            Text("Who's playing?",
                style: TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w800, color: t.text)),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              children: [
                for (final o in model.options)
                  GestureDetector(
                    onTap: () => model.setCount(o),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius:
                            o == model.count ? _blob : BorderRadius.circular(20),
                        gradient: o == model.count ? t.headerGradient : null,
                        color: o == model.count ? null : t.surface,
                        boxShadow: o == model.count
                            ? [
                                BoxShadow(
                                    color:
                                        t.primary.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8))
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text('$o',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: o == model.count
                                  ? Colors.white
                                  : t.text)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: model.seats,
                itemBuilder: (_, i) {
                  final p =
                      PlayerPresets.make(i + model.shuffleSeed * 7, isBot: model.bots[i]);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: i.isEven ? _blob : _blobFlip,
                      color: t.surface,
                      border: Border.all(
                          color: p.color.withValues(alpha: 0.45), width: 2),
                    ),
                    child: Row(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(p.name,
                              style: TextStyle(
                                  color: t.text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                        ),
                        if (model.supportsBots && i > 0)
                          Switch(
                              value: model.bots[i],
                              activeThumbColor: t.primary,
                              onChanged: (v) => model.setBot(i, v)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Center(
                child: buildButton(context, t,
                    label: "Let's play!",
                    emoji: '💫',
                    onTap: () {
                      Sfx.click();
                      onStart(model.buildPlayers());
                    })),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 7. MIDNIGHT NEON — sleek dark, hairline neon, ripple calm
// ===========================================================================
class MidnightNeonSkin extends ShellSkin {
  const MidnightNeonSkin();
  @override
  String get name => 'Midnight Neon';

  @override
  TextStyle buildTitleStyle(GameTheme t) => TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w200,
        letterSpacing: 9,
        color: Colors.white,
        shadows: [
          Shadow(color: t.primary.withValues(alpha: 0.9), blurRadius: 22),
        ],
      );

  @override
  Widget buildBackground(BuildContext context, GameTheme t, Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF050510), Color(0xFF0D0D20)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
                painter: _GlowPainter(
                    color: t.primary.withValues(alpha: 0.08))),
          ),
          child,
        ],
      ),
    );
  }

  @override
  Widget buildSplash(BuildContext context, GameTheme t, String title, String emoji) {
    return Stack(
      children: [
        const _RippleRings(color: Color(0xFF00F5D4)),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1200),
            builder: (_, v, __) => Opacity(
              opacity: v,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 72)),
                  const SizedBox(height: 22),
                  Text(title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: buildTitleStyle(t)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildHome(BuildContext context, GameTheme t, ShellHomeData data) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          children: [
            const SizedBox(height: 64),
            Text(data.emoji, style: const TextStyle(fontSize: 58)),
            const SizedBox(height: 24),
            Text(data.title.toUpperCase(),
                textAlign: TextAlign.center, style: buildTitleStyle(t)),
            const SizedBox(height: 16),
            Container(
                width: 120,
                height: 2,
                decoration: BoxDecoration(
                    color: t.primary,
                    boxShadow: [
                      BoxShadow(color: t.primary, blurRadius: 12)
                    ])),
            const SizedBox(height: 16),
            Text(data.tagline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 14, height: 1.7)),
            const SizedBox(height: 40),
            buildButton(context, t, label: 'play', onTap: data.onPlay),
            const SizedBox(height: 36),
            Wrap(
              spacing: 26,
              alignment: WrapAlignment.center,
              children: [
                _ghostLink(t, '❓ guide', data.onHowTo),
                _ghostLink(t, '🎨 themes', data.onThemes),
                _ghostLink(t, '☕ tip jar', data.onTipJar),
                _ghostLink(t, '🎮 more', data.onMoreGames),
              ],
            ),
            const SizedBox(height: 40),
            buildPromo(data.slug),
            const SizedBox(height: 24),
            Text('WAJIHA • FREE FOREVER',
                style: TextStyle(
                    color: Colors.white38, fontSize: 10, letterSpacing: 4)),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _ghostLink(GameTheme t, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(label,
              style: TextStyle(
                  color: t.primary.withValues(alpha: 0.85),
                  fontSize: 13,
                  letterSpacing: 2)),
        ),
      );

  @override
  Widget buildButton(BuildContext context, GameTheme t,
      {required String label,
      String? emoji,
      required VoidCallback onTap,
      bool primary = true,
      double fontSize = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: (primary ? t.primary : t.muted).withValues(alpha: 0.9),
              width: 1.5),
          boxShadow: primary
              ? [
                  BoxShadow(
                      color: t.primary.withValues(alpha: 0.35),
                      blurRadius: 20),
                ]
              : null,
        ),
        child: Text(
          ((emoji != null) ? '$emoji ' : '') + label.toLowerCase(),
          style: TextStyle(
            color: primary ? t.primary : t.muted,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 5,
            shadows: primary
                ? [Shadow(color: t.primary, blurRadius: 8)]
                : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildDialog(BuildContext context, GameTheme t,
      {required String title, String? emoji, required List<Widget> children}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Transform.scale(
          scale: 0.94 + 0.06 * v,
          child: Dialog(
            backgroundColor: const Color(0xFF0D0D1A).withValues(alpha: 0.96),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                  color: t.primary.withValues(alpha: 0.7), width: 1.2),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border(
                    top: BorderSide(color: t.primary, width: 2)),
                boxShadow: [
                  BoxShadow(
                      color: t.primary.withValues(alpha: 0.25),
                      blurRadius: 28),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji != null)
                    Text(emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 10),
                  Text(title.toLowerCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 5,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: t.primary, blurRadius: 12)
                          ])),
                  const SizedBox(height: 14),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildSheet(BuildContext context, GameTheme t, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
            top: BorderSide(color: t.primary.withValues(alpha: 0.8), width: 1.5),
            left: BorderSide(
                color: t.primary.withValues(alpha: 0.25), width: 1),
            right: BorderSide(
                color: t.primary.withValues(alpha: 0.25), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 40),
      child: child,
    );
  }

  @override
  Widget buildSetup(BuildContext context, GameTheme t, PlayerSetupModel model,
      void Function(List<Player>) onStart, VoidCallback onBack) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack,
              child: Text('‹ back',
                  style: TextStyle(
                      color: t.primary.withValues(alpha: 0.8),
                      letterSpacing: 3,
                      fontSize: 13)),
            ),
            const SizedBox(height: 26),
            Text('players'.toUpperCase(),
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 7,
                    color: Colors.white,
                    shadows: [Shadow(color: t.primary, blurRadius: 14)])),
            const SizedBox(height: 22),
            Row(
              children: [
                for (final o in model.options)
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: GestureDetector(
                      onTap: () => model.setCount(o),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: o == model.count
                                  ? t.primary
                                  : Colors.white24,
                              width: 1.5),
                          boxShadow: o == model.count
                              ? [
                                  BoxShadow(
                                      color: t.primary.withValues(
                                          alpha: 0.5),
                                      blurRadius: 14)
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text('$o',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                color: o == model.count
                                    ? t.primary
                                    : Colors.white38)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: model.seats,
                itemBuilder: (_, i) {
                  final p =
                      PlayerPresets.make(i + model.shuffleSeed * 7, isBot: model.bots[i]);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: p.color.withValues(alpha: 0.6), width: 1.2),
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                    child: Row(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1)),
                              Text(
                                  model.bots[i]
                                      ? 'bot opponent'
                                      : 'human • this device',
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      letterSpacing: 1)),
                            ],
                          ),
                        ),
                        if (model.supportsBots && i > 0)
                          Switch(
                              value: model.bots[i],
                              activeThumbColor: t.primary,
                              onChanged: (v) => model.setBot(i, v)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Center(
                child: buildButton(context, t,
                    label: 'start',
                    onTap: () {
                      Sfx.click();
                      onStart(model.buildPlayers());
                    })),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 8. PLAYFUL POP — bouncy candy confetti, the cheerful default
// ===========================================================================
class PlayfulPopSkin extends ShellSkin {
  const PlayfulPopSkin();
  @override
  String get name => 'Playful Pop';

  @override
  TextStyle buildTitleStyle(GameTheme t) => const TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: Colors.white,
        letterSpacing: 0.5,
        shadows: [
          Shadow(color: Color(0xAA000000), blurRadius: 18, offset: Offset(0, 4)),
        ],
      );

  @override
  Widget buildBackground(BuildContext context, GameTheme t, Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.background, t.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
                painter: _ConfettiPainter(colors: [
              t.primary,
              t.secondary,
              t.accent,
              Colors.white,
            ])),
          ),
          child,
        ],
      ),
    );
  }

  @override
  Widget buildSplash(BuildContext context, GameTheme t, String title, String emoji) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.3, end: 1),
        duration: const Duration(milliseconds: 850),
        curve: Curves.elasticOut,
        builder: (_, v, __) => Transform.scale(
          scale: v,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [Colors.white, Colors.white.withValues(alpha: 0.7)]),
                  boxShadow: [
                    BoxShadow(
                        color: t.primary.withValues(alpha: 0.5),
                        blurRadius: 36),
                  ],
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 80)),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(title,
                    textAlign: TextAlign.center, style: buildTitleStyle(t)),
              ),
              const SizedBox(height: 10),
              const Text('a Wajiha fun game 💛',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                            color: Color(0xAA000000),
                            blurRadius: 8,
                            offset: Offset(0, 2)),
                      ])),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget buildHome(BuildContext context, GameTheme t, ShellHomeData data) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 46),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, v, __) => Transform.scale(
                scale: v,
                child: Text(data.emoji, style: const TextStyle(fontSize: 86)),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(data.title,
                  textAlign: TextAlign.center, style: buildTitleStyle(t)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Text(data.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                            color: Color(0xAA000000),
                            blurRadius: 8,
                            offset: Offset(0, 2)),
                      ])),
            ),
            const SizedBox(height: 30),
            buildButton(context, t,
                label: 'Play!', emoji: '▶️', onTap: data.onPlay, fontSize: 24),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildActionButton(context, t, '❓', 'How to', data.onHowTo),
                const SizedBox(width: 16),
                buildActionButton(context, t, '🎨', 'Themes', data.onThemes),
                const SizedBox(width: 16),
                buildActionButton(context, t, '☕', 'Tip jar', data.onTipJar),
                const SizedBox(width: 16),
                buildActionButton(context, t, '🎮', 'More', data.onMoreGames),
              ],
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: buildPromo(data.slug),
            ),
            const SizedBox(height: 20),
            buildFooter(t),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildButton(BuildContext context, GameTheme t,
      {required String label,
      String? emoji,
      required VoidCallback onTap,
      bool primary = true,
      double fontSize = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            EdgeInsets.symmetric(horizontal: 44, vertical: primary ? 18 : 14),
        decoration: BoxDecoration(
          gradient: primary ? t.headerGradient : null,
          color: primary ? null : t.surface,
          borderRadius: BorderRadius.circular(999),
          border: primary
              ? null
              : Border.all(color: t.primary, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: (primary ? t.primary : t.muted).withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          '${emoji ?? ''} $label'.trim(),
          style: TextStyle(
            color: primary ? Colors.white : t.text,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildDialog(BuildContext context, GameTheme t,
      {required String title, String? emoji, required List<Widget> children}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (_, v, __) => Transform.scale(
        scale: 0.7 + 0.3 * v,
        child: Dialog(
          backgroundColor: t.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                    color: t.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 12)),
              ],
            ),
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (_, e, ___) => Transform.scale(
                        scale: e,
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 48))),
                  ),
                const SizedBox(height: 10),
                Text(title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: t.text)),
                const SizedBox(height: 14),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildActionButton(BuildContext context, GameTheme t, String emoji,
      String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, v, __) => Transform.scale(
              scale: v,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    t.surface,
                    t.surface.withValues(alpha: 0.75)
                  ]),
                  border: Border.all(
                      color: t.primary.withValues(alpha: 0.5), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                        color: t.primary.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6)),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                        color: Color(0xAA000000),
                        blurRadius: 6,
                        offset: Offset(0, 1)),
                  ])),
        ],
      ),
    );
  }

  @override
  Widget buildScoreChips(
      BuildContext context, GameTheme t, List<Player> players, int activeIndex) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (int i = 0; i < players.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: i == activeIndex ? t.headerGradient : null,
              color: i == activeIndex ? null : t.surface,
              border: Border.all(
                  color: i == activeIndex
                      ? Colors.transparent
                      : t.primary.withValues(alpha: 0.4),
                  width: 2),
              boxShadow: i == activeIndex
                  ? [
                      BoxShadow(
                          color: t.primary.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 6))
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(players[i].emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text('${players[i].name} • ${players[i].score}',
                    style: TextStyle(
                        color: i == activeIndex ? Colors.white : t.text,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
      ],
    );
  }
}

// ===========================================================================
// 9. ELEGANT SERIF — refined, gold rules, editorial calm
// ===========================================================================
class ElegantSerifSkin extends ShellSkin {
  const ElegantSerifSkin();
  @override
  String get name => 'Elegant Serif';

  static const _gold = Color(0xFFC9A227);

  @override
  TextStyle buildTitleStyle(GameTheme t) => TextStyle(
        fontFamily: 'serif',
        fontSize: 42,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: t.text,
      );

  @override
  TextStyle buildHeadingStyle(GameTheme t) => TextStyle(
        fontFamily: 'serif',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: t.text,
      );

  @override
  Widget buildBackground(BuildContext context, GameTheme t, Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: t.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
                painter: _PinstripePainter(
                    color: _gold.withValues(alpha: 0.06))),
          ),
          child,
        ],
      ),
    );
  }

  Widget _rule(double width) => Container(
        width: width,
        height: 1,
        color: _gold.withValues(alpha: 0.7),
      );

  @override
  Widget buildSplash(BuildContext context, GameTheme t, String title, String emoji) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1300),
        curve: Curves.easeOut,
        builder: (_, v, __) => Opacity(
          opacity: v,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 60)),
              const SizedBox(height: 24),
              _rule(72 * v + 8),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Text(title,
                    textAlign: TextAlign.center, style: buildTitleStyle(t)),
              ),
              const SizedBox(height: 20),
              _rule(72 * v + 8),
              const SizedBox(height: 18),
              Text('A WAJIHA PARLOUR GAME',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 5,
                      color: t.muted,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget buildHome(BuildContext context, GameTheme t, ShellHomeData data) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text('~ ${data.emoji} ~',
                style: TextStyle(fontSize: 30, color: t.muted)),
            const SizedBox(height: 20),
            _rule(90),
            const SizedBox(height: 22),
            Text(data.title,
                textAlign: TextAlign.center, style: buildTitleStyle(t)),
            const SizedBox(height: 22),
            _rule(90),
            const SizedBox(height: 20),
            Text(data.tagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    color: t.muted,
                    fontSize: 16,
                    height: 1.7)),
            const SizedBox(height: 36),
            buildButton(context, t, label: 'Play', onTap: data.onPlay),
            const SizedBox(height: 34),
            _elegantLink(t, 'How to play', data.onHowTo),
            _elegantLink(t, 'Themes', data.onThemes),
            _elegantLink(t, 'Tip jar', data.onTipJar),
            _elegantLink(t, 'More games', data.onMoreGames),
            const SizedBox(height: 34),
            buildPromo(data.slug),
            const SizedBox(height: 24),
            Text('Made with 💛 by Wajiha • 100% free forever',
                style: TextStyle(
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    color: t.muted.withValues(alpha: 0.8),
                    fontSize: 12)),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _elegantLink(GameTheme t, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: t.muted.withValues(alpha: 0.25)))),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 15,
                    letterSpacing: 2,
                    color: t.text)),
          ),
        ),
      );

  @override
  Widget buildButton(BuildContext context, GameTheme t,
      {required String label,
      String? emoji,
      required VoidCallback onTap,
      bool primary = true,
      double fontSize = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
        decoration: BoxDecoration(
          color: primary ? t.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: primary
              ? null
              : Border.all(color: _gold.withValues(alpha: 0.8), width: 1.2),
        ),
        child: Text(
          '${emoji != null ? '$emoji  ' : ''}${label.toUpperCase()}',
          style: TextStyle(
            fontFamily: 'serif',
            color: primary
                ? (t.dark ? Colors.black : Colors.white)
                : t.text,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildDialog(BuildContext context, GameTheme t,
      {required String title, String? emoji, required List<Widget> children}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Dialog(
          backgroundColor: t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
            side: BorderSide(color: _gold.withValues(alpha: 0.65), width: 1.2),
          ),
          child: Container(
            margin: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                  color: _gold.withValues(alpha: 0.35), width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null)
                  Text(emoji, style: const TextStyle(fontSize: 40)),
                if (emoji != null) const SizedBox(height: 12),
                Text(title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: t.text)),
                Container(
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    width: 56,
                    height: 1,
                    color: _gold.withValues(alpha: 0.8)),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildSheet(BuildContext context, GameTheme t, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        border: Border(
            top: BorderSide(color: _gold.withValues(alpha: 0.7), width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 40),
      child: child,
    );
  }

  @override
  Widget buildActionButton(BuildContext context, GameTheme t, String emoji,
      String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'serif',
                fontSize: 14,
                letterSpacing: 2,
                color: t.muted)),
      ),
    );
  }

  @override
  Widget buildSetup(BuildContext context, GameTheme t, PlayerSetupModel model,
      void Function(List<Player>) onStart, VoidCallback onBack) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack,
              child: Text('‹ Back',
                  style: TextStyle(
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                      color: t.muted,
                      fontSize: 15)),
            ),
            const SizedBox(height: 26),
            Text('The Players',
                style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: t.text)),
            Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                width: 64,
                height: 1,
                color: _gold.withValues(alpha: 0.8)),
            Wrap(
              spacing: 14,
              children: [
                for (final o in model.options)
                  GestureDetector(
                    onTap: () => model.setCount(o),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: o == model.count
                            ? t.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                            color: o == model.count
                                ? t.primary
                                : _gold.withValues(alpha: 0.6),
                            width: 1.2),
                      ),
                      alignment: Alignment.center,
                      child: Text('$o',
                          style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: o == model.count
                                  ? (t.dark ? Colors.black : Colors.white)
                                  : t.text)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView.builder(
                itemCount: model.seats,
                itemBuilder: (_, i) {
                  final p =
                      PlayerPresets.make(i + model.shuffleSeed * 7, isBot: model.bots[i]);
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: _gold.withValues(alpha: 0.3)))),
                    child: Row(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: t.text)),
                              Text(
                                  model.bots[i]
                                      ? 'a mechanical opponent'
                                      : 'a human, present',
                                  style: TextStyle(
                                      fontFamily: 'serif',
                                      fontStyle: FontStyle.italic,
                                      color: t.muted,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        if (model.supportsBots && i > 0)
                          Switch(
                              value: model.bots[i],
                              activeThumbColor: _gold,
                              onChanged: (v) => model.setBot(i, v)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Center(
                child: buildButton(context, t,
                    label: 'Begin',
                    onTap: () {
                      Sfx.click();
                      onStart(model.buildPlayers());
                    })),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildScoreChips(
      BuildContext context, GameTheme t, List<Player> players, int activeIndex) {
    return Wrap(
      spacing: 22,
      alignment: WrapAlignment.center,
      children: [
        for (int i = 0; i < players.length; i++)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(players[i].name,
                  style: TextStyle(
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                      color: i == activeIndex ? t.text : t.muted,
                      fontSize: 14)),
              Text('${players[i].score}',
                  style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: i == activeIndex ? _gold : t.muted)),
            ],
          ),
      ],
    );
  }
}

// ===========================================================================
// 10. GRAFFITI WALL — street art, chamfered cuts, skewed type
// ===========================================================================

/// Chamfered (diagonal-cut) corners for that sprayed-stencil look.
class _ChamferClipper extends CustomClipper<Path> {
  final double cut;
  const _ChamferClipper({this.cut = 14});
  @override
  Path getClip(Size size) {
    final c = cut;
    return Path()
      ..moveTo(c, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - c)
      ..lineTo(size.width - c, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, c)
      ..close();
  }

  @override
  bool shouldReclip(covariant _ChamferClipper old) => old.cut != cut;
}

class GraffitiWallSkin extends ShellSkin {
  const GraffitiWallSkin();
  @override
  String get name => 'Graffiti Wall';

  @override
  TextStyle buildTitleStyle(GameTheme t) => TextStyle(
        fontSize: 46,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: Colors.white,
        letterSpacing: 1,
        shadows: [
          Shadow(color: t.accent, offset: const Offset(4, 4), blurRadius: 0),
          Shadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(7, 7),
              blurRadius: 0),
        ],
      );

  @override
  Widget buildBackground(BuildContext context, GameTheme t, Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1B1B22),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
                painter: _WallPainter(
                    block: Colors.white.withValues(alpha: 0.03),
                    line: Colors.white.withValues(alpha: 0.06))),
          ),
          Positioned.fill(
            child: CustomPaint(
                painter: _SprinklePainter(colors: [
              t.primary.withValues(alpha: 0.5),
              t.accent.withValues(alpha: 0.5),
            ])),
          ),
          child,
        ],
      ),
    );
  }

  Widget _skew(Widget child, [double skew = -0.12]) => Transform(
        transform: Matrix4.skewX(skew),
        alignment: Alignment.center,
        child: child,
      );

  @override
  Widget buildSplash(BuildContext context, GameTheme t, String title, String emoji) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(-140 * (1 - v), 0),
            child: _skew(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 84)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                    color: t.primary,
                    child: Text(title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.black)),
                  ),
                  const SizedBox(height: 10),
                  Text('FRESH • FREE • FUN',
                      style: TextStyle(
                          color: t.accent,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildHome(BuildContext context, GameTheme t, ShellHomeData data) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _skew(Text(data.emoji, style: const TextStyle(fontSize: 72))),
            const SizedBox(height: 12),
            _skew(
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: t.primary,
                  boxShadow: [
                    BoxShadow(
                        color: t.accent,
                        offset: const Offset(6, 6),
                        blurRadius: 0),
                  ],
                ),
                child: Text(data.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                        letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 14),
            _skew(
              Text(data.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      height: 1.5)),
            ),
            const SizedBox(height: 28),
            _skew(buildButton(context, t,
                label: 'PLAY LOUD', emoji: '🎨', onTap: data.onPlay)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _sticker('❓', data.onHowTo, 0.06),
                const SizedBox(width: 14),
                _sticker('🎨', data.onThemes, -0.07),
                const SizedBox(width: 14),
                _sticker('☕', data.onTipJar, 0.05),
                const SizedBox(width: 14),
                _sticker('🎮', data.onMoreGames, -0.05),
              ],
            ),
            const SizedBox(height: 26),
            buildPromo(data.slug),
            const SizedBox(height: 16),
            _skew(
              const Text('WAJIHA • 100% FREE • NO RULES (OK SOME RULES)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      fontSize: 11)),
            ),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }

  Widget _sticker(String emoji, VoidCallback onTap, double rot) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: rot,
        child: Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
            ],
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }

  @override
  Widget buildButton(BuildContext context, GameTheme t,
      {required String label,
      String? emoji,
      required VoidCallback onTap,
      bool primary = true,
      double fontSize = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: const _ChamferClipper(cut: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 17),
          color: primary ? t.accent : const Color(0xFF2A2A33),
          child: _skew(
            Text(
              '${emoji ?? ''} $label'.trim().toUpperCase(),
              style: TextStyle(
                color: primary ? Colors.black : Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1,
              ),
            ),
            -0.08,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildDialog(BuildContext context, GameTheme t,
      {required String title, String? emoji, required List<Widget> children}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Transform(
          transform: Matrix4.skewX(-0.04 * (1 - v)),
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - v)),
            child: Dialog(
              backgroundColor: const Color(0xFF232330),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: t.accent, width: 3),
              ),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color: t.primary.withValues(alpha: 0.5),
                        offset: const Offset(6, 6),
                        blurRadius: 0),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (emoji != null)
                      Text(emoji, style: const TextStyle(fontSize: 44)),
                    const SizedBox(height: 8),
                    _skew(
                      Text(title.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: t.primary)),
                    ),
                    const SizedBox(height: 12),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildSheet(BuildContext context, GameTheme t, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232330),
        border: Border(top: BorderSide(color: t.accent, width: 4)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: child,
    );
  }

  @override
  Widget buildSetup(BuildContext context, GameTheme t, PlayerSetupModel model,
      void Function(List<Player>) onStart, VoidCallback onBack) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack,
              child: _skew(
                const Text('‹ BACK',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic)),
              ),
            ),
            const SizedBox(height: 14),
            _skew(
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: t.accent,
                child: const Text('PICK YOUR CREW',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.black)),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              children: [
                for (final o in model.options)
                  GestureDetector(
                    onTap: () => model.setCount(o),
                    child: Transform.rotate(
                      angle: (o.isEven ? -1 : 1) * 0.05,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: o == model.count
                              ? t.primary
                              : const Color(0xFF2A2A33),
                          border: Border.all(
                              color: o == model.count
                                  ? Colors.white
                                  : t.muted,
                              width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text('$o',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: o == model.count
                                    ? Colors.black
                                    : Colors.white)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.builder(
                itemCount: model.seats,
                itemBuilder: (_, i) {
                  final p =
                      PlayerPresets.make(i + model.shuffleSeed * 7, isBot: model.bots[i]);
                  return Transform.rotate(
                    angle: (i.isEven ? -1 : 1) * 0.012,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Text(p.emoji,
                              style: const TextStyle(fontSize: 30)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(p.name.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic)),
                          ),
                          if (model.supportsBots && i > 0)
                            Switch(
                                value: model.bots[i],
                                activeThumbColor: t.accent,
                                onChanged: (v) => model.setBot(i, v)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Center(
                child: _skew(buildButton(context, t,
                    label: 'BOMB IT!',
                    emoji: '💣',
                    onTap: () {
                      Sfx.click();
                      onStart(model.buildPlayers());
                    }))),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 11. AQUA DEPTH — underwater glow, rising bubbles, glossy glass
// ===========================================================================
class AquaDepthSkin extends ShellSkin {
  const AquaDepthSkin();
  @override
  String get name => 'Aqua Depth';

  @override
  TextStyle buildTitleStyle(GameTheme t) => const TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1,
        shadows: [
          Shadow(color: Color(0xFF4CC9F0), blurRadius: 24),
          Shadow(
              color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      );

  @override
  Widget buildBackground(BuildContext context, GameTheme t, Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF062A44), Color(0xFF03121F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          const _RisingBubbles(color: Color(0xFF4CC9F0)),
          Positioned.fill(
            child: CustomPaint(
                painter: _GlowPainter(
                    color: const Color(0xFF4CC9F0).withValues(alpha: 0.10))),
          ),
          child,
        ],
      ),
    );
  }

  @override
  Widget buildSplash(BuildContext context, GameTheme t, String title, String emoji) {
    return Stack(
      children: [
        const _RisingBubbles(color: Color(0xFF4CC9F0)),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, 70 * (1 - v)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Floaty(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            Colors.white.withValues(alpha: 0.28),
                            Colors.white.withValues(alpha: 0.06),
                          ]),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2),
                        ),
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 72)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(title,
                          textAlign: TextAlign.center,
                          style: buildTitleStyle(t)),
                    ),
                    const SizedBox(height: 10),
                    const Text('dive in • free forever 🫧',
                        style: TextStyle(
                            color: Colors.white70, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildHome(BuildContext context, GameTheme t, ShellHomeData data) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 48),
            _Floaty(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.05),
                  ]),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF4CC9F0).withValues(alpha: 0.4),
                        blurRadius: 30),
                  ],
                ),
                child: Text(data.emoji, style: const TextStyle(fontSize: 66)),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(data.title,
                  textAlign: TextAlign.center, style: buildTitleStyle(t)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Text(data.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70, height: 1.6, fontSize: 15)),
            ),
            const SizedBox(height: 30),
            buildButton(context, t,
                label: 'Dive in', emoji: '🌊', onTap: data.onPlay, fontSize: 22),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _bubbleAction(t, '❓', 'How', data.onHowTo),
                const SizedBox(width: 14),
                _bubbleAction(t, '🎨', 'Style', data.onThemes),
                const SizedBox(width: 14),
                _bubbleAction(t, '☕', 'Tip', data.onTipJar),
                const SizedBox(width: 14),
                _bubbleAction(t, '🎮', 'More', data.onMoreGames),
              ],
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: buildPromo(data.slug),
            ),
            const SizedBox(height: 18),
            const Text('Made with 💛 by Wajiha • 100% free forever',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _bubbleAction(
      GameTheme t, String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                Colors.white.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.05),
              ]),
              border: Border.all(
                  color: const Color(0xFF4CC9F0).withValues(alpha: 0.6),
                  width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget buildButton(BuildContext context, GameTheme t,
      {required String label,
      String? emoji,
      required VoidCallback onTap,
      bool primary = true,
      double fontSize = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: primary
              ? const LinearGradient(
                  colors: [Color(0xFF4CC9F0), Color(0xFF4361EE)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: primary ? null : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
              color: Colors.white.withValues(alpha: primary ? 0.55 : 0.3),
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CC9F0).withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 8,
              margin: const EdgeInsets.only(bottom: 2, left: 12, right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(colors: [
                  Colors.white.withValues(alpha: primary ? 0.55 : 0.25),
                  Colors.white.withValues(alpha: 0),
                ]),
              ),
            ),
            Text(
              '${emoji ?? ''} $label'.trim(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildDialog(BuildContext context, GameTheme t,
      {required String title, String? emoji, required List<Widget> children}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 46 * (1 - v)),
          child: Dialog(
            backgroundColor: const Color(0xFF0B2A44).withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
              side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF4CC9F0).withValues(alpha: 0.35),
                      blurRadius: 34),
                ],
              ),
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji != null)
                    _Floaty(
                      duration: const Duration(seconds: 3),
                      amplitude: 6,
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 46)),
                    ),
                  const SizedBox(height: 10),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                color: Color(0xFF4CC9F0), blurRadius: 14),
                          ])),
                  const SizedBox(height: 14),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildSheet(BuildContext context, GameTheme t, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B2A44).withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.25), width: 1.2),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: child,
    );
  }

  @override
  Widget buildSetup(BuildContext context, GameTheme t, PlayerSetupModel model,
      void Function(List<Player>) onStart, VoidCallback onBack) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: const Text('‹ back',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Who's diving in?",
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Color(0xFF4CC9F0), blurRadius: 16)
                    ])),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              children: [
                for (final o in model.options)
                  GestureDetector(
                    onTap: () => model.setCount(o),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: o == model.count
                            ? const LinearGradient(colors: [
                                Color(0xFF4CC9F0),
                                Color(0xFF4361EE)
                              ])
                            : null,
                        color: o == model.count
                            ? null
                            : Colors.white.withValues(alpha: 0.07),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.5),
                        boxShadow: o == model.count
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF4CC9F0)
                                        .withValues(alpha: 0.6),
                                    blurRadius: 18)
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text('$o',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: model.seats,
                itemBuilder: (_, i) {
                  final p =
                      PlayerPresets.make(i + model.shuffleSeed * 7, isBot: model.bots[i]);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.07),
                      border: Border.all(
                          color: p.color.withValues(alpha: 0.55), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(p.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                        ),
                        if (model.supportsBots && i > 0)
                          Switch(
                              value: model.bots[i],
                              activeThumbColor: const Color(0xFF4CC9F0),
                              onChanged: (v) => model.setBot(i, v)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Center(
                child: buildButton(context, t,
                    label: 'Dive in!',
                    emoji: '🌊',
                    onTap: () {
                      Sfx.click();
                      onStart(model.buildPlayers());
                    })),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 12. CANDY SHOP — sweet pastels, sprinkles, glossy candy buttons
// ===========================================================================
class CandyShopSkin extends ShellSkin {
  const CandyShopSkin();
  @override
  String get name => 'Candy Shop';

  @override
  TextStyle buildTitleStyle(GameTheme t) => const TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 1,
        shadows: [
          Shadow(color: Color(0xFFFF5DA2), blurRadius: 20),
          Shadow(
              color: Color(0xAA000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      );

  @override
  Widget buildBackground(BuildContext context, GameTheme t, Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE4F1), Color(0xFFFFC9E3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
                painter: _SprinklePainter(colors: const [
              Color(0xFFFF5DA2),
              Color(0xFF7C5CFF),
              Color(0xFFFFC531),
              Color(0xFF4CC9F0),
            ])),
          ),
          child,
        ],
      ),
    );
  }

  @override
  Widget buildSplash(BuildContext context, GameTheme t, String title, String emoji) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.4, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (_, v, __) => Transform.scale(
          scale: v,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [
                    Color(0xFFFF8FBE),
                    Color(0xFFFF5DA2)
                  ]),
                  border:
                      Border.all(color: Colors.white, width: 5),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFFF5DA2).withValues(alpha: 0.55),
                        blurRadius: 36),
                  ],
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 76)),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(title,
                    textAlign: TextAlign.center, style: buildTitleStyle(t)),
              ),
              const SizedBox(height: 8),
              const Text('sweet • free • yummy 🍭',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                            color: Color(0xFFFF5DA2), blurRadius: 10),
                      ])),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget buildHome(BuildContext context, GameTheme t, ShellHomeData data) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // striped awning band
            SizedBox(
              height: 44,
              child: CustomPaint(
                painter: _AwningPainter(),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 18),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1),
              duration: const Duration(milliseconds: 750),
              curve: Curves.elasticOut,
              builder: (_, v, __) => Transform.scale(
                scale: v,
                child: Text(data.emoji, style: const TextStyle(fontSize: 78)),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(data.title,
                  textAlign: TextAlign.center, style: buildTitleStyle(t)),
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 48),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(data.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF8A2B5C),
                      fontWeight: FontWeight.w600,
                      height: 1.4)),
            ),
            const SizedBox(height: 26),
            buildButton(context, t,
                label: 'Yum, play!', emoji: '🍬', onTap: data.onPlay, fontSize: 22),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _candyDot('❓', 'How', data.onHowTo, const Color(0xFF7C5CFF)),
                const SizedBox(width: 14),
                _candyDot('🎨', 'Style', data.onThemes, const Color(0xFFFFC531)),
                const SizedBox(width: 14),
                _candyDot('☕', 'Tip', data.onTipJar, const Color(0xFF4CC9F0)),
                const SizedBox(width: 14),
                _candyDot('🎮', 'More', data.onMoreGames, const Color(0xFFFF5DA2)),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: buildPromo(data.slug),
            ),
            const SizedBox(height: 16),
            const Text('Made with 💛 by Wajiha • 100% free forever',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    shadows: [
                      Shadow(color: Color(0xFFFF5DA2), blurRadius: 8),
                    ])),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _candyDot(
      String emoji, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                color.withValues(alpha: 0.9),
                color,
              ]),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 14,
                    offset: const Offset(0, 5)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(color: Color(0xFFFF5DA2), blurRadius: 6),
                  ])),
        ],
      ),
    );
  }

  @override
  Widget buildButton(BuildContext context, GameTheme t,
      {required String label,
      String? emoji,
      required VoidCallback onTap,
      bool primary = true,
      double fontSize = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: primary
              ? const LinearGradient(colors: [
                  Color(0xFFFF8FBE),
                  Color(0xFFFF5DA2),
                ])
              : null,
          color: primary ? null : Colors.white,
          border: Border.all(color: Colors.white, width: primary ? 3 : 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5DA2).withValues(alpha: 0.5),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 7,
              margin: const EdgeInsets.only(bottom: 3, left: 14, right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(colors: [
                  Colors.white.withValues(alpha: 0.75),
                  Colors.white.withValues(alpha: 0),
                ]),
              ),
            ),
            Text(
              '${emoji ?? ''} $label'.trim(),
              style: TextStyle(
                color: primary ? Colors.white : const Color(0xFF8A2B5C),
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildDialog(BuildContext context, GameTheme t,
      {required String title, String? emoji, required List<Widget> children}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (_, v, __) => Transform.scale(
        scale: 0.75 + 0.25 * v,
        child: Dialog(
          backgroundColor: const Color(0xFFFFF6FA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(color: Colors.white, width: 4),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                  color: const Color(0xFFFF5DA2).withValues(alpha: 0.5),
                  width: 2),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFFF5DA2).withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 12)),
              ],
            ),
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null)
                  Text(emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 10),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8A2B5C))),
                _sprinkleDivider(),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sprinkleDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          height: 10,
          child: CustomPaint(
              painter: _SprinklePainter(colors: const [
                Color(0xFFFF5DA2),
                Color(0xFF7C5CFF),
                Color(0xFFFFC531),
              ]),
              child: const SizedBox.expand()),
        ),
      );

  @override
  Widget buildSheet(BuildContext context, GameTheme t, Widget child) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF6FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: Colors.white, width: 5)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: child,
    );
  }

  @override
  Widget buildSetup(BuildContext context, GameTheme t, PlayerSetupModel model,
      void Function(List<Player>) onStart, VoidCallback onBack) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFFF5DA2).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: const Text('‹ back',
                    style: TextStyle(
                        color: Color(0xFF8A2B5C),
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Who's playing?",
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Color(0xFFFF5DA2), blurRadius: 16),
                    ])),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              children: [
                for (final o in model.options)
                  GestureDetector(
                    onTap: () => model.setCount(o),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: o == model.count
                            ? const LinearGradient(colors: [
                                Color(0xFFFF8FBE),
                                Color(0xFFFF5DA2),
                              ])
                            : null,
                        color: o == model.count
                            ? null
                            : Colors.white.withValues(alpha: 0.9),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  const Color(0xFFFF5DA2).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 5)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text('$o',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: o == model.count
                                  ? Colors.white
                                  : const Color(0xFF8A2B5C))),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: model.seats,
                itemBuilder: (_, i) {
                  final p =
                      PlayerPresets.make(i + model.shuffleSeed * 7, isBot: model.bots[i]);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: p.color.withValues(alpha: 0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFFF5DA2)
                                .withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(p.name,
                              style: const TextStyle(
                                  color: Color(0xFF8A2B5C),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                        ),
                        if (model.supportsBots && i > 0)
                          Switch(
                              value: model.bots[i],
                              activeThumbColor: const Color(0xFFFF5DA2),
                              onChanged: (v) => model.setBot(i, v)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Center(
                child: buildButton(context, t,
                    label: "Let's go!",
                    emoji: '🍭',
                    onTap: () {
                      Sfx.click();
                      onStart(model.buildPlayers());
                    })),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }
}

/// Striped candy-shop awning band.
class _AwningPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const stripe = 36.0;
    final colors = [const Color(0xFFFF5DA2), Colors.white];
    for (double x = 0; x < size.width; x += stripe) {
      canvas.drawRect(
          Rect.fromLTWH(x, 0, stripe, size.height),
          Paint()..color = colors[((x / stripe).round()) % 2]);
    }
    // scalloped bottom edge
    final p = Paint()..color = const Color(0xFFFF5DA2);
    for (double x = 0; x < size.width; x += stripe) {
      canvas.drawCircle(
          Offset(x + stripe / 2, size.height), stripe / 2, p);
    }
  }

  @override
  bool shouldRepaint(covariant _AwningPainter old) => false;
}
