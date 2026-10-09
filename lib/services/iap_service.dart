import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Real Play Billing store for Pinball: Pro unlock + tip jar.
///
/// Product IDs (Wajiha creates these in Play Console):
/// - `pinballpro` — one-time NON-CONSUMABLE: unlocks Pro forever.
/// - `pinballcoffee` — CONSUMABLE tip.
/// - `pinballchocolate` — CONSUMABLE tip.
///
/// Until the products exist in Play Console (or on any store error) the
/// service exposes [storeReady] = false and the UI shows an honest
/// "available after store setup" state — never a fake buy button.
class PinballStore {
  static const proId = 'pinballpro';
  static const coffeeId = 'pinballcoffee';
  static const chocolateId = 'pinballchocolate';
  static const productIds = {proId, coffeeId, chocolateId};

  final InAppPurchase _iap = InAppPurchase.instance;

  bool available = false;
  bool storeReady = false; // true once real products are queryable
  List<ProductDetails> products = [];
  String? error;
  bool _initialized = false;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// Callbacks the UI wires up.
  final ValueNotifier<String?> lastThanks = ValueNotifier(null);
  final ValueNotifier<bool> proPurchased = ValueNotifier(false);
  final ValueNotifier<bool> purchaseInProgress = ValueNotifier(false);
  final ValueNotifier<String?> purchaseError = ValueNotifier(null);

  ProductDetails? get proProduct => _byId(proId);
  ProductDetails? get coffeeProduct => _byId(coffeeId);
  ProductDetails? get chocolateProduct => _byId(chocolateId);

  ProductDetails? _byId(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      available = await _iap.isAvailable();
      if (!available) {
        error = 'Store unavailable on this device';
        return;
      }
      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (_) {},
        cancelOnError: false,
      );
      final resp = await _iap.queryProductDetails(productIds);
      if (resp.error != null) {
        error = 'Could not reach the store';
        return;
      }
      products = resp.productDetails;
      // Products not yet created in Play Console simply don't appear here;
      // whatever IS queryable is buyable. Fully empty = pre-launch state.
      storeReady = products.isNotEmpty;
      if (!storeReady) error = 'Available after store setup';
    } catch (_) {
      available = false;
      error = 'Store error';
    }
  }

  void _onPurchases(List<PurchaseDetails> list) {
    for (final p in list) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        if (p.productID == proId) {
          proPurchased.value = true;
          lastThanks.value = 'Welcome to Pinball PRO!';
        } else if (p.productID == chocolateId) {
          lastThanks.value = 'Thank you for the chocolate!';
        } else if (p.productID == coffeeId) {
          lastThanks.value = 'Thank you for the coffee!';
        }
      } else if (p.status == PurchaseStatus.error) {
        purchaseError.value = 'Purchase failed — please try again.';
      } else if (p.status == PurchaseStatus.canceled) {
        purchaseError.value = null;
      }
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored ||
          p.status == PurchaseStatus.canceled ||
          p.status == PurchaseStatus.error) {
        purchaseInProgress.value = false;
      }
      if (p.pendingCompletePurchase) {
        _iap.completePurchase(p).catchError((_) {});
      }
    }
  }

  Future<void> buyPro() async {
    final p = proProduct;
    if (p == null) return;
    purchaseError.value = null;
    purchaseInProgress.value = true;
    try {
      await _iap.buyNonConsumable(
          purchaseParam: PurchaseParam(productDetails: p));
    } catch (_) {
      purchaseInProgress.value = false;
      purchaseError.value = 'Purchase failed — please try again.';
    }
  }

  Future<void> buyTip(ProductDetails product) async {
    purchaseError.value = null;
    purchaseInProgress.value = true;
    try {
      await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (_) {
      purchaseInProgress.value = false;
      purchaseError.value = 'Purchase failed — please try again.';
    }
  }

  /// Restore Pro on a new device. The purchase stream delivers restored
  /// purchases, which flip [proPurchased].
  Future<void> restore() async {
    purchaseError.value = null;
    try {
      await _iap.restorePurchases();
    } catch (_) {
      purchaseError.value = 'Restore failed — please try again.';
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    lastThanks.dispose();
    proPurchased.dispose();
    purchaseInProgress.dispose();
    purchaseError.dispose();
  }
}
