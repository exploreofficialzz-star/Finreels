import 'dart:io';

/// Central configuration for FinReels.
/// ─────────────────────────────────────────────────────────────────────────────
/// Before shipping to production:
///   1. Replace all AdMob IDs labelled [TEST] with your real IDs from AdMob.
///   2. Ensure IAP product IDs match App Store Connect & Google Play Console.
///   3. Set kDebugAds = false.
/// ─────────────────────────────────────────────────────────────────────────────
class AppConfig {
  AppConfig._();

  // ── App Identity ────────────────────────────────────────────────────────────
  static const String appName = 'FinReels';
  static const String byLine = 'by chAs';
  static const String company = 'Chas Tech Group';
  static const String packageName = 'com.chastech.finreels';

  // ── AdMob: set kDebugAds = true to always use test IDs ─────────────────────
  static const bool kDebugAds = true; // ← set false before production release

  static String get admobAppId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544~3347511713' // [TEST]
          : 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX') // [PROD – replace]
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544~1458002511' // [TEST]
          : 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX'); // [PROD – replace]

  static String get bannerAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX')
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX');

  static String get interstitialAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX')
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX');

  static String get appOpenAdUnitId => Platform.isAndroid
      ? (kDebugAds
          ? 'ca-app-pub-3940256099942544/9257395921'
          : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX')
      : (kDebugAds
          ? 'ca-app-pub-3940256099942544/5575463023'
          : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX');

  // ── In-App Purchase Product IDs ─────────────────────────────────────────────
  // Must match EXACTLY what is configured in:
  //   Android → Google Play Console > Monetization > Subscriptions
  //   iOS     → App Store Connect > In-App Purchases > Subscriptions
  static const String iapNoAds1Day = 'finreels_no_ads_1day';
  static const String iapNoAdsWeekly = 'finreels_no_ads_weekly';
  static const String iapNoAdsMonthly = 'finreels_no_ads_monthly';

  static const Set<String> iapProductIds = {
    iapNoAds1Day,
    iapNoAdsWeekly,
    iapNoAdsMonthly,
  };

  // ── SharedPreferences Keys ──────────────────────────────────────────────────
  static const String prefAdsRemoved = 'ads_removed';
  static const String prefAdsRemovedUntil = 'ads_removed_until'; // epoch ms
  static const String prefLastSeenVideos = 'last_seen_videos_'; // + channelId
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefSavedVideos = 'saved_videos';

  // ── Connectivity Check Endpoints (multiple = redundant) ─────────────────────
  // These are non-ad, lightweight endpoints to verify real internet access.
  static const List<String> connectivityEndpoints = [
    'https://www.gstatic.com/generate_204',
    'https://connectivitycheck.gstatic.com/generate_204',
    'https://clients3.google.com/generate_204',
    'https://www.google.com/favicon.ico',
  ];

  // ── Ad-Block Detection Endpoints ────────────────────────────────────────────
  // Try to reach known ad-network URLs. If 2+ fail while internet is working,
  // we flag as ad-blocked.
  static const List<String> adCheckEndpoints = [
    'https://pagead2.googlesyndication.com/pagead/show_ads.js',
    'https://static.doubleclick.net/instream/ad_status.js',
    'https://adservice.google.com/adsid/google/ui',
    'https://tpc.googlesyndication.com/simgad/1',
  ];

  // ── Ad Frequency Throttling ─────────────────────────────────────────────────
  static const int interstitialEveryNVideos = 3; // show every 3rd video open
  static const int interstitialEveryNChannelSwitches = 4;
  static const Duration appOpenAdCooldown = Duration(hours: 2);

  // ── Background Task ─────────────────────────────────────────────────────────
  static const String rssCheckTaskId = 'finreels_rss_check';
  static const String rssCheckTaskName = 'rssCheckTask';
  static const Duration rssCheckFrequency = Duration(minutes: 15);

  // ── Notification Channel ────────────────────────────────────────────────────
  static const int notifIdBase = 1000;
  static const String notifChannelId = 'finreels_new_content';
  static const String notifChannelName = 'New Videos';
  static const String notifChannelDesc =
      'Get notified when your favourite channels post new content';
}
