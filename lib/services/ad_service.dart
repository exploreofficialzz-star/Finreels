import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ── Ad objects ───────────────────────────────────────────────────────────────
  BannerAd?              _bannerAd;
  InterstitialAd?        _interstitialAd;
  AppOpenAd?             _appOpenAd;
  RewardedAd?            _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;

  bool _bannerReady              = false;
  bool _interstitialReady        = false;
  bool _appOpenReady             = false;
  bool _rewardedReady            = false;
  bool _rewardedInterstitialReady = false;

  // ── Throttle counters ────────────────────────────────────────────────────────
  int _videoOpenCount      = 0;
  int _channelSwitchCount  = 0;
  DateTime? _lastAppOpenShown;

  bool _adsRemoved  = false;
  bool _initialized = false;

  bool get adsRemoved => _adsRemoved;
  BannerAd? get bannerAd => (_bannerReady && !_adsRemoved) ? _bannerAd : null;

  // ── Init ─────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _loadAdsRemovedStatus();
    if (_adsRemoved) return;

    await MobileAds.instance.initialize();
    _initialized = true;

    await Future.wait([
      _loadBanner(),
      _loadInterstitial(),
      _loadAppOpen(),
      _loadRewarded(),
      _loadRewardedInterstitial(),
    ]);
  }

  // ── Ads-removed status ────────────────────────────────────────────────────────
  Future<void> _loadAdsRemovedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final removed = prefs.getBool(AppConfig.prefAdsRemoved) ?? false;
    if (removed) {
      final until = prefs.getInt(AppConfig.prefAdsRemovedUntil);
      if (until != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(until);
        _adsRemoved = DateTime.now().isBefore(expiry);
        if (!_adsRemoved) {
          await prefs.remove(AppConfig.prefAdsRemoved);
          await prefs.remove(AppConfig.prefAdsRemovedUntil);
        }
      } else {
        _adsRemoved = true;
      }
    }
  }

  // ── Banner ───────────────────────────────────────────────────────────────────
  Future<void> _loadBanner() async {
    _bannerAd?.dispose();
    _bannerAd    = null;
    _bannerReady = false;

    _bannerAd = BannerAd(
      adUnitId: AppConfig.bannerAdUnitId,
      size:     AdSize.banner,
      request:  const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => _bannerReady = true,
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _bannerReady = false;
          Timer(const Duration(seconds: 30),
              () => unawaited(_loadBanner()));
        },
      ),
    );
    await _bannerAd!.load();
  }

  // ── Interstitial ──────────────────────────────────────────────────────────────
  Future<void> _loadInterstitial() async {
    _interstitialReady = false;
    await InterstitialAd.load(
      adUnitId: AppConfig.interstitialAdUnitId,
      request:  const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd    = ad;
          _interstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd    = null;
              _interstitialReady = false;
              unawaited(_loadInterstitial());
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitialAd    = null;
              _interstitialReady = false;
              unawaited(_loadInterstitial());
            },
          );
        },
        onAdFailedToLoad: (_) {
          _interstitialReady = false;
          Timer(const Duration(seconds: 45),
              () => unawaited(_loadInterstitial()));
        },
      ),
    );
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────────
  Future<void> _loadRewarded() async {
    _rewardedReady = false;
    await RewardedAd.load(
      adUnitId: AppConfig.rewardedAdUnitId,
      request:  const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd    = ad;
          _rewardedReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd    = null;
              _rewardedReady = false;
              unawaited(_loadRewarded());
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _rewardedAd    = null;
              _rewardedReady = false;
              unawaited(_loadRewarded());
            },
          );
        },
        onAdFailedToLoad: (_) {
          _rewardedReady = false;
          Timer(const Duration(minutes: 2),
              () => unawaited(_loadRewarded()));
        },
      ),
    );
  }

  /// Show a rewarded ad. Calls [onRewarded] when the user earns the reward.
  Future<void> showRewardedAd({
    required void Function() onRewarded,
  }) async {
    if (_adsRemoved || !_rewardedReady || _rewardedAd == null) return;
    await _rewardedAd!.show(
      onUserEarnedReward: (_, __) => onRewarded(),
    );
    _rewardedReady = false;
  }

  // ── Rewarded Interstitial ─────────────────────────────────────────────────────
  Future<void> _loadRewardedInterstitial() async {
    _rewardedInterstitialReady = false;
    await RewardedInterstitialAd.load(
      adUnitId: AppConfig.rewardedInterstitialAdUnitId,
      request:  const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd    = ad;
          _rewardedInterstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedInterstitialAd    = null;
              _rewardedInterstitialReady = false;
              unawaited(_loadRewardedInterstitial());
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _rewardedInterstitialAd    = null;
              _rewardedInterstitialReady = false;
              unawaited(_loadRewardedInterstitial());
            },
          );
        },
        onAdFailedToLoad: (_) {
          _rewardedInterstitialReady = false;
          Timer(const Duration(minutes: 2),
              () => unawaited(_loadRewardedInterstitial()));
        },
      ),
    );
  }

  Future<void> showRewardedInterstitialAd({
    required void Function() onRewarded,
  }) async {
    if (_adsRemoved || !_rewardedInterstitialReady ||
        _rewardedInterstitialAd == null) return;
    await _rewardedInterstitialAd!.show(
      onUserEarnedReward: (_, __) => onRewarded(),
    );
    _rewardedInterstitialReady = false;
  }

  // ── App Open ──────────────────────────────────────────────────────────────────
  Future<void> _loadAppOpen() async {
    _appOpenReady = false;
    await AppOpenAd.load(
      adUnitId: AppConfig.appOpenAdUnitId,
      request:  const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd    = ad;
          _appOpenReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _appOpenAd    = null;
              _appOpenReady = false;
              unawaited(_loadAppOpen());
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _appOpenAd    = null;
              _appOpenReady = false;
              unawaited(_loadAppOpen());
            },
          );
        },
        onAdFailedToLoad: (_) {
          _appOpenReady = false;
          Timer(const Duration(minutes: 5),
              () => unawaited(_loadAppOpen()));
        },
      ),
    );
  }

  Future<void> showAppOpenAd() async {
    if (_adsRemoved || !_appOpenReady || _appOpenAd == null) return;
    if (_lastAppOpenShown != null) {
      final elapsed = DateTime.now().difference(_lastAppOpenShown!);
      if (elapsed < AppConfig.appOpenAdCooldown) return;
    }
    _lastAppOpenShown = DateTime.now();
    await _appOpenAd!.show();
    _appOpenReady = false;
  }

  // ── Throttled triggers ────────────────────────────────────────────────────────
  Future<void> onVideoOpened() async {
    if (_adsRemoved || !_initialized) return;
    _videoOpenCount++;
    if (_videoOpenCount % AppConfig.interstitialEveryNVideos == 0) {
      await showInterstitial();
    }
  }

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

  // ── IAP: grant / revoke ad-free ───────────────────────────────────────────────
  Future<void> grantAdFree(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(duration);
    await prefs.setBool(AppConfig.prefAdsRemoved, true);
    await prefs.setInt(
        AppConfig.prefAdsRemovedUntil, until.millisecondsSinceEpoch);
    _adsRemoved = true;
    _bannerAd?.dispose();
    _bannerAd              = null;
    _bannerReady           = false;
    _interstitialAd?.dispose();
    _interstitialAd        = null;
    _interstitialReady     = false;
    _appOpenAd?.dispose();
    _appOpenAd             = null;
    _appOpenReady          = false;
    _rewardedAd?.dispose();
    _rewardedAd            = null;
    _rewardedReady         = false;
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd        = null;
    _rewardedInterstitialReady     = false;
  }

  Future<void> revokeAdFree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.prefAdsRemoved);
    await prefs.remove(AppConfig.prefAdsRemovedUntil);
    _adsRemoved = false;
    if (_initialized) {
      await Future.wait([
        _loadBanner(),
        _loadInterstitial(),
        _loadAppOpen(),
        _loadRewarded(),
        _loadRewardedInterstitial(),
      ]);
    }
  }

  Future<void> refreshStatus() => _loadAdsRemovedStatus();

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _appOpenAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
  }
}
