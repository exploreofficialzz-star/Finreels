import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../data/channel_data.dart';
import 'rss_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Init ────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      AppConfig.notifChannelId,
      AppConfig.notifChannelName,
      description: AppConfig.notifChannelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  // ── Permission Request ──────────────────────────────────────────────────────
  Future<bool> requestPermission() async {
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  // ── Core Check — called from WorkManager background task ────────────────────
  /// Fetches all channels, compares with last-seen video IDs, fires
  /// a notification for any new ones.
  static Future<void> checkAndNotifyNewVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final notifEnabled =
        prefs.getBool(AppConfig.prefNotificationsEnabled) ?? true;
    if (!notifEnabled) return;

    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await plugin.initialize(
        const InitializationSettings(
            android: androidSettings, iOS: iosSettings));

    var notifId = AppConfig.notifIdBase;

    for (final channel in ChannelData.all) {
      try {
        final videos =
            await RssService.instance.fetchVideos(channel.id);
        if (videos.isEmpty) continue;

        final lastSeenKey = '${AppConfig.prefLastSeenVideos}${channel.id}';
        final lastSeenRaw = prefs.getStringList(lastSeenKey) ?? [];
        final lastSeenIds = lastSeenRaw.toSet();

        // New videos = those not in the last-seen set
        final newVideos =
            videos.where((v) => !lastSeenIds.contains(v.id)).toList();

        if (newVideos.isNotEmpty && lastSeenIds.isNotEmpty) {
          // Only notify if we had a previous state (not first run)
          for (final video in newVideos.take(3)) {
            await _showNotification(
              plugin: plugin,
              id: notifId++,
              channelName: channel.name,
              videoTitle: video.title,
              videoId: video.id,
            );
          }
        }

        // Update last-seen with current video IDs (keep latest 30)
        final currentIds = videos.take(30).map((v) => v.id).toList();
        await prefs.setStringList(lastSeenKey, currentIds);
      } on Exception catch (_) {
        // Don't crash the background task on individual channel failures
      }
    }
  }

  static Future<void> _showNotification({
    required FlutterLocalNotificationsPlugin plugin,
    required int id,
    required String channelName,
    required String videoTitle,
    required String videoId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConfig.notifChannelId,
      AppConfig.notifChannelName,
      channelDescription: AppConfig.notifChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails(

    );
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await plugin.show(
      id,
      '🎬 New from $channelName',
      videoTitle,
      details,
      payload: json.encode({'videoId': videoId}),
    );
  }

  void _onTap(NotificationResponse response) {
    // Deep-link handling: parse payload and navigate
    // Navigation is handled in main.dart via a global key
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!) as Map<String, dynamic>;
        final videoId = data['videoId'] as String?;
        if (videoId != null) {
          // Store pending deep link; picked up by main shell on next build
          pendingVideoId = videoId;
        }
      } on Exception catch (_) {}
    }
  }

  static String? pendingVideoId;

  bool get isInitialized => _initialized;
// ── Notification preference ───────────────────────────────────────────────
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConfig.prefNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConfig.prefNotificationsEnabled, enabled);
  }
}
