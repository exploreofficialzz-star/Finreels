import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../config/app_config.dart';
import 'ad_service.dart';

/// Duration each product grants ad-free access.
const Map<String, Duration> _productDurations = {
  AppConfig.iapNoAds1Day: Duration(days: 1),
  AppConfig.iapNoAdsWeekly: Duration(days: 7),
  AppConfig.iapNoAdsMonthly: Duration(days: 31),
};

class IapService extends ChangeNotifier {
  IapService._();
  static final IapService instance = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _available = false;
  bool get available => _available;

  bool _purchasePending = false;
  bool get purchasePending => _purchasePending;

  String? _error;
  String? get error => _error;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  // ── Init ────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      _error = 'In-app purchases not available on this device.';
      notifyListeners();
      return;
    }

    // Listen for purchase updates
    _purchaseSub = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (e) {
        _error = 'Purchase stream error: $e';
        notifyListeners();
      },
    );

    await _loadProducts();
    await _restorePurchases();
  }

  // ── Load Products ───────────────────────────────────────────────────────────
  Future<void> _loadProducts() async {
    final response =
        await _iap.queryProductDetails(AppConfig.iapProductIds);
    if (response.error != null) {
      _error = 'Could not load products: ${response.error!.message}';
    }
    // Sort: 1-day → weekly → monthly
    _products = response.productDetails
      ..sort((a, b) {
        const order = [
          AppConfig.iapNoAds1Day,
          AppConfig.iapNoAdsWeekly,
          AppConfig.iapNoAdsMonthly,
        ];
        return order.indexOf(a.id).compareTo(order.indexOf(b.id));
      });
    notifyListeners();
  }

  // ── Purchase ────────────────────────────────────────────────────────────────
  Future<void> purchase(ProductDetails product) async {
    _error = null;
    _purchasePending = true;
    notifyListeners();

    final param = PurchaseParam(productDetails: product);
    try {
      // All our products are subscriptions
      await _iap.buyNonConsumable(purchaseParam: param);
    } on Exception catch (e) {
      _purchasePending = false;
      _error = 'Purchase failed: $e';
      notifyListeners();
    }
  }

  // ── Restore ─────────────────────────────────────────────────────────────────
  Future<void> restorePurchases() async {
    _error = null;
    _purchasePending = true;
    notifyListeners();
    await _iap.restorePurchases();
  }

  Future<void> _restorePurchases() async {
    await _iap.restorePurchases();
  }

  // ── Handle Updates ──────────────────────────────────────────────────────────
  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _purchasePending = false;
          await _fulfil(purchase);
          break;

        case PurchaseStatus.canceled:
          _purchasePending = false;
          break;

        case PurchaseStatus.error:
          _purchasePending = false;
          _error = purchase.error?.message ?? 'Purchase error';
          break;
      }

      // Complete the purchase (required by both platforms)
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  // ── Fulfil ──────────────────────────────────────────────────────────────────
  Future<void> _fulfil(PurchaseDetails purchase) async {
    final duration = _productDurations[purchase.productID];
    if (duration != null) {
      await AdService.instance.grantAdFree(duration);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String friendlyName(String productId) {
    switch (productId) {
      case AppConfig.iapNoAds1Day:
        return 'Remove Ads – 24 Hours';
      case AppConfig.iapNoAdsWeekly:
        return 'Remove Ads – 1 Week';
      case AppConfig.iapNoAdsMonthly:
        return 'Remove Ads – 1 Month';
      default:
        return productId;
    }
  }

  String friendlyPrice(ProductDetails p) => p.price;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}
