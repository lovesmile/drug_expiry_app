import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

enum PurchaseResult { started, unavailable, productNotFound, failed }

class PurchaseService {
  static const String premiumProductId = 'premium_unlock';
  static const Set<String> _productIds = {premiumProductId};

  static final PurchaseService instance = PurchaseService._internal();

  factory PurchaseService() => instance;

  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final List<VoidCallback> _premiumUnlockedListeners = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<void>? _initialization;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  Future<void> init({VoidCallback? onPremiumUnlocked}) {
    if (onPremiumUnlocked != null &&
        !_premiumUnlockedListeners.contains(onPremiumUnlocked)) {
      _premiumUnlockedListeners.add(onPremiumUnlocked);
    }

    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) return;

      _subscription = _iap.purchaseStream.listen(
        _handlePurchases,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Purchase stream error: $error');
        },
      );
    } catch (error) {
      _isAvailable = false;
      debugPrint('Purchase initialization error: $error');
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.productID == premiumProductId &&
        (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored)) {
      for (final listener in List<VoidCallback>.of(_premiumUnlockedListeners)) {
        listener();
      }
    }

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  Future<ProductDetails?> getPremiumProduct() async {
    await init();
    if (!_isAvailable) return null;

    try {
      final response = await _iap.queryProductDetails(_productIds);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }
      return response.productDetails.isNotEmpty
          ? response.productDetails.first
          : null;
    } catch (error) {
      debugPrint('Product query error: $error');
      return null;
    }
  }

  Future<PurchaseResult> purchase() async {
    await init();
    if (!_isAvailable) return PurchaseResult.unavailable;

    final product = await getPremiumProduct();
    if (product == null) return PurchaseResult.productNotFound;

    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      return PurchaseResult.started;
    } catch (error) {
      debugPrint('Purchase error: $error');
      return PurchaseResult.failed;
    }
  }

  Future<PurchaseResult> restore() async {
    await init();
    if (!_isAvailable) return PurchaseResult.unavailable;

    try {
      await _iap.restorePurchases();
      return PurchaseResult.started;
    } catch (error) {
      debugPrint('Restore purchase error: $error');
      return PurchaseResult.failed;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _initialization = null;
    _premiumUnlockedListeners.clear();
  }
}
