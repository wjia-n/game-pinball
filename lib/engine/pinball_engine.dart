import 'dart:math';

/// Pinball engine: owns ALL game state, phases, timers and the watchdog.
/// The UI only renders and forwards input — it never owns game state.
///
/// Design rule: no stuck states by construction.
/// - Every phase has a time-based exit handled inside [step], never by a UI
///   timer. If the UI stops calling step (app backgrounded), [paused] freezes
///   everything safely.
/// - The watchdog runs every step per ball: a ball that leaves the table
///   bounds, gets wedged motionless, or sits in a phase too long is
///   recovered explicitly — a drain is always announced, never silent.
/// - Drains are explicit events ([PinballPhase.draining]), never just a
///   missing ball.
///
/// Multiball: completing the rollover lanes while the multiplier is already
/// maxed (x5) locks the ball. Two locks release both locked balls onto the
/// field alongside the live ball — 3 balls, x2 scoring — until only one
/// remains (jackpot +5000) or all drain.

enum PinballPhase {
  aim, // ball sits in the plunger lane, waiting to plunge
  inPlay, // ball is live on the table
  draining, // ball fell past the flippers — explicit drain animation
  serving, // short pause before the next ball is served
  tilt, // tilt penalty — flippers dead, ball drains
  gameOver, // run finished
}

enum PinballModeId { scoreAttack, endless, timeRush }

enum PinballDifficultyId { gentle, parlor, lightning }

/// Sound IDs the UI maps to PinballAudio calls.
class PinballSfx {
  static const flipper = 'flipper';
  static const bumper0 = 'bumper0';
  static const bumper1 = 'bumper1';
  static const bumper2 = 'bumper2';
  static const sling = 'sling';
  static const rollover = 'rollover';
  static const bell = 'bell';
  static const multUp = 'multUp';
  static const plunger = 'plunger';
  static const launch = 'launch';
  static const drain = 'drain';
  static const tilt = 'tilt';
  static const rescue = 'rollover';
}

class ScorePopup {
  final String text;
  final double x; // table units, 0..1
  final double y; // table units, 0..aspect
  double ttl;
  ScorePopup(this.text, this.x, this.y, this.ttl);
}

/// One live ball. The engine supports several at once (multiball); the UI
/// renders every ball in [balls].
class PinballBall {
  double x, y, vx, vy;
  final List<Point<double>> trail = [];
  // Watchdog state (per ball).
  double stillT = 0;
  double oobT = 0;
  double lastX = 0, lastY = 0;
  PinballBall(this.x, this.y, this.vx, this.vy);
}

class _Seg {
  final double ax, ay, bx, by;
  _Seg(this.ax, this.ay, this.bx, this.by);
}

class _Bumper {
  final double x, y, r;
  double flash = 0;
  double cd = 0;
  _Bumper(this.x, this.y, this.r);
}

class PinballEngine {
  final PinballModeId mode;
  final PinballDifficultyId difficulty;
  final int ballsPerGame;
  final int timeRushSeconds;

  // Difficulty tuning: speed/complexity scaling.
  late final double gravity;
  late final double maxSpeed;
  late final double bumperBoost;
  late final int tiltLimit;

  PinballPhase phase = PinballPhase.aim;
  bool paused = false;

  int score = 0;
  int mult = 1;
  int ballsLeft = 3;
  double timeLeft = 0; // time-rush countdown

  // Multiball state.
  int lockedBalls = 0;
  bool multiballActive = false;
  bool get inMultiball => multiballActive;
  int get lockCount => lockedBalls;

  // Table geometry (normalized 0..1, scaled by table size).
  final List<_Seg> _walls = [];
  final List<_Bumper> _bumpers = [];
  final List<_Seg> _slings = [];
  final List<Point<double>> _lanes = [];
  double _flipLPx = 0, _flipLPy = 0, _flipRPx = 0, _flipRPy = 0;
  double _flipLen = 0, _ballR = 0;
  double _plungeX = 0, _serveY = 0, _drainY = 0;
  double _tableW = 1;
  double _plungeTopY = 0.28;

  // Live balls (table units). Usually one; three during multiball.
  final List<PinballBall> balls = [];
  PinballBall get _primary => balls.first;

  // Flippers: 0 rest .. 1 fully active.
  double flipL = 0, flipR = 0;
  bool _holdL = false, _holdR = false;

  // Plunger.
  bool charging = false;
  double power = 0;
  double _powerDir = 1;

  // Phase timers.
  double _phaseT = 0;

  // Scoring helpers.
  final Set<int> litLanes = {};
  final List<ScorePopup> popups = [];
  String banner = '';
  double bannerT = 0;

  // Tilt.
  final List<double> _nudges = [];
  double _nudgeCd = 0;
  double _tGlobal = 0;

  // Skill shot: full-power plunge bonus while ball is still up top.
  bool _skillShotLive = false;
  double _skillT = 0;

  // Event callbacks wired by the UI.
  void Function(String sfxId)? onSfx;
  void Function(int finalScore)? onGameOver;

  bool _gameOverFired = false;

  PinballEngine({
    required this.mode,
    required this.difficulty,
    required this.ballsPerGame,
    required this.timeRushSeconds,
  }) {
    // Difficulty tuning: speed/complexity scaling. All physics runs in
    // "table units" where 1 unit = table width, so feel is identical on
    // every screen size.
    switch (difficulty) {
      case PinballDifficultyId.gentle:
        gravity = 2.2;
        maxSpeed = 3.4;
        bumperBoost = 1.2;
        tiltLimit = 4;
      case PinballDifficultyId.parlor:
        gravity = 2.625;
        maxSpeed = 4.25;
        bumperBoost = 1.4;
        tiltLimit = 3;
      case PinballDifficultyId.lightning:
        gravity = 3.4;
        maxSpeed = 5.2;
        bumperBoost = 1.75;
        tiltLimit = 2;
    }
    ballsLeft = mode == PinballModeId.endless ? 999999 : ballsPerGame;
    timeLeft = timeRushSeconds.toDouble();
  }

  // ------------------------------------------------------------ table build
  /// Builds geometry in table units: x in 0..1, y in 0..[h/w].
  void buildTable(double wPx, double hPx) {
    _tableW = wPx;
    final yS = hPx / wPx; // y scale: table units per normalized y
    final y = (double f) => f * yS;
    final leftX = 0.05, divX = 0.80, rightX = 0.95, topY = y(0.03);
    _ballR = 0.024;
    _flipLen = 0.15;
    _walls.clear();
    _walls.add(_Seg(leftX, y(0.12), leftX, y(0.84)));
    _walls.add(_Seg(leftX, y(0.84), 0.30, y(0.985)));
    _walls.add(_Seg(divX, topY, divX, y(0.55)));
    _walls.add(_Seg(rightX, topY, rightX, y(0.985)));
    _walls.add(_Seg(divX, y(0.985), rightX, y(0.985)));
    _walls.add(_Seg(divX, y(0.55), 0.60, y(0.90)));
    // Top arc.
    final cx = (leftX + divX) / 2, cy = y(0.12), r = (divX - leftX) / 2;
    double px = cx - r, py = cy;
    for (var i = 1; i <= 8; i++) {
      final a = pi + i / 8 * pi;
      final qx = cx + cos(a) * r, qy = cy + sin(a) * r;
      _walls.add(_Seg(px, py, qx, qy));
      px = qx;
      py = qy;
    }
    _bumpers.clear();
    _bumpers.addAll([
      _Bumper(0.36, y(0.24), 0.055),
      _Bumper(0.55, y(0.20), 0.055),
      _Bumper(0.45, y(0.35), 0.055),
    ]);
    _lanes.clear();
    _lanes.addAll([
      Point(0.20, y(0.115)),
      Point(0.36, y(0.10)),
      Point(0.52, y(0.115)),
    ]);
    _slings.clear();
    _slings.add(_Seg(0.235, y(0.72), 0.275, y(0.85)));
    _slings.add(_Seg(0.585, y(0.72), 0.545, y(0.85)));
    _flipLPx = 0.315;
    _flipLPy = y(0.90);
    _flipRPx = 0.505;
    _flipRPy = y(0.90);
    _plungeX = (divX + rightX) / 2;
    _serveY = y(0.88);
    _drainY = y(0.985);
    _plungeTopY = y(0.14);
    _serveBall();
  }

  void _serveBall() {
    balls.clear();
    balls.add(PinballBall(_plungeX, _serveY, 0, 0));
    charging = false;
    power = 0;
    _powerDir = 1;
    litLanes.clear();
    flipL = 0;
    flipR = 0;
    _holdL = false;
    _holdR = false;
    phase = PinballPhase.aim;
    _phaseT = 0;
  }

  // ---------------------------------------------------------------- inputs
  void flipperDown(bool left) {
    if (phase == PinballPhase.tilt || phase == PinballPhase.gameOver) return;
    if (left) {
      _holdL = true;
    } else {
      _holdR = true;
    }
    onSfx?.call(PinballSfx.flipper);
  }

  void flipperUp(bool left) {
    if (left) {
      _holdL = false;
    } else {
      _holdR = false;
    }
  }

  void startCharge() {
    if (phase != PinballPhase.aim) return;
    charging = true;
    power = 0;
    _powerDir = 1;
    onSfx?.call(PinballSfx.plunger);
  }

  void releasePlunger() {
    if (phase != PinballPhase.aim || !charging || balls.isEmpty) return;
    charging = false;
    // Full-power plunge arms the skill shot.
    _skillShotLive = power >= 0.85;
    _skillT = 5.0;
    final b = _primary;
    b.vy = -(1.75 + power * 3.75);
    b.vx = 0;
    b.stillT = 0;
    b.oobT = 0;
    power = 0;
    phase = PinballPhase.inPlay;
    _phaseT = 0;
    onSfx?.call(PinballSfx.launch);
  }

  void cancelCharge() {
    charging = false;
    power = 0;
  }

  void nudge() {
    if (phase != PinballPhase.inPlay || _nudgeCd > 0) return;
    _nudgeCd = 0.8;
    _nudges.add(_tGlobal);
    _nudges.removeWhere((t) => _tGlobal - t > 4);
    if (_nudges.length >= tiltLimit) {
      _nudges.clear();
      _tilt();
      return;
    }
    // A real table nudge: small random horizontal shove, slight lift,
    // applied to every live ball.
    for (final b in balls) {
      b.vx += (Random().nextDouble() - 0.5) * 1.4;
      b.vy -= 0.40;
    }
  }

  void _tilt() {
    phase = PinballPhase.tilt;
    _phaseT = 0;
    _holdL = false;
    _holdR = false;
    banner = 'TILT!';
    bannerT = 1.8;
    onSfx?.call(PinballSfx.tilt);
  }

  void quitToMenu() {
    // Endless mode: the player ends the run explicitly.
    if (phase == PinballPhase.gameOver) return;
    _finishGame();
  }

  // ------------------------------------------------------------------ step
  /// Advance the simulation. The engine owns all phase timing; the UI just
  /// calls this every frame with real dt.
  void step(double dt) {
    if (paused || _tableW <= 0) return;
    dt = dt.clamp(0.0, 0.05).toDouble();
    _tGlobal += dt;
    _phaseT += dt;
    bannerT = max(0.0, bannerT - dt);
    _nudgeCd = max(0.0, _nudgeCd - dt);
    for (final p in popups) {
      p.ttl -= dt;
    }
    popups.removeWhere((p) => p.ttl <= 0);

    // Flipper animation (fast in, slightly slower out — like a solenoid).
    final targetL = (_holdL && phase != PinballPhase.tilt) ? 1.0 : 0.0;
    final targetR = (_holdR && phase != PinballPhase.tilt) ? 1.0 : 0.0;
    flipL += (targetL - flipL) * min(1.0, dt * (targetL > flipL ? 26 : 14));
    flipR += (targetR - flipR) * min(1.0, dt * (targetR > flipR ? 26 : 14));

    // Plunger charge oscillation.
    if (charging && phase == PinballPhase.aim) {
      power += _powerDir * dt * 1.6;
      if (power >= 1) {
        power = 1;
        _powerDir = -1;
      } else if (power <= 0) {
        power = 0;
        _powerDir = 1;
      }
    }

    switch (phase) {
      case PinballPhase.aim:
        break;
      case PinballPhase.inPlay:
        _stepBalls(dt);
        if (mode == PinballModeId.timeRush) {
          timeLeft -= dt;
          if (timeLeft <= 0) {
            timeLeft = 0;
            _finishGame();
          }
        }
      case PinballPhase.draining:
        // Ball(s) keep falling with gravity for the visual, then next serve.
        for (final b in balls) {
          b.vy += gravity * dt;
          b.y += b.vy * dt;
        }
        if (_phaseT > 1.0) _nextBallOrGameOver();
      case PinballPhase.serving:
        if (_phaseT > 1.1) _serveBall();
      case PinballPhase.tilt:
        // Flippers dead; balls fall straight through.
        for (final b in balls) {
          b.vy += gravity * dt;
          b.x += b.vx * dt;
          b.y += b.vy * dt;
        }
        if (_phaseT > 1.4) _loseBall();
      case PinballPhase.gameOver:
        break;
    }

    // Bumper flash decay.
    for (final b in _bumpers) {
      b.flash = max(0.0, b.flash - dt * 4);
      b.cd = max(0.0, b.cd - dt);
    }
    // Skill-shot window decay.
    if (_skillShotLive) {
      _skillT -= dt;
      if (_skillT <= 0) _skillShotLive = false;
    }
  }

  // --------------------------------------------------------------- watchdog
  /// Runs every step per ball during inPlay. Recovers anything the physics
  /// could not settle: out-of-bounds balls, wedged motionless balls.
  /// Nothing is ever lost silently.
  void _watchdog(double dt, PinballBall b) {
    // 1. Out of bounds: the ball must never leave the table region.
    final oob = b.x < -0.15 || b.x > 1.15 || b.y < -0.3 || b.y > 4.0;
    if (oob) {
      b.oobT += dt;
      if (b.oobT > 0.25) {
        b.oobT = 0;
        banner = 'Ball escaped the table!';
        bannerT = 1.4;
        _onBallDrained(b);
        return;
      }
    } else {
      b.oobT = 0;
    }

    // 2. Wedged ball: no meaningful movement for a while -> rescue kick.
    final moved = (b.x - b.lastX).abs() + (b.y - b.lastY).abs();
    b.lastX = b.x;
    b.lastY = b.y;
    final speed = sqrt(b.vx * b.vx + b.vy * b.vy);
    if (speed < 0.06 && moved < 0.002) {
      b.stillT += dt;
      if (b.stillT > 2.5) {
        b.stillT = 0;
        // Rescue: pop the ball upward with a random sideways nudge.
        b.vx = (Random().nextDouble() - 0.5) * 0.9;
        b.vy = -1.6;
        banner = 'Ball rescued!';
        bannerT = 1.2;
        _addScore(100, (t) => 'RESCUE +$t');
        onSfx?.call(PinballSfx.rescue);
      }
    } else {
      b.stillT = 0;
    }

    // 3. Phase sanity: inPlay should never persist without ball motion
    //    events; covered by (2). Draining/serving/tilt have hard timeouts
    //    in step() above.
  }

  // -------------------------------------------------------------- physics
  void _stepBalls(double dt) {
    // Substep so fast balls can't tunnel through thin walls.
    const sub = 3;
    final h = dt / sub;
    for (final b in List.of(balls)) {
      for (var i = 0; i < sub; i++) {
        b.vy += gravity * h;
        // Curve the ball out of the plunger lane at the top.
        if (b.x > 0.80 && b.y < _plungeTopY) b.vx -= 8.0 * h;
        final sp = sqrt(b.vx * b.vx + b.vy * b.vy);
        if (sp > maxSpeed) {
          b.vx = b.vx / sp * maxSpeed;
          b.vy = b.vy / sp * maxSpeed;
        }
        b.x += b.vx * h;
        b.y += b.vy * h;
        _collide(h, b);
      }
      b.trail.add(Point(b.x, b.y));
      if (b.trail.length > 12) b.trail.removeAt(0);
    }
    // Drain check per ball (snapshot: _onBallDrained mutates the list).
    for (final b in List.of(balls)) {
      if (phase == PinballPhase.inPlay && b.y > _drainY + 0.02) {
        _onBallDrained(b);
      }
    }
    for (final b in List.of(balls)) {
      if (phase == PinballPhase.inPlay) _watchdog(dt, b);
    }
  }

  double _segClosest(double px, double py, _Seg s,
      {required List<double> out}) {
    final abx = s.bx - s.ax, aby = s.by - s.ay;
    final denom = abx * abx + aby * aby;
    var t = denom < 1e-9
        ? 0.0
        : ((px - s.ax) * abx + (py - s.ay) * aby) / denom;
    t = t.clamp(0.0, 1.0).toDouble();
    final cx = s.ax + abx * t, cy = s.ay + aby * t;
    out[0] = cx;
    out[1] = cy;
    return sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
  }

  void _reflect(double nx, double ny, double restitution, PinballBall b,
      [double boost = 0]) {
    final vn = b.vx * nx + b.vy * ny;
    if (vn < 0) {
      b.vx -= nx * vn * (1 + restitution);
      b.vy -= ny * vn * (1 + restitution);
      if (boost > 0) {
        final sp = sqrt(b.vx * b.vx + b.vy * b.vy);
        if (sp < boost && sp > 1e-6) {
          b.vx = b.vx / sp * boost;
          b.vy = b.vy / sp * boost;
        }
      }
    }
  }

  void _collide(double dt, PinballBall b) {
    final tmp = [0.0, 0.0];
    final r = _ballR;
    // Walls.
    for (final s in _walls) {
      final d = _segClosest(b.x, b.y, s, out: tmp);
      if (d < r) {
        var nx = b.x - tmp[0], ny = b.y - tmp[1];
        var len = sqrt(nx * nx + ny * ny);
        if (len < 1e-6) {
          nx = 0;
          ny = -1;
          len = 1;
        }
        nx /= len;
        ny /= len;
        b.x = tmp[0] + nx * r;
        b.y = tmp[1] + ny * r;
        _reflect(nx, ny, 0.55, b);
      }
    }
    // Slingshots.
    for (final s in _slings) {
      final d = _segClosest(b.x, b.y, s, out: tmp);
      if (d < r + 0.008) {
        var nx = b.x - tmp[0], ny = b.y - tmp[1];
        var len = sqrt(nx * nx + ny * ny);
        if (len < 1e-6) {
          nx = 0;
          ny = -1;
          len = 1;
        }
        nx /= len;
        ny /= len;
        b.x = tmp[0] + nx * (r + 0.008);
        b.y = tmp[1] + ny * (r + 0.008);
        _reflect(nx, ny, 0.7, b, 1.25);
        _addScore(25 * mult, (t) => '+$t');
        onSfx?.call(PinballSfx.sling);
      }
    }
    // Flippers as animated segments with real kick physics.
    _flipperCollide(true, tmp, b);
    _flipperCollide(false, tmp, b);
    // Bumpers.
    for (var i = 0; i < _bumpers.length; i++) {
      final bu = _bumpers[i];
      final dx = b.x - bu.x, dy = b.y - bu.y;
      final d = sqrt(dx * dx + dy * dy);
      if (d < bu.r + r && bu.cd <= 0) {
        bu.cd = 0.09;
        bu.flash = 1;
        var nx = dx, ny = dy;
        var len = d;
        if (len < 1e-6) {
          nx = 0;
          ny = -1;
          len = 1;
        }
        nx /= len;
        ny /= len;
        b.x = bu.x + nx * (bu.r + r);
        b.y = bu.y + ny * (bu.r + r);
        _reflect(nx, ny, 0.9, b, bumperBoost);
        _addScore(100 * mult, (t) => '+$t');
        onSfx?.call(switch (i) {
          0 => PinballSfx.bumper0,
          1 => PinballSfx.bumper1,
          _ => PinballSfx.bumper2,
        });
      }
    }
    // Rollover lanes.
    for (var i = 0; i < _lanes.length; i++) {
      if (litLanes.contains(i)) continue;
      final l = _lanes[i];
      final d = sqrt((b.x - l.x) * (b.x - l.x) + (b.y - l.y) * (b.y - l.y));
      if (d < 0.035 + r) {
        litLanes.add(i);
        _addScore(50 * mult, (t) => '+$t');
        onSfx?.call(PinballSfx.rollover);
        if (_skillShotLive && balls.isNotEmpty && _primary.y < _plungeTopY + 0.2) {
          _skillShotLive = false;
          _addScore(2500, (t) => 'SKILL SHOT +$t!');
          banner = 'SKILL SHOT!';
          bannerT = 1.4;
          onSfx?.call(PinballSfx.bell);
        }
        if (litLanes.length == 3) {
          _onLaneSetComplete();
        }
      }
    }
  }

  /// All 3 rollover lanes lit: multiplier up (max x5), then ball locks,
  /// then multiball at 2 locks.
  void _onLaneSetComplete() {
    litLanes.clear();
    if (mult < 5) {
      mult++;
      _addScore(1000, (t) => '+$t');
      banner = 'MULTIPLIER x$mult!';
      bannerT = 1.6;
      onSfx?.call(PinballSfx.bell);
      onSfx?.call(PinballSfx.multUp);
      return;
    }
    if (!multiballActive && lockedBalls < 2) {
      lockedBalls++;
      _addScore(1000, (t) => '+$t');
      if (lockedBalls >= 2) {
        _startMultiball();
      } else {
        banner = 'BALL $lockedBalls LOCKED!';
        bannerT = 1.6;
        onSfx?.call(PinballSfx.bell);
        // Park the live ball on the lock ramp and serve a fresh one.
        if (balls.isNotEmpty) balls.removeAt(0);
        phase = PinballPhase.serving;
        _phaseT = 0.5; // shorter pause keeps the flow fast
      }
      return;
    }
    // Multiball already running or locks full: just bank the points.
    _addScore(1000, (t) => '+$t');
    onSfx?.call(PinballSfx.bell);
  }

  void _startMultiball() {
    lockedBalls = 0;
    multiballActive = true;
    // Release the two locked balls from the plunger lane with force.
    for (var i = 0; i < 2; i++) {
      balls.add(PinballBall(
        _plungeX,
        _serveY - i * 0.06,
        i == 0 ? -0.7 : 0.7,
        -(2.6 + i * 0.5),
      ));
    }
    banner = 'MULTIBALL!  x2 SCORING';
    bannerT = 2.2;
    onSfx?.call(PinballSfx.bell);
    onSfx?.call(PinballSfx.multUp);
  }

  void _flipperCollide(bool left, List<double> tmp, PinballBall b) {
    final t = left ? flipL : flipR;
    final pivX = left ? _flipLPx : _flipRPx;
    final pivY = left ? _flipLPy : _flipRPy;
    final tip = _flipperTip(left, t);
    final seg = _Seg(pivX, pivY, tip.x, tip.y);
    final d = _segClosest(b.x, b.y, seg, out: tmp);
    final r = _ballR;
    if (d >= r + 0.006) return;
    var nx = b.x - tmp[0], ny = b.y - tmp[1];
    var len = sqrt(nx * nx + ny * ny);
    if (len < 1e-6) {
      nx = 0;
      ny = -1;
      len = 1;
    }
    nx /= len;
    ny /= len;
    // Never let the normal point downward — the flipper always bats up.
    if (ny > -0.25) {
      final inv = 1 / sqrt(nx * nx + 0.6 * 0.6 + 1e-9);
      nx *= inv;
      ny = -0.6 * inv;
      len = 1;
    }
    b.x = tmp[0] + nx * (r + 0.006);
    b.y = tmp[1] + ny * (r + 0.006);
    final active = t > 0.45;
    if (active) {
      // Real kick: reflect off the moving bat and add bat energy.
      // Hitting near the tip sends the ball wider; near the pivot, straighter.
      final along = ((b.x - pivX) * (tip.x - pivX) +
              (b.y - pivY) * (tip.y - pivY)) /
          max(_flipLen * _flipLen, 1e-6);
      final dirSign = left ? 1.0 : -1.0;
      final alongC = along.clamp(0.0, 1.0).toDouble();
      _reflect(nx, ny, 0.35, b, 1.6 + 0.9 * alongC);
      b.vx += dirSign * 0.7 * alongC;
      b.vy = min(b.vy, -2.6);
    } else {
      _reflect(nx, ny, 0.25, b);
    }
  }

  Point<double> _flipperTip(bool left, double t) {
    final pivX = left ? _flipLPx : _flipRPx;
    final pivY = left ? _flipLPy : _flipRPy;
    final rest = left ? 0.5 : pi - 0.5; // down-out
    final act = left ? -0.5 : pi + 0.5; // up-in
    final a = rest + (act - rest) * t;
    return Point(pivX + cos(a) * _flipLen, pivY + sin(a) * _flipLen);
  }

  // ---------------------------------------------------------------- scoring
  /// Banks points. During multiball everything scores x2.
  void _addScore(int basePoints, String Function(int total) label) {
    final total = basePoints * (multiballActive ? 2 : 1);
    score += total;
    double px = 0.5, py = 1.0;
    if (balls.isNotEmpty) {
      px = _primary.x.clamp(0.0, 1.0).toDouble();
      py = _primary.y.clamp(0.0, 4.0).toDouble();
    }
    popups.add(ScorePopup(label(total), px, py, 1.0));
    if (popups.length > 8) popups.removeAt(0);
  }

  // ----------------------------------------------------------------- drain
  /// One ball left the table. During multiball the game continues with the
  /// remaining balls; otherwise this becomes the explicit drain event.
  void _onBallDrained(PinballBall b) {
    if (multiballActive) {
      balls.remove(b);
      onSfx?.call(PinballSfx.drain);
      if (balls.isEmpty) {
        _beginDrain();
      } else if (balls.length == 1) {
        multiballActive = false;
        banner = 'MULTIBALL COMPLETE!';
        bannerT = 1.8;
        _addScore(5000, (t) => 'JACKPOT +$t');
        onSfx?.call(PinballSfx.bell);
      } else {
        banner = 'BALL DRAINED — ${balls.length} LEFT';
        bannerT = 1.2;
      }
      return;
    }
    _beginDrain();
  }

  void _beginDrain() {
    if (phase != PinballPhase.inPlay) return;
    phase = PinballPhase.draining;
    _phaseT = 0;
    _holdL = false;
    _holdR = false;
    charging = false;
    onSfx?.call(PinballSfx.drain);
  }

  void _loseBall() {
    lockedBalls = 0; // any pending locks are released with the ball
    if (mode == PinballModeId.endless) {
      banner = 'Ball drained — new ball!';
      bannerT = 1.2;
      phase = PinballPhase.serving;
      _phaseT = 0;
      return;
    }
    ballsLeft = max(0, ballsLeft - 1);
    if (ballsLeft <= 0) {
      _finishGame();
    } else {
      banner = ballsLeft == 1 ? 'LAST BALL!' : 'BALL $ballsLeft';
      bannerT = 1.4;
      phase = PinballPhase.serving;
      _phaseT = 0;
    }
  }

  void _nextBallOrGameOver() {
    if (phase == PinballPhase.gameOver) return;
    if (mode == PinballModeId.timeRush) {
      // Time rush: drains cost nothing but time — serve again instantly.
      phase = PinballPhase.serving;
      _phaseT = 0.8; // shorter pause keeps the rush feeling fast
      return;
    }
    _loseBall();
  }

  void _finishGame() {
    if (_gameOverFired) return;
    _gameOverFired = true;
    phase = PinballPhase.gameOver;
    _phaseT = 0;
    _holdL = false;
    _holdR = false;
    multiballActive = false;
    lockedBalls = 0;
    onGameOver?.call(score);
  }

  // ------------------------------------------------------------- UI helpers
  Point<double> flipperTipPublic(bool left) =>
      _flipperTip(left, left ? flipL : flipR);
  double get flipPivotLX => _flipLPx;
  double get flipPivotLY => _flipLPy;
  double get flipPivotRX => _flipRPx;
  double get flipPivotRY => _flipRPy;
  List<Point<double>> get lanePoints => _lanes;
  List<_Bumper> get bumpers => _bumpers;
  List<_Seg> get walls => _walls;
  List<_Seg> get slings => _slings;
  double get ballRadius => _ballR;
  double get serveBallY => _serveY;
  double get plungeLaneX => _plungeX;
  bool get ballVisible => balls.isNotEmpty && phase != PinballPhase.gameOver;
}
