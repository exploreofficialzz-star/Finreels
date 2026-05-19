import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Ad trigger pattern for content taps (videos, blogs, books):
///   Tap 1 → show ad
///   Tap 2 → live (no ad)
///   Tap 3 → live (no ad)
///   Tap 4 → show ad
///   Tap 5 → live, 6 → live, 7 → live, 8 → show ad ... repeat every 4
///
/// In other words: show ad on tap 1, then every 4th tap after that.
/// Shorts pattern: show ad every 4 pages scrolled (independent counter).
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ── Ad objects ────────────────────────────────────────────────────────────────
  BannerAd?               _bannerAd;
  InterstitialAd?         _interstitialAd;
  AppOpenAd?              _appOpenAd;
  RewardedAd?             _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;

  bool _bannerReady               = false;
  bool _interstitialReady         = false;
  bool _appOpenReady              = false;
  bool _rewardedReady             = false;
  bool _rewardedInterstitialReady = false;

  // ── Tap counters ──────────────────────────────────────────────────────────────
  /// Global content-tap counter (videos + blogs + books).
  /// Pattern: ad on tap 1, then every 4th tap (1, 4, 8, 12, …).
  int _contentTapCount = 0;

  /// Independent shorts-scroll counter.
  /// Ad every [AppConfig.interstitialEveryNShorts] pages scrolled.
  int _shortScrollCount = 0;

  int _channelSwitchCount = 0;
  DateTime? _lastAppOpenShown;

  bool _adsRemoved  = false;
  bool _initialized = false;

  bool get adsRemoved => _adsRemoved;
  BannerAd? get bannerAd => (_bannerReady && !_adsRemoved) ? _bannerAd : null;

  // ── Init ──────────────────────────────────────────────────────────────────────
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

  // ── Banner ────────────────────────────────────────────────────────────────────
  Future<void> _loadBanner() async {
    if (_bannerAd != null) { unawaited(_bannerAd!.dispose()); }
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
          Timer(const Duration(seconds: 30), () => unawaited(_loadBanner()));
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
          Timer(const Duration(seconds: 45), () => unawaited(_loadInterstitial()));
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
          Timer(const Duration(minutes: 2), () => unawaited(_loadRewarded()));
        },
      ),
    );
  }

  Future<void> showRewardedAd({required void Function() onRewarded}) async {
    if (_adsRemoved || !_rewardedReady || _rewardedAd == null) return;
    await _rewardedAd!.show(onUserEarnedReward: (_, __) => onRewarded());
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
          Timer(const Duration(minutes: 2), () => unawaited(_loadRewardedInterstitial()));
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
        onUserEarnedReward: (_, __) => onRewarded());
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
          Timer(const Duration(minutes: 5), () => unawaited(_loadAppOpen()));
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

  // ── Content tap trigger — feeds, blogs, books ─────────────────────────────────
  /// Call this every time the user taps to open any content item.
  /// Ad pattern: show on tap 1, skip 2 & 3, show on 4, skip 5 & 6 & 7,
  /// show on 8 … i.e. tap 1 and every 4th tap thereafter.
  Future<void> onContentTapped() async {
    if (_adsRemoved || !_initialized) return;
    _contentTapCount++;
    // Show on tap 1 (first ever tap), then every 4th tap: 1, 4, 8, 12 …
    final shouldShow = _contentTapCount == 1 ||
        (_contentTapCount > 1 &&
            (_contentTapCount - 1) % AppConfig.interstitialCycleLength == 0);
    if (shouldShow) await showInterstitial();
  }

  /// Legacy — kept for backward-compat with any callers still using it.
  Future<void> onVideoOpened() => onContentTapped();

  // ── Shorts scroll trigger ─────────────────────────────────────────────────────
  /// Call on every page change in the Shorts player.
  /// Shows an interstitial every [AppConfig.interstitialEveryNShorts] scrolls.
  Future<void> onShortScrolled() async {
    if (_adsRemoved || !_initialized) return;
    _shortScrollCount++;
    if (_shortScrollCount % AppConfig.interstitialEveryNShorts == 0) {
      await showInterstitial();
    }
  }

  // ── Channel switch trigger ────────────────────────────────────────────────────
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
