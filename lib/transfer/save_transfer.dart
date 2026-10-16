import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phone-to-phone save transfer for Wajiha games.
///
/// Exports ALL local game data (SharedPreferences + JSON save files in the
/// app documents directory) into a single compressed, base64-encoded payload
/// string. The payload carries a format marker, version, and the game slug so
/// a save can never be imported into the wrong game.
///
/// Two transfer paths are supported by the UI layer ([transfer_ui.dart]):
///  * QR code — for small saves (payload under ~3 KB)
///  * `.wajiha-save` file shared via the system share sheet (any size)
///
/// No account, no login, no cloud — everything stays on the player's phones.
class SaveTransfer {
  static const String kFormat = 'wajiha-save';
  static const int kFormatVersion = 1;

  /// Rough QR capacity threshold. Payloads larger than this fall back to
  /// file-share only (the UI hides the QR option automatically).
  static const int kQrMaxChars = 2900;

  /// File extension used for exported save files.
  static const String kFileExtension = 'wajiha-save';

  /// Serializes everything into a transfer payload string.
  ///
  /// Set [includeFiles] to false to export SharedPreferences only.
  static Future<String> exportPayload(
    String gameSlug, {
    bool includeFiles = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};

    for (final key in prefs.getKeys()) {
      final v = prefs.get(key);
      if (v is int) {
        data[key] = {'t': 'i', 'v': v};
      } else if (v is double) {
        data[key] = {'t': 'd', 'v': v};
      } else if (v is bool) {
        data[key] = {'t': 'b', 'v': v};
      } else if (v is String) {
        data[key] = {'t': 's', 'v': v};
      } else if (v is List<String>) {
        data[key] = {'t': 'l', 'v': v};
      }
      // Other types are not storable via SharedPreferences anyway.
    }

    final files = <String, String>{};
    if (includeFiles) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        if (await dir.exists()) {
          await for (final e in dir.list()) {
            if (e is File &&
                (e.path.endsWith('.json') || e.path.endsWith('.save'))) {
              final name = e.path.split(Platform.pathSeparator).last;
              try {
                files[name] = base64Encode(await e.readAsBytes());
              } catch (_) {
                // Skip unreadable files — never fail the whole export.
              }
            }
          }
        }
      } catch (_) {
        // File scan is best-effort; SharedPreferences data is the core.
      }
    }

    final envelope = <String, dynamic>{
      'format': kFormat,
      'version': kFormatVersion,
      'game': gameSlug,
      'exportedAt': DateTime.now().toIso8601String(),
      'prefs': data,
      'files': files,
    };

    final jsonBytes = utf8.encode(jsonEncode(envelope));
    final compressed = _gzip(jsonBytes);
    return base64Encode(compressed);
  }

  /// Restores a payload previously created by [exportPayload].
  ///
  /// Returns `null` on success, or a human-readable error message.
  /// Existing data is overwritten key-by-key (merge); keys absent from the
  /// payload are left untouched, so an import can never wipe unrelated data.
  static Future<String?> importPayload(
    String payload,
    String gameSlug, {
    bool restoreFiles = true,
  }) async {
    Map<String, dynamic> envelope;
    try {
      final trimmed = payload.trim();
      final compressed = base64Decode(trimmed);
      final jsonBytes = _gunzip(compressed);
      envelope = jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
    } catch (_) {
      return 'Could not read this save. Make sure you scanned the full code or picked the right file.';
    }

    if (envelope['format'] != kFormat) {
      return 'This is not a valid game save file.';
    }
    if (envelope['game'] != gameSlug) {
      final other = envelope['game'];
      return 'This save belongs to a different game${other is String && other.isNotEmpty ? ' (“$other”)' : ''}. Open that game to import it.';
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = (envelope['prefs'] as Map?) ?? {};
      for (final entry in data.entries) {
        final key = entry.key.toString();
        final wrapped = entry.value as Map?;
        if (wrapped == null) continue;
        final t = wrapped['t'];
        final v = wrapped['v'];
        switch (t) {
          case 'i':
            await prefs.setInt(key, (v as num).toInt());
            break;
          case 'd':
            await prefs.setDouble(key, (v as num).toDouble());
            break;
          case 'b':
            await prefs.setBool(key, v as bool);
            break;
          case 's':
            await prefs.setString(key, v as String);
            break;
          case 'l':
            await prefs.setStringList(
                key, (v as List).map((e) => e.toString()).toList());
            break;
        }
      }

      if (restoreFiles) {
        try {
          final files = (envelope['files'] as Map?) ?? {};
          if (files.isNotEmpty) {
            final dir = await getApplicationDocumentsDirectory();
            for (final entry in files.entries) {
              final name = entry.key.toString();
              // Guard against path traversal in file names.
              if (name.contains('/') || name.contains('\\') || name.contains('..')) {
                continue;
              }
              final bytes = base64Decode(entry.value.toString());
              await File('${dir.path}${Platform.pathSeparator}$name')
                  .writeAsBytes(bytes);
            }
          }
        } catch (_) {
          // File restore is best-effort.
        }
      }
    } catch (_) {
      return 'Something went wrong while restoring your save. Please try again.';
    }
    return null;
  }

  /// Writes [payload] to a temporary `.wajiha-save` file for sharing.
  static Future<File> payloadToFile(String payload, String gameSlug) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
        '${dir.path}${Platform.pathSeparator}$gameSlug-save-$stamp.$kFileExtension');
    await file.writeAsString(payload);
    return file;
  }

  /// True when the payload is small enough to fit in a QR code.
  static bool fitsInQr(String payload) => payload.length <= kQrMaxChars;

  // -----------------------------------------------------------------
  // gzip via dart:io (no extra dependency).
  // -----------------------------------------------------------------
  static Uint8List _gzip(List<int> bytes) {
    // dart:io's gzip is exposed through ZLibCodec.
    return Uint8List.fromList(ZLibCodec(gzip: true).encode(bytes));
  }

  static List<int> _gunzip(List<int> bytes) {
    return ZLibCodec(gzip: true).decode(bytes);
  }
}
