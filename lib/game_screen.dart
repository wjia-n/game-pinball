import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

class _Seg {
  final Offset a, b;
  _Seg(this.a, this.b);
}

class _Bumper {
  final Offset p;
  final double r;
  double flash = 0;
  double cd = 0;
  _Bumper(this.p, this.r);
}

class PinballScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const PinballScreen(
      {super.key, required this.players, required this.callbacks});

  @override
  State<PinballScreen> createState() => _PinballScreenState();
}

class _PinballScreenState extends State<PinballScreen>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  late Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;

  // table geometry (rebuilt on size change)
  final List<_Seg> _walls = [];
  final List<_Bumper> _bumpers = [];
  final List<Offset> _lanes = [];
  final List<_Seg> _slings = [];
  double _leftX = 0, _divX = 0, _rightX = 0, _topY = 0;
  Offset _flipLP = Offset.zero, _flipRP = Offset.zero;
  double _flipLen = 60, _br = 10;

  // ball
  Offset _p = Offset.zero, _v = Offset.zero;
  bool _launched = false;
  final List<Offset> _trail = [];

  // flippers
  double _flipL = 0, _flipR = 0; // 0 rest .. 1 active
  bool _holdL = false, _holdR = false;

  // plunger
  bool _charging = false;
  double _power = 0, _powerDir = 1;

  int _score = 0, _best = 0, _mult = 1, _balls = 3;
  final Set<int> _lit = {};
  final List<double> _nudges = [];
  double _nudgeCd = 0, _tGlobal = 0;
  String _banner = '';
  double _bannerT = 0;
  bool _over = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _best = p.getInt('pinball_best') ?? 0);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _buildTable(Size s) {
    _size = s;
    final w = s.width, h = s.height;
    _leftX = w * 0.05;
    _divX = w * 0.80;
    _rightX = w * 0.95;
    _topY = h * 0.03;
    _br = w * 0.024;
    _flipLen = w * 0.15;
    _walls.clear();
    // left wall + inlane
    _walls.add(_Seg(Offset(_leftX, _topY + h * 0.09), Offset(_leftX, h * 0.84)));
    _walls.add(_Seg(Offset(_leftX, h * 0.84), Offset(w * 0.30, h * 0.985)));
    // divider (plunger lane)
    _walls.add(_Seg(Offset(_divX, _topY), Offset(_divX, h * 0.55)));
    _walls.add(_Seg(Offset(_rightX, _topY), Offset(_rightX, h * 0.985)));
    _walls.add(_Seg(Offset(_divX, h * 0.985), Offset(_rightX, h * 0.985)));
    // right inlane guide
    _walls.add(_Seg(Offset(_divX, h * 0.55), Offset(w * 0.60, h * 0.90)));
    // top arc
    final cx = (_leftX + _divX) / 2, cy = _topY + h * 0.09, r = (_divX - _leftX) / 2;
    Offset? prev;
    for (var i = 0; i <= 6; i++) {
      final a = pi + i / 6 * pi;
      final pt = Offset(cx + cos(a) * r, cy + sin(a) * r);
      if (prev != null) _walls.add(_Seg(prev, pt));
      prev = pt;
    }
    _bumpers.clear();
    _bumpers.addAll([
      _Bumper(Offset(w * 0.36, h * 0.24), w * 0.055),
      _Bumper(Offset(w * 0.55, h * 0.20), w * 0.055),
      _Bumper(Offset(w * 0.45, h * 0.35), w * 0.055),
    ]);
    _lanes.clear();
    _lanes.addAll([
      Offset(w * 0.20, h * 0.115),
      Offset(w * 0.36, h * 0.10),
      Offset(w * 0.52, h * 0.115),
    ]);
    _slings.clear();
    _slings.add(_Seg(Offset(w * 0.235, h * 0.72), Offset(w * 0.275, h * 0.85)));
    _slings.add(_Seg(Offset(w * 0.585, h * 0.72), Offset(w * 0.545, h * 0.85)));
    _flipLP = Offset(w * 0.315, h * 0.90);
    _flipRP = Offset(w * 0.505, h * 0.90);
    _resetBall();
  }

  void _resetBall() {
    _p = Offset((_divX + _rightX) / 2, _size.height * 0.88);
    _v = Offset.zero;
    _launched = false;
    _trail.clear();
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _over || _size == Size.zero) return;
    if (ModalRoute.of(context)?.isCurrent != true) {
      _last = elapsed;
      return;
    }
    final dt = min((elapsed - _last).inMicroseconds / 1e6, 0.033);
    _last = elapsed;
    _tGlobal += dt;
    _update(dt);
    setState(() {});
  }

  Offset _flipperTip(bool left, double t) {
    final piv = left ? _flipLP : _flipRP;
    final rest = left ? 0.5 : pi - 0.5; // down-out
    final act = left ? -0.5 : pi + 0.5; // up-in
    final a = rest + (act - rest) * t;
    return piv + Offset(cos(a), sin(a)) * _flipLen;
  }

  void _update(double dt) {
    _bannerT = max(0, _bannerT - dt);
    _nudgeCd = max(0, _nudgeCd - dt);
    // flipper animation
    _flipL += ((_holdL ? 1 : 0) - _flipL) * min(1, dt * 18);
    _flipR += ((_holdR ? 1 : 0) - _flipR) * min(1, dt * 18);
    // plunger charge
    if (_charging) {
      _power += _powerDir * dt * 1.6;
      if (_power >= 1) {
        _power = 1;
        _powerDir = -1;
      } else if (_power <= 0) {
        _power = 0;
        _powerDir = 1;
      }
    }
    if (!_launched) return;

    _v += Offset(0, 1050 * dt); // gravity
    // curve the ball out of the plunger lane at the top
    if (_p.dx > _divX && _p.dy < _size.height * 0.14) {
      _v += Offset(-3200 * dt, 0);
    }
    if (_v.distance > 1700) _v = _v / _v.distance * 1700;
    _p += _v * dt;
    _trail.add(_p);
    if (_trail.length > 14) _trail.removeAt(0);

    _collide(dt);

    // drain
    if (_p.dy > _size.height + 30) _loseBall();
  }

  double _segDist(Offset p, Offset a, Offset b, List<Offset> out) {
    final ab = b - a;
    final denom = ab.dx * ab.dx + ab.dy * ab.dy;
    var t = denom < 1e-6
        ? 0.0
        : ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / denom;
    t = t.clamp(0.0, 1.0);
    final c = a + ab * t;
    out[0] = c;
    return (p - c).distance;
  }

  void _reflect(Offset n, double restitution, [double boost = 0]) {
    final vn = _v.dx * n.dx + _v.dy * n.dy;
    if (vn < 0) {
      _v = _v - n * (vn * (1 + restitution));
      if (boost > 0 && _v.distance < boost) {
        _v = _v / max(_v.distance, 1) * boost;
      }
    }
  }

  void _collide(double dt) {
    final tmp = [Offset.zero];
    for (final s in _walls) {
      final d = _segDist(_p, s.a, s.b, tmp);
      if (d < _br) {
        var n = _p - tmp[0];
        if (n.distance < 0.001) n = const Offset(0, -1);
        n = n / n.distance;
        _p = tmp[0] + n * _br;
        _reflect(n, 0.55);
      }
    }
    // slingshots
    for (final s in _slings) {
      final d = _segDist(_p, s.a, s.b, tmp);
      if (d < _br + 4) {
        var n = _p - tmp[0];
        if (n.distance < 0.001) n = const Offset(0, -1);
        n = n / n.distance;
        _p = tmp[0] + n * (_br + 4);
        _reflect(n, 0.7, 500);
        _score += 10 * _mult;
        Sfx.tap();
      }
    }
    // flippers as segments
    for (final left in [true, false]) {
      final piv = left ? _flipLP : _flipRP;
      final tip = _flipperTip(left, left ? _flipL : _flipR);
      final d = _segDist(_p, piv, tip, tmp);
      if (d < _br + 3) {
        var n = _p - tmp[0];
        if (n.distance < 0.001) n = const Offset(0, -1);
        n = n / n.distance;
        if (n.dy > -0.2) n = Offset(n.dx, -0.6).normalize();
        _p = tmp[0] + n * (_br + 3);
        _reflect(n, 0.25);
      }
    }
    // bumpers
    for (final b in _bumpers) {
      b.flash = max(0, b.flash - dt * 4);
      b.cd = max(0, b.cd - dt);
      final d = (_p - b.p).distance;
      if (d < b.r + _br && b.cd <= 0) {
        b.cd = 0.09;
        b.flash = 1;
        var n = (_p - b.p) / max(d, 0.001);
        _p = b.p + n * (b.r + _br);
        _reflect(n, 0.9, 560);
        _score += 100 * _mult;
        Sfx.click();
      }
    }
    // rollover lanes
    for (var i = 0; i < _lanes.length; i++) {
      if (_lit.contains(i)) continue;
      if ((_p - _lanes[i]).distance < _size.width * 0.035 + _br) {
        _lit.add(i);
        _score += 50 * _mult;
        Sfx.tap();
        if (_lit.length == 3) {
          _lit.clear();
          _mult = min(5, _mult + 1);
          _score += 1000;
          _banner = 'MULTIPLIER x$_mult!';
          _bannerT = 1.6;
          Sfx.win();
        }
      }
    }
  }

  void _flipperDown(bool left) {
    if (left) {
      _holdL = true;
    } else {
      _holdR = true;
    }
    Sfx.tap();
    // kick the ball if it's in range
    final piv = left ? _flipLP : _flipRP;
    if ((_p - piv).distance < _size.width * 0.30 && _launched) {
      final cx = _size.width * 0.41;
      _v = Offset((cx - _p.dx).sign * 260, -1150);
      _trail.clear();
    }
  }

  void _nudge() {
    if (_nudgeCd > 0 || !_launched || _over) return;
    _nudgeCd = 0.8;
    _nudges.add(_tGlobal);
    _nudges.removeWhere((t) => _tGlobal - t > 4);
    Sfx.move();
    if (_nudges.length >= 3) {
      _nudges.clear();
      _banner = 'TILT! 😵';
      _bannerT = 1.8;
      _loseBall();
      return;
    }
    _v += Offset((_rng.nextDouble() - 0.5) * 560, -160);
  }

  void _loseBall() {
    _balls--;
    Sfx.lose();
    if (_balls <= 0) {
      _gameOver();
    } else {
      _banner = _balls == 1 ? 'LAST BALL!' : 'BALL $_balls';
      _bannerT = 1.4;
      _resetBall();
    }
  }

  Future<void> _gameOver() async {
    _over = true;
    _ticker.stop();
    final isBest = _score > _best;
    if (isBest) {
      _best = _score;
      final p = await SharedPreferences.getInstance();
      await p.setInt('pinball_best', _best);
    }
    widget.players.first.score = _score;
    widget.callbacks.refreshHud();
    widget.callbacks.finish(
      headline: 'You scored $_score!',
      subline: isBest ? '🔴 New table record!' : 'Best: $_best',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return Column(
      children: [
        _hud(t),
        Expanded(
          child: LayoutBuilder(builder: (ctx, c) {
            final ns = Size(c.maxWidth, c.maxHeight);
            if ((_size == Size.zero ||
                    (_size.width - ns.width).abs() > 1 ||
                    (_size.height - ns.height).abs() > 1) &&
                ns.width > 0) {
              _buildTable(ns);
            }
            return Container(
              decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(16)),
              child: CustomPaint(
                painter: _TablePainter(
                  state: this,
                  bg: t.surface,
                  wall: t.primary,
                  bumper: t.accent,
                  bumper2: t.secondary,
                  laneOn: t.accent,
                  laneOff: t.muted,
                  ball: t.text,
                  tick: _tGlobal,
                  banner: _bannerT > 0 ? _banner : '',
                ),
                child: const SizedBox.expand(),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        _controls(t),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _hud(GameTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(t, 'SCORE', '$_score'),
          _stat(t, 'BEST', '$_best'),
          _stat(t, 'MULT', 'x$_mult'),
          _stat(t, 'BALL', '${max(_balls, 0)}/3'),
        ],
      ),
    );
  }

  Widget _stat(GameTheme t, String l, String v) => Column(
        children: [
          Text(l,
              style: TextStyle(
                  color: t.muted, fontSize: 10, fontWeight: FontWeight.w700)),
          Text(v,
              style: TextStyle(
                  color: t.text, fontSize: 17, fontWeight: FontWeight.w800)),
        ],
      );

  Widget _holdButton(
      String label, GameTheme t, void Function() onDown, void Function() onUp,
      {double width = 92}) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: Container(
        width: width,
        height: 60,
        decoration: BoxDecoration(
          color: t.primary.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.primary, width: 2),
        ),
        child: Center(
            child: Text(label,
                style: TextStyle(
                    color: t.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15))),
      ),
    );
  }

  Widget _controls(GameTheme t) {
    return Column(
      children: [
        if (!_launched && !_over)
          GestureDetector(
            onTapDown: (_) {
              _charging = true;
              _power = 0;
              _powerDir = 1;
              Sfx.tap();
            },
            onTapUp: (_) {
              _charging = false;
              _launched = true;
              _v = Offset(0, -(700 + _power * 1500));
              _power = 0;
              Sfx.move();
            },
            onTapCancel: () => _charging = false,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: t.accent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.accent, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎯 HOLD TO PLUNGE',
                      style: TextStyle(
                          color: t.text, fontWeight: FontWeight.w800)),
                  if (_charging) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      child: LinearProgressIndicator(
                          value: _power,
                          backgroundColor:
                              t.muted.withValues(alpha: 0.3),
                          color: t.accent),
                    ),
                  ],
                ],
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _holdButton('◀ LEFT', t, () => _flipperDown(true),
                () => _holdL = false),
            GestureDetector(
              onTap: _nudge,
              child: Container(
                width: 64,
                height: 60,
                decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(18)),
                child: const Center(
                    child:
                        Text('📳', style: TextStyle(fontSize: 24))),
              ),
            ),
            _holdButton('RIGHT ▶', t, () => _flipperDown(false),
                () => _holdR = false),
          ],
        ),
      ],
    );
  }
}

extension _OffsetX on Offset {
  Offset normalize() {
    final d = distance;
    return d < 1e-6 ? this : this / d;
  }
}

class _TablePainter extends CustomPainter {
  final _PinballScreenState state;
  final Color bg, wall, bumper, bumper2, laneOn, laneOff, ball;
  final double tick;
  final String banner;

  _TablePainter({
    required this.state,
    required this.bg,
    required this.wall,
    required this.bumper,
    required this.bumper2,
    required this.laneOn,
    required this.laneOff,
    required this.ball,
    required this.tick,
    required this.banner,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = state;
    // lane divider glow
    final wallPaint = Paint()
      ..color = wall
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (final w in s._walls) {
      canvas.drawLine(w.a, w.b, wallPaint);
    }
    // slingshots
    for (final sl in s._slings) {
      canvas.drawLine(
          sl.a,
          sl.b,
          Paint()
            ..color = bumper2
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round);
    }
    // rollover lanes
    for (var i = 0; i < s._lanes.length; i++) {
      final lit = s._lit.contains(i);
      canvas.drawCircle(
          s._lanes[i],
          size.width * 0.035,
          Paint()
            ..color = (lit ? laneOn : laneOff).withValues(
                alpha: lit ? (0.6 + 0.4 * sin(tick * 6)) : 0.35));
    }
    // bumpers
    for (var i = 0; i < s._bumpers.length; i++) {
      final b = s._bumpers[i];
      final c = (i % 2 == 0 ? bumper : bumper2)
          .withValues(alpha: 0.55 + 0.45 * b.flash);
      canvas.drawCircle(b.p, b.r, Paint()..color = c);
      canvas.drawCircle(
          b.p,
          b.r * 0.45,
          Paint()..color = bg.withValues(alpha: 0.85));
    }
    // flippers
    for (final left in [true, false]) {
      final piv = left ? s._flipLP : s._flipRP;
      final tip = s._flipperTip(left, left ? s._flipL : s._flipR);
      canvas.drawLine(
          piv,
          tip,
          Paint()
            ..color = bumper
            ..strokeWidth = 13
            ..strokeCap = StrokeCap.round);
      canvas.drawCircle(piv, 8, Paint()..color = wall);
    }
    // ball trail + ball
    for (var i = 0; i < s._trail.length; i++) {
      canvas.drawCircle(
          s._trail[i],
          s._br * (i / s._trail.length) * 0.8,
          Paint()
            ..color = ball.withValues(
                alpha: 0.25 * i / s._trail.length));
    }
    canvas.drawCircle(s._p, s._br, Paint()..color = ball);
    canvas.drawCircle(
        s._p - const Offset(3, 3),
        s._br * 0.35,
        Paint()..color = bg.withValues(alpha: 0.7));
    // banner
    if (banner.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
            text: banner,
            style: TextStyle(
                color: ball, fontSize: 30, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset((size.width - tp.width) / 2,
              size.height * 0.42));
    }
  }

  @override
  bool shouldRepaint(covariant _TablePainter old) => true;
}
