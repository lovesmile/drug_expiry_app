import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _initialized = false;

  static const String bannerAdUnitId =
      'ca-app-pub-3467280156915509/7992566851';

  static Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  static BannerAd createBanner({
    required AdSize size,
    required void Function(Ad) onLoaded,
    required void Function(Ad, LoadAdError) onFailed,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed,
      ),
    )..load();
  }
}