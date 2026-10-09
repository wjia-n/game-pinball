import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/pinball_themes.dart';

/// Settings: audio toggles + volume, renameable player profile, stats reset.
class SettingsScreen extends StatefulWidget {
  final PinballAudio audio;
  final PinballSettings settings;
  const SettingsScreen({super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _initials;
  late final FocusNode _nameFocus;
  late final FocusNode _initialsFocus;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.settings.profile.name);
    _initials =
        TextEditingController(text: widget.settings.profile.initials);
    // Commit the profile when a field loses focus, in addition to the
    // per-keystroke saves — the value is always persisted either way.
    _nameFocus = FocusNode()
      ..addListener(() {
        if (!_nameFocus.hasFocus) _saveProfile();
      });
    _initialsFocus = FocusNode()
      ..addListener(() {
        if (!_initialsFocus.hasFocus) _saveProfile();
      });
  }

  @override
  void dispose() {
    _name.dispose();
    _initials.dispose();
    _nameFocus.dispose();
    _initialsFocus.dispose();
    super.dispose();
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
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section(t, 'PLAYER PROFILE'),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            focusNode: _nameFocus,
            maxLength: 16,
            style: TextStyle(color: t.ivory),
            decoration: InputDecoration(
              labelText: 'Display name',
              labelStyle: TextStyle(color: t.muted),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: t.muted),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: t.accent),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => _saveProfile(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _initials,
            focusNode: _initialsFocus,
            maxLength: 3,
            textCapitalization: TextCapitalization.characters,
            style: TextStyle(color: t.ivory),
            decoration: InputDecoration(
              labelText: 'High-score initials (3 letters)',
              labelStyle: TextStyle(color: t.muted),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: t.muted),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: t.accent),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => _saveProfile(),
          ),
          const SizedBox(height: 20),
          _section(t, 'AUDIO'),
          SwitchListTile(
            title: Text('Music', style: TextStyle(color: t.ivory)),
            value: s.musicOn,
            activeThumbColor: t.accent,
            onChanged: (v) {
              widget.audio.click();
              s.setMusic(v);
              widget.audio.configure(
                  musicOn: v, sfxOn: s.sfxOn, volume: s.volume);
              if (v) widget.audio.startMenuMusic();
            },
          ),
          SwitchListTile(
            title: Text('Sound effects', style: TextStyle(color: t.ivory)),
            value: s.sfxOn,
            activeThumbColor: t.accent,
            onChanged: (v) {
              s.setSfx(v);
              widget.audio.configure(
                  musicOn: s.musicOn, sfxOn: v, volume: s.volume);
              if (v) widget.audio.click();
            },
          ),
          ListTile(
            title: Text('Volume', style: TextStyle(color: t.ivory)),
            subtitle: Slider(
              value: s.volume,
              activeColor: t.accent,
              onChanged: (v) {
                s.setVolume(v);
                widget.audio.configure(
                    musicOn: s.musicOn,
                    sfxOn: s.sfxOn,
                    volume: v);
              },
            ),
          ),
          const SizedBox(height: 20),
          _section(t, 'STATS'),
          ListTile(
            title: Text(
                'Games played: ${s.gamesPlayed}   ·   Tips given: ${s.tipsGiven}',
                style: TextStyle(color: t.muted, fontSize: 13)),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade300,
              side: BorderSide(color: Colors.red.shade300),
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Reset high scores & stats'),
            onPressed: () async {
              widget.audio.click();
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Reset everything?'),
                  content: const Text(
                      'All high scores and stats will be cleared.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              if (ok == true) s.resetStats();
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Pinball by WAJIHA · v2.0.0',
              style: TextStyle(color: t.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    widget.settings.setProfile(_name.text, _initials.text);
  }

  Widget _section(PinballThemeDef t, String text) => Text(
        text,
        style: TextStyle(
          color: t.accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 3,
        ),
      );
}
