import 'dart:math';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/game_theme.dart';
import 'all_games.dart';

/// In-game marketing: every game cross-promotes the rest of the catalogue.
class CrossPromo {
  /// Play Store URL for a game package.
  static String storeUrl(String slug) =>
      'https://play.google.com/store/apps/details?id=com.gameswajiha.$slug';

  /// Share text for the current game.
  static Future<void> shareGame(String slug, String name) async {
    await Share.share(
      'I\'m playing $name - it\'s free and ridiculously fun! ${storeUrl(slug)}',
      subject: 'Try $name!',
    );
  }

  static Future<void> openStore(String slug) async {
    final uri = Uri.parse(storeUrl(slug));
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// A few random *other* games, for the "More games" sheet.
  static List<GameInfo> picks({required String excludeSlug, int count = 9}) {
    final others = kAllGames.where((g) => g.slug != excludeSlug).toList()..shuffle(Random());
    return others.take(count).toList();
  }

  /// One featured game for the home-screen promo banner.
  static GameInfo featured({required String excludeSlug}) {
    final others = kAllGames.where((g) => g.slug != excludeSlug).toList();
    return others[Random().nextInt(others.length)];
  }
}

/// Bottom sheet grid: "More games you'll love".
class MoreGamesSheet extends StatelessWidget {
  final String currentSlug;
  const MoreGamesSheet({super.key, required this.currentSlug});

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final games = CrossPromo.picks(excludeSlug: currentSlug, count: 12);
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 48, height: 5, decoration: BoxDecoration(color: t.muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(99))),
          const SizedBox(height: 12),
          Text('🎮 More games you\'ll love', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: t.text)),
          const SizedBox(height: 4),
          Text('All free. All fun. Made by Wajiha.', style: TextStyle(color: t.muted, fontSize: 13)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85,
            ),
            itemCount: games.length,
            itemBuilder: (_, i) {
              final g = games[i];
              return GestureDetector(
                onTap: () => CrossPromo.openStore(g.slug),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [g.color1.withValues(alpha: 0.85), g.color2.withValues(alpha: 0.85)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: t.radius,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(g.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 6),
                      Text(g.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Slim promo banner shown on home screens: "New: `Game` - Play free".
class PromoBanner extends StatelessWidget {
  final String currentSlug;
  const PromoBanner({super.key, required this.currentSlug});

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final g = CrossPromo.featured(excludeSlug: currentSlug);
    return GestureDetector(
      onTap: () => CrossPromo.openStore(g.slug),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [g.color1, g.color2]),
          borderRadius: t.radius,
          boxShadow: [BoxShadow(color: g.color1.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Text(g.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔥 TRY THIS TOO', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800)),
                  Text(g.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
