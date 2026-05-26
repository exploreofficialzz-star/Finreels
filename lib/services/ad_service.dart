import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// AdService — interstitial patterns:
///
/// FEED TAPS (videos, blogs, books):
///   Show ad on every 4th tap: taps 4, 8, 12, 16 …
///   i.e. user browses 1-2-3 freely, ad on 4th, free 5-6-7, ad on 8th, etc.
///
/// VIDEO PAUSE:
///   Show ad on every 4th pause: pauses 4, 8, 12 …
///   Independent counter per session — resets when app restarts.
///
/// BLOGS / BOOKS:
///   Same counter as feed taps (shared _contentTapCount).
///   Tapping any blog article or book triggers the same every-4th pattern.
///
/// BANNER:
///   Placed after every 3rd item in the video feed list and blog list.
///   Also pinned at the bottom of all content screens.
///   A single BannerAd instance is reused across all placements via
///   AdWidget — the SDK handles correct rendering.
///
/// SHORTS: untouched — scroll-based counter unchanged.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ── Ad objects ────────────────────────────────────────────────────────────
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

  // ── Counters ──────────────────────────────────────────────────────────────

  /// Shared counter for feed taps (videos + blogs + books).
  /// Interstitial fires every 4th tap: 4, 8, 12, 16 …
  int _contentTapCount = 0;

  /// Video pause counter — independent from feed taps.
  /// Interstitial fires every 4th pause: 4, 8, 12 …
  int _videoPauseCount = 0;

  /// Shorts scroll counter — unchanged, every 4 scrolls.
  int _shortScrollCount = 0;

  int _channelSwitchCount = 0;
  DateTime? _lastAppOpenShown;

  bool _adsRemoved  = false;
  bool _initialized = false;

  bool get adsRemoved => _adsRemoved;
  BannerAd? get bannerAd => (_bannerReady && !_adsRemoved) ? _bannerAd : null;

  // ── Init ──────────────────────────────────────────────────────────────────
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

  // ── Ads-removed status ────────────────────────────────────────────────────
  Future<void> _loadAdsRemovedStatus() async {
    final prefs   = await SharedPreferences.getInstance();
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

  // ── Banner ────────────────────────────────────────────────────────────────
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

  // ── Interstitial ──────────────────────────────────────────────────────────
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

  // ── Rewarded ──────────────────────────────────────────────────────────────
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

  // ── Rewarded Interstitial ─────────────────────────────────────────────────
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
        onUserEarnedReward: (_, __) => onRewarded());
    _rewardedInterstitialReady = false;
  }

  // ── App Open ──────────────────────────────────────────────────────────────
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
      if (DateTime.now().difference(_lastAppOpenShown!) <
          AppConfig.appOpenAdCooldown) return;
    }
    _lastAppOpenShown = DateTime.now();
    await _appOpenAd!.show();
    _appOpenReady = false;
  }

  // ── FEED TAP TRIGGER (videos + blogs + books) ─────────────────────────────
  /// Call every time user taps a video card, blog article, or book.
  /// Pattern: interstitial fires on tap 4, 8, 12, 16 … (every 4th tap).
  /// Taps 1, 2, 3 are free. Then 4 fires, 5-6-7 free, 8 fires, etc.
  Future<void> onContentTapped() async {
    if (_adsRemoved || !_initialized) return;
    _contentTapCount++;
    if (_contentTapCount % AppConfig.interstitialCycleLength == 0) {
      await showInterstitial();
    }
  }

  // ── VIDEO PAUSE TRIGGER ───────────────────────────────────────────────────
  /// Call every time the user taps pause inside the inline video player.
  /// Pattern: interstitial fires on pause 4, 8, 12 … (every 4th pause).
  /// Pauses 1, 2, 3 are free. Pause 4 fires, 5-6-7 free, pause 8 fires, etc.
  Future<void> onVideoPaused() async {
    if (_adsRemoved || !_initialized) return;
    _videoPauseCount++;
    if (_videoPauseCount % AppConfig.interstitialCycleLength == 0) {
      await showInterstitial();
    }
  }

  // ── SHORTS SCROLL TRIGGER ─────────────────────────────────────────────────
  /// Unchanged — fires every 4 shorts scrolled.
  Future<void> onShortScrolled() async {
    if (_adsRemoved || !_initialized) return;
    _shortScrollCount++;
    if (_shortScrollCount % AppConfig.interstitialEveryNShorts == 0) {
      await showInterstitial();
    }
  }

  // ── Channel switch ────────────────────────────────────────────────────────
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

  // ── Legacy compat ─────────────────────────────────────────────────────────
  Future<void> onVideoOpened() => onContentTapped();

  // ── IAP: grant / revoke ad-free ───────────────────────────────────────────
  Future<void> grantAdFree(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(duration);
    await prefs.setBool(AppConfig.prefAdsRemoved, true);
    await prefs.setInt(
        AppConfig.prefAdsRemovedUntil, until.millisecondsSinceEpoch);
    _adsRemoved = true;
    unawaited(_bannerAd?.dispose()              ?? Future.value());
    _bannerAd              = null; _bannerReady           = false;
    unawaited(_interstitialAd?.dispose()        ?? Future.value());
    _interstitialAd        = null; _interstitialReady     = false;
    unawaited(_appOpenAd?.dispose()             ?? Future.value());
    _appOpenAd             = null; _appOpenReady          = false;
    unawaited(_rewardedAd?.dispose()            ?? Future.value());
    _rewardedAd            = null; _rewardedReady         = false;
    unawaited(_rewardedInterstitialAd?.dispose() ?? Future.value());
    _rewardedInterstitialAd = null; _rewardedInterstitialReady = false;
  }

  Future<void> revokeAdFree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.prefAdsRemoved);
    await prefs.remove(AppConfig.prefAdsRemovedUntil);
    _adsRemoved = false;
    if (_initialized) {
      await Future.wait([
        _loadBanner(), _loadInterstitial(), _loadAppOpen(),
        _loadRewarded(), _loadRewardedInterstitial(),
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
