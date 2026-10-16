import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'save_transfer.dart';

/// Drop-in settings tile that opens the phone-to-phone save transfer flow.
///
/// Usage in a settings screen (inside a ListView/Column children):
/// ```dart
/// TransferSaveTile(gameSlug: 'bowling', accent: myAccentColor),
/// ```
/// The tile needs the game's slug so an imported save is verified to belong
/// to the same game.
class TransferSaveTile extends StatelessWidget {
  final String gameSlug;
  final Color? accent;
  final Color? textColor;

  const TransferSaveTile({
    super.key,
    required this.gameSlug,
    this.accent,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.phone_android_outlined,
          color: accent ?? Theme.of(context).colorScheme.primary),
      title: Text('Transfer save to new phone',
          style: TextStyle(color: textColor)),
      subtitle: Text('Move your progress without an account',
          style: TextStyle(color: textColor?.withValues(alpha: 0.6))),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TransferScreen(gameSlug: gameSlug),
        ),
      ),
    );
  }
}

/// Two-way transfer screen: send this phone's save, or receive another's.
class TransferScreen extends StatelessWidget {
  final String gameSlug;

  const TransferScreen({super.key, required this.gameSlug});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transfer save')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.upload_outlined,
                title: 'Send to new phone',
                subtitle: 'Show a code or share a file from this phone',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => _SendScreen(gameSlug: gameSlug)),
                ),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                icon: Icons.download_outlined,
                title: 'Receive from old phone',
                subtitle: 'Scan a code or open a save file on this phone',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => _ReceiveScreen(gameSlug: gameSlug)),
                ),
              ),
              const Spacer(),
              Text(
                'No account needed. Your save moves directly between your phones.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// SEND
// ------------------------------------------------------------------

class _SendScreen extends StatefulWidget {
  final String gameSlug;
  const _SendScreen({required this.gameSlug});

  @override
  State<_SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<_SendScreen> {
  String? _payload;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final payload = await SaveTransfer.exportPayload(widget.gameSlug);
      if (!mounted) return;
      setState(() {
        _payload = payload;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not prepare your save. Please try again.';
        _busy = false;
      });
    }
  }

  Future<void> _shareFile() async {
    final payload = _payload;
    if (payload == null) return;
    try {
      final file = await SaveTransfer.payloadToFile(payload, widget.gameSlug);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My ${widget.gameSlug} game save — open it in the game on your new phone.',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share the file. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;
    final showQr = payload != null && SaveTransfer.fitsInQr(payload);

    return Scaffold(
      appBar: AppBar(title: const Text('Send to new phone')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_busy) ...[
                const Expanded(
                    child: Center(child: CircularProgressIndicator())),
              ] else if (_error != null) ...[
                Expanded(child: Center(child: Text(_error!))),
                ElevatedButton(onPressed: _generate, child: const Text('Retry')),
              ] else if (payload != null) ...[
                Text(
                  showQr
                      ? 'On your NEW phone, open the game → Settings → Transfer save → Receive, then scan this code:'
                      : 'This save is too large for a code — share the file instead, then open it in the game on your new phone:',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                if (showQr)
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: payload,
                          size: 240,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  const Expanded(
                    child: Center(
                      child: Icon(Icons.file_present_outlined, size: 96, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _shareFile,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share save file'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _generate,
                  child: const Text('Regenerate'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// RECEIVE
// ------------------------------------------------------------------

class _ReceiveScreen extends StatefulWidget {
  final String gameSlug;
  const _ReceiveScreen({required this.gameSlug});

  @override
  State<_ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<_ReceiveScreen> {
  bool _busy = false;

  Future<void> _doImport(String payload) async {
    if (_busy) return;
    setState(() => _busy = true);
    final err =
        await SaveTransfer.importPayload(payload, widget.gameSlug);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Save restored'),
          content: const Text(
              'Your progress is now on this phone. Restart the game to see everything.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _pickFile() async {
    try {
      // file_picker v13 API: returns List<PlatformFile> directly.
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [SaveTransfer.kFileExtension, 'txt'],
      );
      final file = files.firstOrNull;
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final payload = String.fromCharCodes(bytes);
      if (!mounted) return;
      if (payload.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read that file.')),
        );
        return;
      }
      await _doImport(payload);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the file picker.')),
      );
    }
  }

  void _scanQr() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _QrScanScreen(
          onScanned: (code) {
            Navigator.of(context).pop();
            _doImport(code);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive from old phone')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.qr_code_scanner_outlined,
                title: 'Scan QR code',
                subtitle: 'Point at the code shown on your old phone',
                onTap: _busy ? () {} : _scanQr,
              ),
              const SizedBox(height: 16),
              _ActionCard(
                icon: Icons.file_open_outlined,
                title: 'Open save file',
                subtitle: 'Pick the .${SaveTransfer.kFileExtension} file you shared',
                onTap: _busy ? () {} : _pickFile,
              ),
              if (_busy) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QrScanScreen extends StatefulWidget {
  final ValueChanged<String> onScanned;
  const _QrScanScreen({required this.onScanned});

  @override
  State<_QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<_QrScanScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan save code')),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_handled) return;
          final code = capture.barcodes.firstOrNull?.rawValue;
          if (code != null && code.isNotEmpty) {
            _handled = true;
            widget.onScanned(code);
          }
        },
        errorBuilder: (ctx, error, child) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Camera unavailable (${error.errorCode}). Please use “Open save file” instead.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
