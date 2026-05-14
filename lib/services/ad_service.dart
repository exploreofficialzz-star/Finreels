import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;

  bool _bannerReady = false;
  bool _interstitialReady = false;
  bool _appOpenReady = false;

  int _videoOpenCount = 0;
  int _channelSwitchCount = 0;
  DateTime? _lastAppOpenShown;

  bool get bannerReady => _bannerReady && !_adsRemoved;
  bool get interstitialReady => _interstitialReady && !_adsRemoved;

  bool _adsRemoved = false;
  bool _initialized = false;

  // ── Init ────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _loadAdsRemovedStatus();
    if (_adsRemoved) return;

    await MobileAds.instance.initialize();
    _initialized = true;

    await Future.wait([
      _loadBanner(),
      _loadInterstitial(),
      _loadAppOpen(),
    ]);
  }

  Future<void> _loadAdsRemovedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final adsRemovedRaw = prefs.getBool(AppConfig.prefAdsRemoved) ?? false;
    if (adsRemovedRaw) {
      final until = prefs.getInt(AppConfig.prefAdsRemovedUntil);
      if (until != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(until);
        _adsRemoved = DateTime.now().isBefore(expiry);
        if (!_adsRemoved) {
          // Subscription expired — clean up
          await prefs.remove(AppConfig.prefAdsRemoved);
          await prefs.remove(AppConfig.prefAdsRemovedUntil);
        }
      } else {
        _adsRemoved = true; // permanent (if ever we add lifetime)
      }
    }
  }

  // ── Banner ──────────────────────────────────────────────────────────────────
  Future<void> _loadBanner() async {
    _bannerAd?.dispose();
    _bannerAd = null;
    _bannerReady = false;

    _bannerAd = BannerAd(
      adUnitId: AppConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => _bannerReady = true,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerReady = false;
          // retry after 30 s
          Timer(const Duration(seconds: 30), () => unawaited(_loadBanner()));
        },
      ),
    );
    await _bannerAd!.load();
  }

  BannerAd? get bannerAd => _bannerReady && !_adsRemoved ? _bannerAd : null;

  // ── Interstitial ─────────────────────────────────────────────────────────────
  Future<void> _loadInterstitial() async {
    _interstitialReady = false;
    await InterstitialAd.load(
      adUnitId: AppConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              unawaited(_loadInterstitial()); // pre-load next
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _interstitialReady = false;
          Timer(const Duration(seconds: 45), () => unawaited(_loadInterstitial()));
        },
      ),
    );
  }

  /// Call when user opens a video. Shows interstitial every N opens.
  Future<void> onVideoOpened() async {
    if (_adsRemoved || !_initialized) return;
    _videoOpenCount++;
    if (_videoOpenCount % AppConfig.interstitialEveryNVideos == 0) {
      await showInterstitial();
    }
  }

  /// Call when user switches to a different channel.
  Future<void> onChannelSwitched() async {
    if (_adsRemoved || !_initialized) return;
    _channelSwitchCount++;
    if (_channelSwitchCount % AppConfig.interstitialEveryNChannelSwitches == 0) {
      await showInterstitial();
    }
  }

  Future<void> showInterstitial() async {
    if (_adsRemoved || _interstitialAd == null || !_interstitialReady) return;
    await _interstitialAd!.show();
    _interstitialReady = false;
  }

  // ── App Open Ad ─────────────────────────────────────────────────────────────
  Future<void> _loadAppOpen() async {
    _appOpenReady = false;
    await AppOpenAd.load(
      adUnitId: AppConfig.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _appOpenAd = null;
              _appOpenReady = false;
              _loadAppOpen();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _appOpenAd = null;
              _appOpenReady = false;
              _loadAppOpen();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _appOpenReady = false;
          Timer(const Duration(minutes: 5), () => unawaited(_loadAppOpen()));
        },
      ),
    );
  }

  Future<void> showAppOpenAd() async {
    if (_adsRemoved || !_appOpenReady || _appOpenAd == null) return;
    // Respect cooldown
    if (_lastAppOpenShown != null) {
      final elapsed = DateTime.now().difference(_lastAppOpenShown!);
      if (elapsed < AppConfig.appOpenAdCooldown) return;
    }
    _lastAppOpenShown = DateTime.now();
    await _appOpenAd!.show();
    _appOpenReady = false;
  }

  // ── IAP: Grant Ad-Free Period ────────────────────────────────────────────────
  Future<void> grantAdFree(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(duration);
    await prefs.setBool(AppConfig.prefAdsRemoved, true);
    await prefs.setInt(
        AppConfig.prefAdsRemovedUntil, until.millisecondsSinceEpoch);
    _adsRemoved = true;

    // Clean up existing ads
    _bannerAd?.dispose();
    _bannerAd = null;
    _bannerReady = false;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _interstitialReady = false;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _appOpenReady = false;
  }

  Future<void> revokeAdFree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.prefAdsRemoved);
    await prefs.remove(AppConfig.prefAdsRemovedUntil);
    _adsRemoved = false;
    if (_initialized) {
      await Future.wait([_loadBanner(), _loadInterstitial(), _loadAppOpen()]);
    }
  }

  bool get adsRemoved => _adsRemoved;

  Future<void> refreshStatus() => _loadAdsRemovedStatus();

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _appOpenAd?.dispose();
  }
}
