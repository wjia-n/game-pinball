import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/ball_styles.dart';
import '../theme/pinball_themes.dart';
import 'pro_screen.dart';
import '../services/iap_service.dart';

/// Table themes + ball/plunger styles, with Pro custom creators.
class StylePickerScreen extends StatefulWidget {
  final PinballAudio audio;
  final PinballSettings settings;
  const StylePickerScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<StylePickerScreen> createState() => _StylePickerScreenState();
}

class _StylePickerScreenState extends State<StylePickerScreen> {
  static const _swatches = [
    0xFFC42E2E, 0xFFE08A4C, 0xFFFFD76A, 0xFF6E8A3A, 0xFF1E4D3B, 0xFF2E5E8A,
    0xFF5E2E8A, 0xFFF5EFE0, 0xFF8A8A8A, 0xFF2E2E34, 0xFFC9A227, 0xFFB03A2E,
  ];

  void _needPro() {
    widget.audio.click();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProScreen(
        audio: widget.audio,
        settings: widget.settings,
        store: PinballStore()..init(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final t = s.theme;
    return Scaffold(
      backgroundColor: const Color(0xFF171008),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: t.ivory,
        title: const Text('Table & Ball'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(t, 'TABLE THEMES (${PinballThemes.all.length + 1})'),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.78,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: PinballThemes.all.length + 1,
            itemBuilder: (_, i) {
              if (i < PinballThemes.all.length) {
                final th = PinballThemes.all[i];
                final locked = th.isPro && !s.isPro;
                final selected = s.themeId == th.id;
                return _themeCard(t, th.name, th.felt, th.woodMid,
                    th.accent, locked, selected, () {
                  if (locked) {
                    _needPro();
                    return;
                  }
                  widget.audio.click();
                  s.setTheme(th.id);
                });
              }
              // Custom theme creator (Pro).
              final locked = !s.isPro;
              final selected = s.themeId == 'custom';
              return _themeCard(
                  t,
                  'My Creation',
                  s.customTheme.felt,
                  s.customTheme.woodMid,
                  s.customTheme.accent,
                  locked,
                  selected, () {
                if (locked) {
                  _needPro();
                  return;
                }
                widget.audio.click();
                s.setTheme('custom');
                _customThemeEditor();
              });
            },
          ),
          const SizedBox(height: 20),
          _section(t, 'BALL STYLES (${BallStyles.all.length + 1})'),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.78,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: BallStyles.all.length + 1,
            itemBuilder: (_, i) {
              if (i < BallStyles.all.length) {
                final b = BallStyles.all[i];
                final locked = b.isPro && !s.isPro;
                final selected = s.ballStyleId == b.id;
                return _ballCard(
                    t, b.name, b.core, locked, selected, () {
                  if (locked) {
                    _needPro();
                    return;
                  }
                  widget.audio.click();
                  s.setBallStyle(b.id);
                });
              }
              final locked = !s.isPro;
              final selected = s.ballStyleId == 'custom';
              return _ballCard(t, 'My Creation',
                  Color(s.customBallColor), locked, selected, () {
                if (locked) {
                  _needPro();
                  return;
                }
                widget.audio.click();
                _customBallEditor();
              });
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(PinballThemeDef t, String text) => Text(
        text,
        style: TextStyle(
          color: t.accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      );

  Widget _themeCard(PinballThemeDef t, String name, Color felt, Color wood,
      Color accent, bool locked, bool selected, void Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : t.muted.withValues(alpha: 0.3),
            width: selected ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                Expanded(flex: 3, child: Container(color: felt)),
                Expanded(child: Container(color: wood)),
              ],
            ),
            if (locked)
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: const Icon(Icons.lock_outline,
                    color: Colors.white70),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ballCard(PinballThemeDef t, String name, Color core, bool locked,
      bool selected, void Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(
            color: selected ? t.accent : t.muted.withValues(alpha: 0.3),
            width: selected ? 3 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: core,
                    border:
                        Border.all(color: Colors.white30, width: 2),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0, 3),
                          blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(name,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: t.ivory, fontSize: 10)),
              ],
            ),
            if (locked)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withValues(alpha: 0.55),
                ),
                child: const Center(
                    child: Icon(Icons.lock_outline,
                        color: Colors.white70)),
              ),
          ],
        ),
      ),
    );
  }

  void _customBallEditor() {
    final s = widget.settings;
    final t = s.theme;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF241A10),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Design your ball',
                  style: TextStyle(
                      color: t.ivory,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(s.customBallColor),
                  border:
                      Border.all(color: t.accent, width: 3),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in _swatches)
                    GestureDetector(
                      onTap: () {
                        widget.audio.click();
                        s.setCustomBallColor(c);
                        setSheet(() {});
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(c),
                          border: Border.all(
                            color: s.customBallColor == c
                                ? t.accent
                                : Colors.white24,
                            width: s.customBallColor == c ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _customThemeEditor() {
    final s = widget.settings;
    final t = s.theme;
    const keys = [
      'felt',
      'woodDark',
      'woodMid',
      'woodLight',
      'rail',
      'bumperA',
      'bumperB',
      'sling',
      'flipper',
      'accent',
    ];
    const labels = {
      'felt': 'Playfield',
      'woodDark': 'Cabinet dark',
      'woodMid': 'Cabinet mid',
      'woodLight': 'Trim',
      'rail': 'Rails',
      'bumperA': 'Bumpers A',
      'bumperB': 'Bumpers B',
      'sling': 'Slingshots',
      'flipper': 'Flippers',
      'accent': 'UI accent',
    };
    String editing = 'felt';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF241A10),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Design your table',
                  style: TextStyle(
                      color: t.ivory,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in keys)
                    ChoiceChip(
                      label: Text(labels[k]!,
                          style: const TextStyle(fontSize: 11)),
                      selected: editing == k,
                      onSelected: (_) => setSheet(() => editing = k),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in _swatches)
                    GestureDetector(
                      onTap: () {
                        widget.audio.click();
                        s.setCustomThemeColor(editing, c);
                        setSheet(() {});
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(c),
                          border: Border.all(
                            color:
                                s.customThemeColors[editing] == c
                                    ? t.accent
                                    : Colors.white24,
                            width:
                                s.customThemeColors[editing] == c
                                    ? 3
                                    : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  s.resetCustomTheme();
                  setSheet(() {});
                },
                child: const Text('Reset to classic'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
