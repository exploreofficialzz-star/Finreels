import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../data/channel_data.dart';
import '../models/channel.dart';
import '../models/video.dart';
import '../services/rss_service.dart';

enum FeedState { idle, loading, loaded, error }

class FeedProvider extends ChangeNotifier {
  // ── State ────────────────────────────────────────────────────────────────────
  FeedState _state = FeedState.idle;
  FeedState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final Map<String, List<Video>> _videosByChannel = {};
  List<Video> getVideosFor(String channelId) =>
      _videosByChannel[channelId] ?? [];

  Channel? _selectedChannel; // null = "All"
  Channel? get selectedChannel => _selectedChannel;

  List<Channel> get channels => ChannelData.all;

  var _savedVideoIds = <String>{};
  Set<String> get savedVideoIds => _savedVideoIds;

  // ── Combined / filtered feed ────────────────────────────────────────────────
  List<Video> get feedVideos {
    if (_selectedChannel != null) {
      return _videosByChannel[_selectedChannel!.id] ?? [];
    }
    // Merge all channels, sort by date
    final all = _videosByChannel.values.expand((v) => v).toList();
    all.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return all;
  }

  bool isVideoSaved(String id) => _savedVideoIds.contains(id);

  // ── Init ─────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _loadSaved();
    await refresh();
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────────
  Future<void> refresh({bool force = false}) async {
    _state = FeedState.loading;
    _errorMessage = null;
    notifyListeners();

    var successCount = 0;

    // Fetch all channels concurrently
    final futures = ChannelData.all.map((ch) async {
      try {
        final videos =
            await RssService.instance.fetchVideos(ch.id, forceRefresh: force);
        _videosByChannel[ch.id] = videos;
        successCount++;
      } on Exception catch (e) {
        // Keep stale data; don't fail entire feed
        debugPrint('[FeedProvider] Error fetching ${ch.name}: $e');
      }
    });

    await Future.wait(futures);

    _state = successCount > 0 ? FeedState.loaded : FeedState.error;
    _errorMessage = successCount == 0
        ? 'Could not load any content. Check your connection.'
        : null;

    notifyListeners();
  }

  // ── Channel Selector ─────────────────────────────────────────────────────────
  void selectChannel(Channel? channel) {
    if (_selectedChannel == channel) return;
    _selectedChannel = channel;
    notifyListeners();
  }

  // ── Saved Videos ─────────────────────────────────────────────────────────────
  Future<void> toggleSaved(Video video) async {
    if (_savedVideoIds.contains(video.id)) {
      _savedVideoIds.remove(video.id);
    } else {
      _savedVideoIds.add(video.id);
    }
    await _persistSaved(video);
    notifyListeners();
  }

  List<Video> get savedVideos {
    final all = _videosByChannel.values.expand((v) => v).toList();
    return all.where((v) => _savedVideoIds.contains(v.id)).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConfig.prefSavedVideos) ?? [];
    _savedVideoIds = raw.toSet();
  }

  Future<void> _persistSaved(Video video) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        AppConfig.prefSavedVideos, _savedVideoIds.toList());
  }
}
