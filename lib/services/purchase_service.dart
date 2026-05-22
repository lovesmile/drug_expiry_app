import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  static const String _premiumId = 'premium_unlock';
  static const Set<String> _productIds = {_premiumId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// Initialize the purchase service.
  /// [onPremiumUnlocked] is called when a premium purchase is detected.
  Future<void> init({required void Function() onPremiumUnlocked}) async {
    _isAvailable = await _iap.isAvailable();

    if (!_isAvailable) return;

    _subscription = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        _handlePurchase(purchase, onPremiumUnlocked);
      }
    });
  }

  void _handlePurchase(PurchaseDetails purchase, void Function() onPremiumUnlocked) {
    if (purchase.productID != _premiumId) return;

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      onPremiumUnlocked();
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  /// Query product details for the premium product.
  Future<ProductDetails?> getPremiumProduct() async {
    if (!_isAvailable) return null;
    final response = await _iap.queryProductDetails(_productIds);
    if (response.notFoundIDs.isNotEmpty) {
      // ignore: avoid_print
      print('Products not found: ${response.notFoundIDs}');
    }
    return response.productDetails.isNotEmpty
        ? response.productDetails.first
        : null;
  }

  /// Start the purchase flow for the premium product.
  Future<bool> purchase() async {
    if (!_isAvailable) return false;
    final product = await getPremiumProduct();
    if (product == null) return false;

    final param = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: param);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Purchase error: $e');
      return false;
    }
  }

  /// Restore previously purchased products.
  Future<void> restore() async {
    if (!_isAvailable) return;
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
