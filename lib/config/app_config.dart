import 'dart:io';

/// Central configuration for FinReels — by chAs Tech Group
/// ─────────────────────────────────────────────────────────
/// Real AdMob IDs wired from AdMob console screenshots.
/// iOS IDs still need to be added once iOS app is registered in AdMob.
class AppConfig {
  AppConfig._();

  // ── App Identity ─────────────────────────────────────────────────────────────
  static const String appName = 'FinReels';
  static const String byLine = 'by chAs';
  static const String company = 'chAs Tech Group';
  static const String packageName = 'com.chastech.finreels';

  // ── AdMob — PRODUCTION IDs (Android) ────────────────────────────────────────
  // App ID: ca-app-pub-2492078126313994~7729948254
  // Set kDebugAds = true ONLY for local testing to avoid policy violations.
  static const bool kDebugAds = false;

  static String get admobAppId => Platform.isAndroid
      ? 'ca-app-pub-2492078126313994~7729948254'
      : 'ca-app-pub-2492078126313994~7729948254'; // ← replace with iOS App ID

  static String get bannerAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/6300978111' // test
          : 'ca-app-pub-2492078126313994/9210550883') // PROD
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/2934735716' // test
          : 'ca-app-pub-2492078126313994/9210550883'); // ← replace with iOS unit

  static String get interstitialAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/1033173712' // test
          : 'ca-app-pub-2492078126313994/2175580693') // PROD
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/4411468910' // test
          : 'ca-app-pub-2492078126313994/2175580693'); // ← replace with iOS unit

  static String get rewardedAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/5224354917' // test
          : 'ca-app-pub-2492078126313994/3017889074') // PROD
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/1712485313' // test
          : 'ca-app-pub-2492078126313994/3017889074'); // ← replace with iOS unit

  static String get rewardedInterstitialAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/5354046379' // test
          : 'ca-app-pub-2492078126313994/5422743877') // PROD
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/6978759866' // test
          : 'ca-app-pub-2492078126313994/5422743877'); // ← replace with iOS unit

  static String get nativeAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/2247696110' // test
          : 'ca-app-pub-2492078126313994/1332060862') // PROD
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/3986624511' // test
          : 'ca-app-pub-2492078126313994/1332060862'); // ← replace with iOS unit

  // Note: No App Open ad unit was created in AdMob — using test ID for now.
  // Create an App Open unit in AdMob console and paste the ID here.
  static String get appOpenAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/9257395921' // test
          : 'ca-app-pub-3940256099942544/9257395921') // ← create & replace
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/5575463023' // test
          : 'ca-app-pub-3940256099942544/5575463023'); // ← create & replace

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
  static const String prefAdsRemoved          = 'ads_removed';
  static const String prefAdsRemovedUntil     = 'ads_removed_until';
  static const String prefLastSeenVideos      = 'last_seen_videos_';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefSavedVideos         = 'saved_videos';
  static const String prefAdBlockChecked      = 'adblock_last_check_ms';

  // ── Connectivity Check Endpoints ─────────────────────────────────────────────
  // Plain internet health checks — NOT ad-related (no false positives).
  static const List<String> connectivityEndpoints = [
    'https://www.gstatic.com/generate_204',
    'https://connectivitycheck.gstatic.com/generate_204',
    'https://clients3.google.com/generate_204',
    'https://www.google.com/favicon.ico',
  ];

  // ── Ad-Block Detection Endpoints ─────────────────────────────────────────────
  // These are the exact URLs that every major ad blocker (AdGuard, uBlock,
  // NextDNS, Pi-hole) targets. They should always succeed on a clean device.
  // We require ALL 4 to fail before flagging — avoids false positives on
  // occasional CDN blips.
  static const List<String> adCheckEndpoints = [
    'https://pagead2.googlesyndication.com/pagead/show_ads.js',
    'https://static.doubleclick.net/instream/ad_status.js',
    'https://adservice.google.com/adsid/google/ui',
    'https://tpc.googlesyndication.com/simgad/1',
  ];

  // ── Ad Frequency Throttling ──────────────────────────────────────────────────
  static const int interstitialEveryNVideos          = 3;
  static const int interstitialEveryNChannelSwitches = 4;
  static const Duration appOpenAdCooldown            = Duration(hours: 2);

  // ── Background Task ──────────────────────────────────────────────────────────
  static const String rssCheckTaskId   = 'finreels_rss_check';
  static const String rssCheckTaskName = 'rssCheckTask';
  static const Duration rssCheckFrequency = Duration(minutes: 15);

  // ── Notification Channel ─────────────────────────────────────────────────────
  static const int    notifIdBase      = 1000;
  static const String notifChannelId   = 'finreels_new_content';
  static const String notifChannelName = 'New Videos';
  static const String notifChannelDesc =
      'Get notified when your favourite channels post new content';
}
