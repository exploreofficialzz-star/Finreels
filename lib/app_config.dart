import 'dart:io';

/// Central configuration for FinReels — by chAs Tech Group
class AppConfig {
  AppConfig._();

  static const String appName = 'FinReels';
  static const String byLine = 'by chAs';
  static const String company = 'chAs Tech Group';
  static const String packageName = 'com.chastech.finreels';

  // ── AdMob — PRODUCTION IDs (Android) ────────────────────────────────────────
  static const bool kDebugAds = true;

  static String get admobAppId => Platform.isAndroid
      ? 'ca-app-pub-2492078126313994~7729948254'
      : 'ca-app-pub-2492078126313994~7729948254';

  static String get bannerAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-2492078126313994/9210550883')
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-2492078126313994/9210550883');

  static String get interstitialAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-2492078126313994/2175580693')
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-2492078126313994/2175580693');

  static String get rewardedAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-2492078126313994/3017889074')
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-2492078126313994/3017889074');

  static String get rewardedInterstitialAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/5354046379'
          : 'ca-app-pub-2492078126313994/5422743877')
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/6978759866'
          : 'ca-app-pub-2492078126313994/5422743877');

  static String get nativeAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/2247696110'
          : 'ca-app-pub-2492078126313994/1332060862')
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/3986624511'
          : 'ca-app-pub-2492078126313994/1332060862');

  static String get appOpenAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/9257395921'
          : 'ca-app-pub-2492078126313994/4197807683')
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/5575463023'
          : 'ca-app-pub-2492078126313994/4197807683');

  // ── In-App Purchase Product IDs ──────────────────────────────────────────────
  static const String iapNoAds1Day    = 'finreels_no_ads_1day';
  static const String iapNoAdsWeekly  = 'finreels_no_ads_weekly';
  static const String iapNoAdsMonthly = 'finreels_no_ads_monthly';

  static const Set<String> iapProductIds = {
    iapNoAds1Day,
    iapNoAdsWeekly,
    iapNoAdsMonthly,
  };

  // ── SharedPreferences Keys ───────────────────────────────────────────────────
  static const String prefAdsRemoved           = 'ads_removed';
  static const String prefAdsRemovedUntil      = 'ads_removed_until';
  static const String prefLastSeenVideos       = 'last_seen_videos_';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefSavedVideos          = 'saved_videos';
  static const String prefAdBlockChecked       = 'adblock_last_check_ms';

  // ── Connectivity ─────────────────────────────────────────────────────────────
  static const List<String> connectivityEndpoints = [
    'https://www.gstatic.com/generate_204',
    'https://connectivitycheck.gstatic.com/generate_204',
    'https://clients3.google.com/generate_204',
    'https://www.google.com/favicon.ico',
  ];

  // ── Ad-Block Detection ────────────────────────────────────────────────────────
  static const List<String> adCheckEndpoints = [
    'https://pagead2.googlesyndication.com/pagead/show_ads.js',
    'https://static.doubleclick.net/instream/ad_status.js',
    'https://adservice.google.com/adsid/google/ui',
    'https://tpc.googlesyndication.com/simgad/1',
  ];

  // ── Ad Frequency ─────────────────────────────────────────────────────────────
  // Pattern for regular content: show ad on tap 1, skip 2 & 3, show on 4, repeat.
  // (Every 1st and 4th tap in a 4-tap cycle.)
  // interstitialCycleLength = 4 → show when (count % 4 == 1) || (count % 4 == 0)
  static const int interstitialCycleLength = 4;

  // Shorts: show ad every N pages scrolled.
  static const int interstitialEveryNShorts = 4;

  // Legacy kept for onChannelSwitched path.
  static const int interstitialEveryNChannelSwitches = 4;
  static const Duration appOpenAdCooldown = Duration(hours: 2);

  // ── Background Task ───────────────────────────────────────────────────────────
  static const String rssCheckTaskId      = 'finreels_rss_check';
  static const String rssCheckTaskName    = 'rssCheckTask';
  static const Duration rssCheckFrequency = Duration(minutes: 15);

  // ── Notification Channel ──────────────────────────────────────────────────────
  static const int    notifIdBase      = 1000;
  static const String notifChannelId   = 'finreels_new_content';
  static const String notifChannelName = 'New Videos';
  static const String notifChannelDesc =
      'Get notified when your favourite channels post new content';
}
