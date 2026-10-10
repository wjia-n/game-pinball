import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/iap_service.dart';
import '../theme/pinball_themes.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import 'style_picker_screen.dart';

/// Main menu: mode + difficulty select, profile, launch the table.
class MenuScreen extends StatefulWidget {
  final PinballAudio audio;
  final PinballSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final PinballStore _store;

  @override
  void initState() {
    super.initState();
    _store = PinballStore();
    _store.init();
    widget.audio.startMenuMusic();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  
  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _play() {
    widget.audio.gameStart();
    widget.audio.startGameMusic();
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        audio: widget.audio,
        settings: widget.settings,
      ),
    ))
        .then((_) {
      // App-scoped music: back to the menu track on return.
      if (mounted) widget.audio.startMenuMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final t = s.theme;
    return Scaffold(
      backgroundColor: const Color(0xFF171008),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.woodDark, const Color(0xFF0E0906)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Share',
                    icon: Icon(Icons.share, color: t.ivory),
                    onPressed: () {
                      widget.audio.click();
                      Share.share(
                        'I\'m playing Pinball by WAJIHA — classic arcade pinball with real wooden tables! https://play.google.com/store/apps/details?id=com.gameswajiha.pinball',
                        subject: 'Pinball by WAJIHA',
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Rate',
                    icon: Icon(Icons.star_outline, color: t.ivory),
                    onPressed: () {
                      widget.audio.click();
                      _requestReview();
                    },
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    icon: Icon(Icons.settings, color: t.ivory),
                    onPressed: () {
                      widget.audio.click();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                            audio: widget.audio, settings: s),
                      ));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: t.accent, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        offset: const Offset(0, 8),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      Image.asset('assets/pinball_logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'PINBALL',
                  style: TextStyle(
                    color: t.ivory,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                ),
              ),
              Center(
                child: Text(
                  '${s.profile.name}  ·  best ${s.bestForMode}',
                  style: TextStyle(color: t.muted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(t, 'MODE'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _modeCard(t, PinballMode.scoreAttack, 'Score Attack',
                      '${s.attackBalls} balls · beat your record', s),
                  const SizedBox(width: 10),
                  _modeCard(t, PinballMode.endless, 'Endless',
                      'Infinite balls · marathon', s),
                  const SizedBox(width: 10),
                  _modeCard(t, PinballMode.timeRush, 'Time Rush',
                      s.isPro ? '3 minutes · pure rush' : 'PRO only',
                      s,
                      locked: !s.isPro),
                ],
              ),
              const SizedBox(height: 14),
              _sectionTitle(t, 'DIFFICULTY'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _diffCard(t, PinballDifficulty.gentle, 'Gentle',
                      'Slow ball, forgiving tilt', s),
                  const SizedBox(width: 10),
                  _diffCard(t, PinballDifficulty.parlor, 'Parlor',
                      'Classic arcade pace', s),
                  const SizedBox(width: 10),
                  _diffCard(t, PinballDifficulty.lightning, 'Lightning',
                      s.isPro ? 'Fast ball, twitchy tilt' : 'PRO only', s,
                      locked: !s.isPro),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accent,
                    foregroundColor: const Color(0xFF1A1208),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _play,
                  child: const Text(
                    'PLAY',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: t.ivory,
                        side: BorderSide(color: t.accent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.palette_outlined),
                      label: const Text('Table & Ball'),
                      onPressed: () {
                        widget.audio.click();
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => StylePickerScreen(
                              audio: widget.audio, settings: s),
                        ));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: s.isPro ? t.accent : t.ivory,
                        side: BorderSide(
                            color: s.isPro ? t.accent : t.muted),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(s.isPro
                          ? Icons.workspace_premium
                          : Icons.lock_outline),
                      label: Text(s.isPro ? 'PRO active' : 'Go PRO'),
                      onPressed: () {
                        widget.audio.click();
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProScreen(
                              audio: widget.audio,
                              settings: s,
                              store: _store),
                        ));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'High scores — Attack: ${s.bestScoreAttack} · Endless: ${s.bestEndless} · Rush: ${s.bestTimeRush}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(PinballThemeDef t, String text) => Text(
        text,
        style: TextStyle(
          color: t.accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 3,
        ),
      );

  Widget _modeCard(PinballThemeDef t, PinballMode m, String title,
      String sub, PinballSettings s,
      {bool locked = false}) {
    final selected = s.mode == m;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (locked) {
            s.setMode(m); // ignored when not Pro; offer Pro instead
            widget.audio.click();
            if (!s.isPro) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProScreen(
                    audio: widget.audio, settings: s, store: _store),
              ));
            }
            return;
          }
          widget.audio.click();
          s.setMode(m);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? t.accent.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? t.accent : t.muted.withValues(alpha: 0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              if (locked)
                Icon(Icons.lock_outline, color: t.muted, size: 18)
              else
                Icon(Icons.sports_esports,
                    color: selected ? t.accent : t.muted, size: 18),
              const SizedBox(height: 4),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: t.ivory,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
              const SizedBox(height: 2),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.muted, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _diffCard(PinballThemeDef t, PinballDifficulty d, String title,
      String sub, PinballSettings s,
      {bool locked = false}) {
    final selected = s.difficulty == d;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (locked && !s.isPro) {
            widget.audio.click();
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProScreen(
                  audio: widget.audio, settings: s, store: _store),
            ));
            return;
          }
          widget.audio.click();
          s.setDifficulty(d);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? t.accent.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? t.accent : t.muted.withValues(alpha: 0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              if (locked)
                Icon(Icons.lock_outline, color: t.muted, size: 18)
              else
                Icon(Icons.speed,
                    color: selected ? t.accent : t.muted, size: 18),
              const SizedBox(height: 4),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: t.ivory,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
              const SizedBox(height: 2),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.muted, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
