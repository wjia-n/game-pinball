# Pinball — Rules

The authoritative rules for Pinball (com.gameswajiha.pinball). The engine
enforces this document; if implementation conflicts with it, the
implementation is fixed.

## 1. Objective

Score as many points as possible by keeping the steel ball in play on a
classic wooden pinball table: hit pop bumpers, slingshots and rollover
lanes with the flippers, build the score multiplier, and avoid draining
the ball past the flippers.

## 2. Setup

- The table has a plunger lane on the right, 3 pop bumpers up top,
  3 rollover lanes, 2 slingshots, and 2 flippers at the bottom.
- Score Attack: 3 balls per game (5 for Pro). Endless: infinite balls.
  Time Rush (Pro): 3-minute countdown, instant re-serves.
- Difficulty: Gentle (slow ball, forgiving tilt — 4 nudges), Parlor
  (classic pace, 3 nudges), Lightning / Pro (fast ball, 2 nudges).

## 3. Turn order

Pinball is single-player. Each ball is one turn: plunge → play →
drain → next ball served. Ball locks persist across the serves within one
turn; draining releases them.

## 4. Legal moves

- Hold the plunger button to charge, release to launch the ball.
- Tap/hold the left/right flipper buttons to swing the flippers.
- Tap the nudge button to shove the table (limited — see Tilt).
- Pause any time; resume, restart, or quit from the pause panel.

## 5. Illegal moves

- The plunger can only be charged while a ball is sitting in the lane
  (aim phase). Releasing with no charge does nothing.
- Flippers do not fire during the tilt penalty.
- Nudging more often than once per 0.8s is ignored.

## 6. Captures

Not applicable — pinball has no captures.

## 7. Special rules

- **Multiplier:** lighting all 3 rollover lanes raises the score
  multiplier by 1 (max x5) and banks +1000. Lanes then reset.
- **Ball lock & multiball:** lighting all 3 lanes while the multiplier is
  already maxed (x5) locks the ball on the lock ramp (+1000) and serves a
  fresh ball. A second lock releases both locked balls onto the field
  alongside the live ball: 3 balls at once, all scoring x2 (MULTIBALL).
  Draining a ball during multiball only loses that ball; when one ball
  remains the run scores a +5000 JACKPOT and multiball ends. Losing all
  balls drains the turn. Pending locks are released if the ball drains
  (e.g. via tilt) before multiball starts.
- **Skill shot:** a full-power (85%+) plunge that rolls through a top
  lane scores +2500 "SKILL SHOT".
- **Tilt:** nudging too often within 4 seconds (limit set by difficulty)
  triggers TILT — flippers die and the ball drains, losing the ball.
- **Ball rescue:** if the ball wedges motionless for 2.5s, the table
  gives it a free kick (+100, "Ball rescued") rather than losing it.
- **Out-of-bounds:** a ball that ever escapes the table is recovered as
  an explicit, announced drain — never lost silently.

## 8. Scoring

- Pop bumper: 100 × multiplier (each bumper has its own ding pitch).
- Slingshot: 25 × multiplier.
- Rollover lane: 50 × multiplier.
- Lane set complete: +1000 and multiplier +1.
- Skill shot: +2500.
- Ball rescue: +100.
- Ball lock: +1000 per lock.
- Multiball: all scoring x2 while active; multiball jackpot +5000 when
  the last two balls become one.

## 9. Winning conditions

Pinball is a score-attack game: the run ends when the balls (or the
clock, in Time Rush) run out. Beating your saved best is a new record.

## 10. Draw conditions

Not applicable.

## 11. AI strategy

Not applicable — single-player vs. the table.

## 12. Edge cases

- Ball drains during tilt penalty → the tilt drain counts as the ball
  lost; no double penalty.
- Time Rush: drains re-serve instantly (short pause); the clock never
  pauses for drains.
- Endless: drains serve a new ball; the run ends only via pause → Menu
  (score is banked) or the device back button.
- App backgrounded mid-ball: the engine freezes and resumes exactly.
- Ball resting against a flipper with the flipper held: no phantom
  kicks — kicks only fire on active flipper contact.

## 13. Test cases

1. Fresh launch → company splash → menu; menu music starts, never silent.
2. Start Score Attack → aim phase shows plunger + power gauge.
3. Full-power plunge → ball launches; top-lane rollover → SKILL SHOT +2500.
4. Hit each bumper → distinct ding pitch, +100×mult, visible flash.
5. Light all 3 lanes → multiplier x2, +1000, bell fanfare.
6. Drain the ball → explicit drain sound + animation → next ball served
   with banner ("BALL 2" / "LAST BALL!").
7. Drain the last ball → game-over panel with score, best, initials.
8. New record → win fanfare + "NEW RECORD!" + review prompt.
9. Nudge 3× quickly (Parlor) → TILT, flippers dead, ball drains.
10. Leave ball wedged (e.g. behind a bumper) → "Ball rescued!" kick.
11. Time Rush → 3:00 countdown, drains re-serve, ends at 0:00.
12. Toggle music/sfx/volume in Settings → applies immediately, persists.
13. Rename profile + initials → persists across restarts; shows on
    game-over panel.
14. Pick Pro theme/ball style as free user → routed to Pro screen, locked.
15. Pro screen with no Play products configured → honest "available after
    store setup", no fake buy button.
16. Complete the lanes at x5 → "BALL 1 LOCKED!" and a fresh ball served;
    complete again → MULTIBALL with 3 balls and x2 scoring.
17. Drain 2 balls during multiball → "MULTIBALL COMPLETE!" + JACKPOT +5000,
    play continues with the last ball.
18. Drain all balls during multiball → explicit drain → next ball served.
19. Tilt during multiball → flippers dead, all balls fall, locks released,
    the turn is lost once (no double penalty).
