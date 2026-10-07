import 'package:flutter/material.dart';
import '../audio/sfx.dart';
import '../iap/tip_jar.dart';
import '../marketing/cross_promo.dart';
import '../players/player.dart';
import '../theme/game_theme.dart';
import 'bits.dart';
import 'shell_variants.dart';

/// Callbacks the shell hands to the game screen.
class GameCallbacks {
  /// Call when the match ends.
  final void Function({Player? winner, String? headline, String? subline}) finish;

  /// Call after mutating [Player.score] so the HUD refreshes.
  final void Function() refreshHud;

  /// Tell the shell whose turn it is (highlights their score chip).
  final void Function(int index) setActivePlayer;

  const GameCallbacks({required this.finish, required this.refreshHud, required this.setActivePlayer});
}

enum _Stage { splash, home, setup, playing }

/// The complete app wrapper every game uses: splash, home, player setup,
/// pause menu, themes, tip jar, cross-promo and game-over flow.
///
/// [variant] picks one of the 12 visual identities ([ShellVariant]) so no
/// two games share the same menus. Defaults to Playful Pop.
class GameShell extends StatefulWidget {
  final String title;
  final String tagline;
  final String emoji;
  final String howToPlay;
  final String slug;
  final List<int> playerOptions;
  final bool supportsBots;
  final ShellVariant variant;
  final Widget Function(BuildContext context, List<Player> players, GameCallbacks callbacks) gameBuilder;

  const GameShell({
    super.key,
    required this.title,
    required this.tagline,
    required this.emoji,
    required this.howToPlay,
    required this.slug,
    required this.gameBuilder,
    this.playerOptions = const [1, 2],
    this.supportsBots = true,
    this.variant = ShellVariant.playfulPop,
  });

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  final ThemeController _themes = ThemeController();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  _Stage _stage = _Stage.splash;
  List<Player> _players = [];
  int _gameKey = 0;
  int _activeIndex = 0;

  ShellSkin get _skin => widget.variant.skin;

  /// Dialogs/sheets must use the navigator's context: the state's own
  /// context sits above MaterialApp (no Navigator, no ThemeScope there).
  BuildContext? get _dlgContext => _navigatorKey.currentContext;

  @override
  void initState() {
    super.initState();
    _themes.load();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _stage = _Stage.home);
    });
  }

  void _startSetup() {
    Sfx.click();
    setState(() => _stage = _Stage.setup);
  }

  void _beginGame(List<Player> players) {
    _players = players;
    _gameKey++;
    _activeIndex = 0;
    setState(() => _stage = _Stage.playing);
  }

  List<Player> _freshPlayers() => _players
      .map((p) => PlayerPresets.make(_players.indexOf(p), isBot: p.isBot))
      .toList();

  void _onGameOver({Player? winner, String? headline, String? subline}) {
    final ctx = _dlgContext;
    if (ctx == null) return;
    Sfx.win();
    final t = _themes.theme;
    final skin = _skin;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dlg) => skin.buildGameOverDialog(
        dlg,
        t,
        winner: winner,
        headline: headline,
        subline: subline,
        players: _players,
        onRematch: () {
          Navigator.pop(dlg);
          _beginGame(_freshPlayers());
        },
        onShare: () => CrossPromo.shareGame(widget.slug, widget.title),
        onMenu: () {
          Navigator.pop(dlg);
          setState(() => _stage = _Stage.home);
        },
      ),
    );
  }

  void _showThemes() {
    final ctx = _dlgContext;
    if (ctx == null) return;
    final t = _themes.theme;
    final skin = _skin;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheet) => skin.buildSheet(
        sheet,
        t,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                    color: t.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 12),
            Text('🎨 Pick your vibe', style: skin.buildHeadingStyle(t)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12),
              itemCount: GameThemes.all.length,
              itemBuilder: (_, i) {
                final th = GameThemes.all[i];
                final active = th.id == _themes.theme.id;
                return GestureDetector(
                  onTap: () {
                    Sfx.tap();
                    _themes.setTheme(th);
                    Navigator.pop(sheet);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [th.primary, th.secondary]),
                          borderRadius: BorderRadius.circular(18),
                          border: active ? Border.all(color: th.text, width: 3) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(th.emoji, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(height: 4),
                      Text(th.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10,
                              color: t.muted,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHowTo() {
    final ctx = _dlgContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      builder: (dlg) => WajihaDialog(
        emoji: '❓',
        title: 'How to play',
        children: [
          Text(widget.howToPlay,
              style: TextStyle(color: _themes.theme.muted, height: 1.6)),
          const SizedBox(height: 16),
          WajihaButton(label: 'Got it!', onTap: () => Navigator.pop(dlg)),
        ],
      ),
    );
  }

  void _showTipJar() {
    final ctx = _dlgContext;
    if (ctx == null) return;
    showModalBottomSheet(
        context: ctx,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheet) =>
            _skin.buildSheet(sheet, _themes.theme, const TipJarSheet()));
  }

  void _showMoreGames() {
    final ctx = _dlgContext;
    if (ctx == null) return;
    showModalBottomSheet(
        context: ctx,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheet) => _skin.buildSheet(
            sheet, _themes.theme, MoreGamesSheet(currentSlug: widget.slug)));
  }

  @override
  Widget build(BuildContext context) {
    // Scopes sit ABOVE MaterialApp so dialogs, sheets and every route
    // can reach the theme controller and the active skin.
    return ListenableBuilder(
      listenable: _themes,
      builder: (context, _) => ShellVariantScope(
        skin: _skin,
        child: ThemeScope(
          controller: _themes,
          child: MaterialApp(
            title: widget.title,
            debugShowCheckedModeBanner: false,
            theme: _themes.theme.materialTheme,
            navigatorKey: _navigatorKey,
            home: switch (_stage) {
              _Stage.splash => _splash(),
              _Stage.home => _home(),
              _Stage.setup => _PlayerSetup(
                  options: widget.playerOptions,
                  supportsBots: widget.supportsBots,
                  onStart: _beginGame,
                  onBack: () => setState(() => _Stage.home),
                ),
              _Stage.playing => _gameScreen(),
            },
          ),
        ),
      ),
    );
  }

  Widget _splash() {
    final t = _themes.theme;
    final skin = _skin;
    return Scaffold(
      body: skin.buildBackground(
          context, t, skin.buildSplash(context, t, widget.title, widget.emoji)),
    );
  }

  Widget _home() {
    final t = _themes.theme;
    final skin = _skin;
    return Scaffold(
      body: skin.buildBackground(
        context,
        t,
        skin.buildHome(
          context,
          t,
          ShellHomeData(
            title: widget.title,
            tagline: widget.tagline,
            emoji: widget.emoji,
            slug: widget.slug,
            onPlay: _startSetup,
            onHowTo: _showHowTo,
            onThemes: _showThemes,
            onTipJar: _showTipJar,
            onMoreGames: _showMoreGames,
          ),
        ),
      ),
    );
  }

  Widget _gameScreen() {
    final t = _themes.theme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.pause_rounded, color: t.text),
          onPressed: _showPause,
        ),
        title: Text(widget.title,
            style: TextStyle(color: t.text, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Text('🎮', style: TextStyle(fontSize: 22)),
              onPressed: _showMoreGames),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_players.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ScoreChips(players: _players, activeIndex: _activeIndex),
              ),
            Expanded(
              child: KeyedSubtree(
                key: ValueKey(_gameKey),
                child: Builder(
                  builder: (ctx) => widget.gameBuilder(
                    ctx,
                    _players,
                    GameCallbacks(
                      finish: _onGameOver,
                      refreshHud: () => setState(() {}),
                      setActivePlayer: (i) => setState(() => _activeIndex = i),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPause() {
    final ctx = _dlgContext;
    if (ctx == null) return;
    Sfx.tap();
    final t = _themes.theme;
    showDialog(
      context: ctx,
      builder: (dlg) => _skin.buildPauseDialog(
        dlg,
        t,
        onResume: () => Navigator.pop(dlg),
        onRestart: () {
          Navigator.pop(dlg);
          _beginGame(_freshPlayers());
        },
        onHowTo: () {
          Navigator.pop(dlg);
          _showHowTo();
        },
        onQuit: () {
          Navigator.pop(dlg);
          setState(() => _stage = _Stage.home);
        },
      ),
    );
  }
}

/// Player-count + bot setup screen (local pass-and-play party setup).
/// The visual presentation is delegated to the active shell skin.
class _PlayerSetup extends StatefulWidget {
  final List<int> options;
  final bool supportsBots;
  final void Function(List<Player>) onStart;
  final VoidCallback onBack;

  const _PlayerSetup(
      {required this.options,
      required this.supportsBots,
      required this.onStart,
      required this.onBack});

  @override
  State<_PlayerSetup> createState() => _PlayerSetupState();
}

class _PlayerSetupState extends State<_PlayerSetup> {
  late final PlayerSetupModel _model;

  @override
  void initState() {
    super.initState();
    _model = PlayerSetupModel(
        options: widget.options, supportsBots: widget.supportsBots);
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final skin = ShellVariantScope.skinOf(context);
    return Scaffold(
      body: skin.buildBackground(
        context,
        t,
        ListenableBuilder(
          listenable: _model,
          builder: (context, _) =>
              skin.buildSetup(context, t, _model, widget.onStart, widget.onBack),
        ),
      ),
    );
  }
}
