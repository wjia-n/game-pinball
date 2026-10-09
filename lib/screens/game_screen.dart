import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/pinball_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/ball_styles.dart';
import '../theme/pinball_themes.dart';

/// Game screen: renders the engine, forwards input. The engine owns all
/// state — this widget never decides game outcomes.
class GameScreen extends StatefulWidget {
  final PinballAudio audio;
  final PinballSettings settings;
  const GameScreen({super.key, required this.audio, required this.settings});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  late final PinballEngine _engine;
  Duration _last = Duration.zero;
  bool _pausedOverlay = false;
  bool _lifecyclePaused = false;
  bool _gameOverShown = false;
  int _finalScore = 0;
  bool _wasRecord = false;
  bool _reviewAsked = false;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _engine = PinballEngine(
      mode: switch (s.mode) {
        PinballMode.scoreAttack => PinballModeId.scoreAttack,
        PinballMode.endless => PinballModeId.endless,
        PinballMode.timeRush => PinballModeId.timeRush,
      },
      difficulty: switch (s.difficulty) {
        PinballDifficulty.gentle => PinballDifficultyId.gentle,
        PinballDifficulty.parlor => PinballDifficultyId.parlor,
        PinballDifficulty.lightning => PinballDifficultyId.lightning,
      },
      ballsPerGame: s.attackBalls,
      timeRushSeconds: PinballSettings.timeRushSeconds,
    );
    _engine.onSfx = _playSfx;
    _engine.onGameOver = _onGameOver;
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Freeze the engine while backgrounded; resume cleanly.
    _lifecyclePaused = state != AppLifecycleState.resumed;
  }

  void _playSfx(String id) {
    final a = widget.audio;
    switch (id) {
      case PinballSfx.flipper:
        a.flipper();
      case PinballSfx.bumper0:
        a.bumper(0);
      case PinballSfx.bumper1:
        a.bumper(1);
      case PinballSfx.bumper2:
        a.bumper(2);
      case PinballSfx.sling:
        a.sling();
      case PinballSfx.rollover:
        a.rollover();
      case PinballSfx.bell:
        a.bell();
      case PinballSfx.multUp:
        a.multUp();
      case PinballSfx.plunger:
        a.plunger();
      case PinballSfx.launch:
        a.launch();
      case PinballSfx.drain:
        a.drain();
      case PinballSfx.tilt:
        a.tilt();
    }
  }

  Future<void> _onGameOver(int score) async {
    _finalScore = score;
    _wasRecord = await widget.settings.recordGame(score);
    if (_wasRecord) {
      widget.audio.win();
    } else {
      widget.audio.lose();
    }
    if (mounted) setState(() => _gameOverShown = true);
    // Sensible review moment: a new record, or every 3rd finished game.
    final n = widget.settings.gamesPlayed;
    if (!_reviewAsked && (_wasRecord || n % 3 == 0)) {
      _reviewAsked = true;
      _requestReview();
    }
  }

  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      }
      // Not from Play / unavailable: stay silent, no fake UI.
    } catch (_) {}
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) {
      _last = elapsed;
      return;
    }
    final dt = min((elapsed - _last).inMicroseconds / 1e6, 0.05);
    _last = elapsed;
    _engine.paused = _pausedOverlay || _lifecyclePaused;
    _engine.step(dt);
    setState(() {});
  }

  void _restart() {
    widget.audio.gameStart();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            GameScreen(audio: widget.audio, settings: widget.settings),
      ),
    );
  }

  /// Leaving mid-run (endless / time-rush): bank the score before popping.
  Future<void> _quitToMenu() async {
    widget.audio.click();
    final s = widget.settings;
    if ((s.mode == PinballMode.endless ||
            s.mode == PinballMode.timeRush) &&
        _engine.phase != PinballPhase.gameOver &&
        _engine.score > 0) {
      await s.recordGame(_engine.score);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final t = s.theme;
    final ball = s.ballStyle;
    return Scaffold(
      backgroundColor: const Color(0xFF0E0906),
      body: SafeArea(
        child: Column(
          children: [
            _hud(t, s),
            Expanded(
              child: _TableView(
                engine: _engine,
                theme: t,
                ball: ball,
                onSize: (size) =>
                    _engine.buildTable(size.width, size.height),
              ),
            ),
            const SizedBox(height: 6),
            _controls(t),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _hud(PinballThemeDef t, PinballSettings s) {
    final e = _engine;
    final ballsLabel = s.mode == PinballMode.endless
        ? '∞'
        : '${max(e.ballsLeft, 0)}/${s.attackBalls}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              _stat(t, 'SCORE', '${e.score}'),
              _stat(t, 'BEST', '${s.bestForMode}'),
              _stat(t, 'MULT', 'x${e.mult}'),
              _stat(
                  t,
                  s.mode == PinballMode.timeRush ? 'TIME' : 'BALL',
                  s.mode == PinballMode.timeRush
                      ? _fmtTime(e.timeLeft)
                      : ballsLabel),
              IconButton(
                tooltip: 'Pause',
                icon: Icon(Icons.pause_circle_outline, color: t.ivory),
                onPressed: () {
                  widget.audio.click();
                  setState(() => _pausedOverlay = true);
                },
              ),
            ],
          ),
          // Multiball / lock progress line.
          if (e.inMultiball || e.lockCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                e.inMultiball
                    ? 'MULTIBALL — all scoring x2!'
                    : 'Ball lock ${e.lockCount}/2 — light the lanes at x5',
                style: TextStyle(
                  color: e.inMultiball ? t.laneLit : t.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmtTime(double t) {
    final s = t.ceil();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Widget _stat(PinballThemeDef t, String l, String v) => Expanded(
        child: Column(
          children: [
            Text(l,
                style: TextStyle(
                    color: t.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
            Text(v,
                style: TextStyle(
                    color: t.ivory,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      );

  /// Icon-based circular controls (no dated text buttons).
  Widget _controls(PinballThemeDef t) {
    final e = _engine;
    if (_gameOverShown) return _gameOverPanel(t);
    if (_pausedOverlay) return _pausePanel(t);
    return Column(
      children: [
        if (e.phase == PinballPhase.aim) _plungerControl(t),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _roundButton(
              t,
              icon: Icons.arrow_back,
              onDown: () => e.flipperDown(true),
              onUp: () => e.flipperUp(true),
              size: 76,
            ),
            _roundButton(
              t,
              icon: Icons.vibration,
              onDown: () => e.nudge(),
              onUp: () {},
              size: 60,
              tapOnly: true,
            ),
            _roundButton(
              t,
              icon: Icons.arrow_forward,
              onDown: () => e.flipperDown(false),
              onUp: () => e.flipperUp(false),
              size: 76,
            ),
          ],
        ),
      ],
    );
  }

  Widget _roundButton(
    PinballThemeDef t, {
    required IconData icon,
    required void Function() onDown,
    required void Function() onUp,
    required double size,
    bool tapOnly = false,
  }) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: tapOnly ? null : (_) => onUp(),
      onTapCancel: tapOnly ? null : onUp,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: t.woodMid,
          border: Border.all(color: t.accent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: t.ivory, size: size * 0.42),
      ),
    );
  }

  Widget _plungerControl(PinballThemeDef t) {
    final e = _engine;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTapDown: (_) => e.startCharge(),
        onTapUp: (_) => e.releasePlunger(),
        onTapCancel: () => e.cancelCharge(),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: t.accent.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: t.accent, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_upward, color: t.ivory),
              const SizedBox(width: 8),
              Text('HOLD TO PLUNGE',
                  style: TextStyle(
                      color: t.ivory, fontWeight: FontWeight.w800)),
              if (e.charging) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 90,
                  child: LinearProgressIndicator(
                    value: e.power,
                    backgroundColor: t.muted.withValues(alpha: 0.3),
                    color: t.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pausePanel(PinballThemeDef t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.woodDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.accent, width: 2),
      ),
      child: Column(
        children: [
          Text('PAUSED',
              style: TextStyle(
                  color: t.ivory,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _panelBtn(t, Icons.play_arrow, 'Resume', () {
                widget.audio.click();
                setState(() => _pausedOverlay = false);
              }),
              _panelBtn(t, Icons.refresh, 'Restart', _restart),
              _panelBtn(t, Icons.home, 'Menu', _quitToMenu),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gameOverPanel(PinballThemeDef t) {
    final s = widget.settings;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.woodDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.accent, width: 2),
      ),
      child: Column(
        children: [
          Text('GAME OVER',
              style: TextStyle(
                  color: t.ivory,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4)),
          const SizedBox(height: 6),
          Text('$_finalScore',
              style: TextStyle(
                  color: t.accent,
                  fontSize: 38,
                  fontWeight: FontWeight.w900)),
          if (_wasRecord)
            Text('NEW RECORD!  ${s.profile.initials}',
                style: TextStyle(
                    color: t.laneLit,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          Text('Best: ${s.bestForMode}  ·  ${s.profile.name}',
              style: TextStyle(color: t.muted, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _panelBtn(t, Icons.refresh, 'Again', _restart),
              _panelBtn(t, Icons.share, 'Share', () {
                widget.audio.click();
                Share.share(
                  'I scored $_finalScore in Pinball by WAJIHA! Can you beat it? https://play.google.com/store/apps/details?id=com.gameswajiha.pinball',
                  subject: 'My Pinball score',
                );
              }),
              _panelBtn(t, Icons.home, 'Menu', () {
                widget.audio.click();
                Navigator.of(context).pop();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panelBtn(
      PinballThemeDef t, IconData icon, String label, void Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.woodMid,
              border: Border.all(color: t.accent, width: 2),
            ),
            child: Icon(icon, color: t.ivory),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: t.muted, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Table view: builds engine geometry on layout, then paints every frame.
class _TableView extends StatefulWidget {
  final PinballEngine engine;
  final PinballThemeDef theme;
  final BallStyleDef ball;
  final void Function(Size size) onSize;
  const _TableView(
      {required this.engine,
      required this.theme,
      required this.ball,
      required this.onSize});

  @override
  State<_TableView> createState() => _TableViewState();
}

class _TableViewState extends State<_TableView> {
  Size _last = Size.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final ns = Size(c.maxWidth, c.maxHeight);
      if (ns.width > 0 &&
          ns.height > 0 &&
          (_last == Size.zero ||
              (_last.width - ns.width).abs() > 1 ||
              (_last.height - ns.height).abs() > 1)) {
        _last = ns;
        // Defer: engine geometry must not be rebuilt during layout.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onSize(ns);
        });
      }
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: widget.theme.felt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.theme.woodLight, width: 6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CustomPaint(
            painter: _TablePainter(
              engine: widget.engine,
              theme: widget.theme,
              ball: widget.ball,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
    });
  }
}

class _TablePainter extends CustomPainter {
  final PinballEngine e;
  final PinballThemeDef theme;
  final BallStyleDef ball;

  _TablePainter(
      {required this.e, required this.theme, required this.ball});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    // Engine geometry is in table units (1 unit = table width).
    Offset pt(double nx, double ny) => Offset(nx * w, ny * w);

    // Playfield felt.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = theme.felt,
    );

    // Walls / rails.
    final wallPaint = Paint()
      ..color = theme.rail
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (final s in e.walls) {
      canvas.drawLine(pt(s.ax, s.ay), pt(s.bx, s.by), wallPaint);
    }
    // Slingshots.
    for (final s in e.slings) {
      canvas.drawLine(
        pt(s.ax, s.ay),
        pt(s.bx, s.by),
        Paint()
          ..color = theme.sling
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    }
    // Rollover lanes.
    for (var i = 0; i < e.lanePoints.length; i++) {
      final l = e.lanePoints[i];
      final lit = e.litLanes.contains(i);
      canvas.drawCircle(
        pt(l.x, l.y),
        w * 0.035,
        Paint()
          ..color = (lit ? theme.laneLit : theme.laneUnlit)
              .withValues(alpha: 0.55),
      );
    }
    // Bumpers with flash.
    for (var i = 0; i < e.bumpers.length; i++) {
      final b = e.bumpers[i];
      final c = (i % 2 == 0 ? theme.bumperA : theme.bumperB)
          .withValues(alpha: 0.55 + 0.45 * b.flash);
      final bp = pt(b.x, b.y);
      final br = b.r * w;
      canvas.drawCircle(bp, br, Paint()..color = c);
      canvas.drawCircle(
          bp, br * 0.45, Paint()..color = theme.felt.withValues(alpha: 0.9));
      canvas.drawCircle(
          bp,
          br,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = theme.woodLight.withValues(alpha: 0.8));
    }
    // Flippers.
    for (final left in [true, false]) {
      final piv = left
          ? pt(e.flipPivotLX, e.flipPivotLY)
          : pt(e.flipPivotRX, e.flipPivotRY);
      final tipP = e.flipperTipPublic(left);
      final tip = pt(tipP.x, tipP.y);
      canvas.drawLine(
        piv,
        tip,
        Paint()
          ..color = theme.flipper
          ..strokeWidth = 13
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(piv, 8, Paint()..color = theme.rail);
    }
    // Plunger rod while aiming.
    if (e.phase == PinballPhase.aim) {
      final px = e.plungeLaneX * w;
      final rodTop = (e.serveBallY - e.power * 0.20) * w;
      final rodBottom = (e.serveBallY + 0.16) * w;
      canvas.drawLine(
        Offset(px, rodTop),
        Offset(px, rodBottom),
        Paint()
          ..color = theme.woodLight
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round,
      );
      // Power gauge ticks.
      for (var i = 0; i <= 10; i++) {
        final yy = rodBottom - i * 0.016 * w;
        canvas.drawLine(
          Offset(px + 0.05 * w, yy),
          Offset(px + 0.07 * w, yy),
          Paint()
            ..color = (i / 10 <= e.power ? theme.laneLit : theme.muted)
            ..strokeWidth = 3,
        );
      }
    }
    // Balls (one, or three during multiball): trail + physical material.
    if (e.ballVisible) {
      for (final b in e.balls) {
        // Ball trail.
        final n = b.trail.length;
        for (var i = 0; i < n; i++) {
          final p = b.trail[i];
          canvas.drawCircle(
            pt(p.x, p.y),
            e.ballRadius * w * (i / max(n, 1)) * 0.8,
            Paint()
              ..color = ball.trail
                  .withValues(alpha: 0.25 * i / max(n, 1)),
          );
        }
        // Ball: rim + core + sheen highlight = physical depth.
        final bp = pt(b.x, b.y);
        final br = e.ballRadius * w;
        canvas.drawCircle(bp, br, Paint()..color = ball.rim);
        canvas.drawCircle(bp, br * 0.88, Paint()..color = ball.core);
        canvas.drawCircle(
          bp + Offset(-br * 0.3, -br * 0.3),
          br * 0.32,
          Paint()..color = ball.sheen.withValues(alpha: 0.85),
        );
      }
    }
    // Score popups (fade as they rise).
    for (final p in e.popups) {
      final alpha = (p.ttl / 1.0).clamp(0.0, 1.0).toDouble();
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            color: theme.ivory.withValues(alpha: alpha),
            fontSize: 15,
            fontWeight: FontWeight.w800,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset(p.x * w - tp.width / 2,
              (p.y - (1 - p.ttl) * 0.12) * w - tp.height / 2));
    }
    // Banner.
    if (e.bannerT > 0 && e.banner.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: e.banner,
          style: TextStyle(
            color: theme.laneLit,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 6),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset((w - tp.width) / 2, size.height * 0.42 - tp.height / 2));
    }
    // Tilt warning tint.
    if (e.phase == PinballPhase.tilt) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.red.withValues(alpha: 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TablePainter old) => true;
}
