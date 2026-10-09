import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/iap_service.dart';
import '../theme/pinball_themes.dart';

/// Pinball PRO: Free-vs-Pro comparison, real purchase, restore, and tip jar.
class ProScreen extends StatefulWidget {
  final PinballAudio audio;
  final PinballSettings settings;
  final PinballStore store;
  const ProScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.store});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  void _onPro() {
    if (widget.store.proPurchased.value) {
      widget.settings.setPro(true);
      setState(() {});
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg != null && mounted) {
      widget.settings.recordTip();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      widget.store.lastThanks.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final t = s.theme;
    final store = widget.store;
    return Scaffold(
      backgroundColor: const Color(0xFF171008),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: t.ivory,
        title: const Text('Pinball PRO'),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          store.proPurchased,
          store.purchaseInProgress,
          store.purchaseError,
        ]),
        builder: (_, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _comparisonTable(t, s),
            const SizedBox(height: 20),
            if (s.isPro)
              _proActiveCard(t)
            else
              _buyCard(t, store),
            const SizedBox(height: 16),
            _tipJar(t, store),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Restore purchases'),
              style: TextButton.styleFrom(foregroundColor: t.muted),
              onPressed: () {
                widget.audio.click();
                store.restore();
              },
            ),
            if (store.purchaseError.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  store.purchaseError.value!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            if (!store.storeReady && store.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Store: ${store.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.muted, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Free vs Pro comparison table — buyers see the big difference.
  Widget _comparisonTable(PinballThemeDef t, PinballSettings s) {
    const rows = [
      ('Score Attack mode', true, true),
      ('Endless mode', true, true),
      ('Time Rush mode', false, true),
      ('Gentle + Parlor difficulty', true, true),
      ('Lightning difficulty', false, true),
      ('Score-attack balls', '3 balls', '5 balls'),
      ('Multiball & ball locks', true, true),
      ('Table themes', '6 classic', 'All 14 + creator'),
      ('Ball styles', '4 classic', 'All 9 + creator'),
      ('High-score initials', true, true),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text('Free vs PRO',
                style: TextStyle(
                    color: t.ivory,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(
                    width: 64,
                    child: Text('Free',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: t.muted, fontWeight: FontWeight.w700))),
                SizedBox(
                    width: 64,
                    child: Text('PRO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: t.accent, fontWeight: FontWeight.w800))),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final r in rows) _row(t, r.$1, r.$2, r.$3),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _row(PinballThemeDef t, String label, Object free, Object pro) {
    Widget cell(Object v, Color c) => SizedBox(
          width: 64,
          child: v is bool
              ? Icon(v ? Icons.check_circle : Icons.remove_circle_outline,
                  color: v ? c : t.muted.withValues(alpha: 0.5), size: 20)
              : Text(v.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c, fontSize: 11)),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(color: t.ivory, fontSize: 13))),
          cell(free, t.ivory),
          cell(pro, t.accent),
        ],
      ),
    );
  }

  Widget _proActiveCard(PinballThemeDef t) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.accent, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: t.accent, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'PRO is active — enjoy every table, ball and mode!',
              style: TextStyle(color: t.ivory, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buyCard(PinballThemeDef t, PinballStore store) {
    final p = store.proProduct;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text('Unlock everything, forever.',
              style: TextStyle(color: t.ivory, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('One-time purchase. No subscription.',
              style: TextStyle(color: t.muted, fontSize: 12)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: const Color(0xFF1A1208),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: (p == null || store.purchaseInProgress.value)
                  ? null
                  : () {
                      widget.audio.click();
                      store.buyPro();
                    },
              child: store.purchaseInProgress.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      p == null
                          ? 'PRO — available after store setup'
                          : 'Get PRO — ${p.price}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipJar(PinballThemeDef t, PinballStore store) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.muted.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tip jar',
              style: TextStyle(
                  color: t.ivory,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 4),
          Text('Love the game? Fuel the next table with a coffee or chocolate.',
              style: TextStyle(color: t.muted, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              _tipButton(t, store, store.coffeeProduct, '☕', 'Coffee'),
              const SizedBox(width: 10),
              _tipButton(
                  t, store, store.chocolateProduct, '🍫', 'Chocolate'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tipButton(PinballThemeDef t, PinballStore store,
      ProductDetails? product, String emoji, String label) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.ivory,
          side: BorderSide(color: t.accent.withValues(alpha: 0.6)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: (product == null || store.purchaseInProgress.value)
            ? null
            : () {
                widget.audio.click();
                store.buyTip(product);
              },
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(product?.price ?? '—',
                style: TextStyle(color: t.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
