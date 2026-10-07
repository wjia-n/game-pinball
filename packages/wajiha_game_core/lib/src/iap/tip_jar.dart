import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../theme/game_theme.dart';

/// Tip-jar only monetisation. Everything in the games is free -
/// these two products are pure voluntary support.
/// NOTE: create these exact product IDs in Google Play Console:
///   buy_me_a_coffee, buy_me_a_chocolate
class TipJar {
  static const coffeeId = 'buy_me_a_coffee';
  static const chocolateId = 'buy_me_a_chocolate';
  static const productIds = {coffeeId, chocolateId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  List<ProductDetails> products = [];
  bool available = false;
  bool loading = true;

  Future<void> init() async {
    available = await _iap.isAvailable();
    if (!available) {
      loading = false;
      return;
    }
    _sub = _iap.purchaseStream.listen(_onPurchases);
    final response = await _iap.queryProductDetails(productIds);
    products = response.productDetails;
    loading = false;
  }

  void _onPurchases(List<PurchaseDetails> details) {
    for (final d in details) {
      if (d.status == PurchaseStatus.purchased || d.status == PurchaseStatus.restored) {
        _iap.completePurchase(d);
      }
    }
  }

  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: param);
  }

  Future<void> restore() async => _iap.restorePurchases();

  void dispose() => _sub?.cancel();
}

/// Bottom sheet with the two tip-jar options.
class TipJarSheet extends StatefulWidget {
  const TipJarSheet({super.key});

  @override
  State<TipJarSheet> createState() => _TipJarSheetState();
}

class _TipJarSheetState extends State<TipJarSheet> {
  final TipJar _tipJar = TipJar();

  @override
  void initState() {
    super.initState();
    _tipJar.init().then((_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _tipJar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Container(
        decoration: BoxDecoration(color: t.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 48, height: 5, decoration: BoxDecoration(color: t.muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 16),
            const Text('💛', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text('Fuel the fun!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: t.text)),
            const SizedBox(height: 8),
            Text(
              'Every game here is 100% free, forever. No ads walls, no pay-to-win. If these games made you smile, you can toss a little love our way:',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.muted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            if (_tipJar.loading)
              const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
            else if (!_tipJar.available || _tipJar.products.isEmpty)
              Text('Tip jar is napping right now (store unavailable).\nThe games are still all free! 💛',
                  textAlign: TextAlign.center, style: TextStyle(color: t.muted))
            else
              for (final p in _tipJar.products) _tipCard(p, t),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Maybe later', style: TextStyle(color: t.muted, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipCard(ProductDetails p, GameTheme t) {
    final isCoffee = p.id == TipJar.coffeeId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isCoffee ? [const Color(0xFF8B5E34), const Color(0xFF5C3A1E)] : [const Color(0xFF7C4DFF), const Color(0xFF4A2B9E)]),
        borderRadius: t.radius,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Text(isCoffee ? '☕' : '🍫', style: const TextStyle(fontSize: 36)),
        title: Text(isCoffee ? 'Buy me a coffee' : 'Buy me a chocolate',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
        subtitle: Text(isCoffee ? 'For late-night game making' : 'For sweet new game ideas',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
          child: Text(p.price, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
        ),
        onTap: () {
          _tipJar.buy(p);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('You are awesome! Thank you! ${isCoffee ? '☕' : '🍫'}')),
            );
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
