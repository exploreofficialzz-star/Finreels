import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../data/channel_data.dart';
import '../models/channel.dart';
import '../models/feed_tab.dart';
import '../models/video.dart';
import '../services/rss_service.dart';

enum FeedState { idle, loading, loaded, error }

class FeedProvider extends ChangeNotifier {
  FeedState _state = FeedState.idle;
  FeedState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final Map<String, List<Video>> _videosByChannel = {};

  FeedTab _activeTab = FeedTab.all;
  FeedTab get activeTab => _activeTab;

  var _savedVideoIds = <String>{};
  Set<String> get savedVideoIds => _savedVideoIds;

  List<Channel> get channels => ChannelData.all;

  List<Video> getVideosFor(String channelId) =>
      _videosByChannel[channelId] ?? [];

  // ── Filtered feed by tab ─────────────────────────────────────────────────────
  List<Video> get feedVideos {
    final all = _videosByChannel.values.expand((v) => v).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    switch (_activeTab) {
      case FeedTab.all:
        return all;
      case FeedTab.videos:
        // Regular videos — title length > 20 chars, not short
        return all
            .where((v) => !_isShort(v) && !_isBlog(v))
            .toList();
      case FeedTab.shorts:
        return all.where(_isShort).toList();
      case FeedTab.blogs:
        return all.where(_isBlog).toList();
      case FeedTab.books:
        // Curated free finance books from Open Library RSS
        return _bookVideos;
    }
  }

  // Heuristics for content type detection from RSS metadata
  bool _isShort(Video v) {
    final t = v.title.toLowerCase();
    final d = v.description.toLowerCase();
    return t.contains('#short') ||
        t.contains('shorts') ||
        d.contains('#shorts') ||
        t.contains('in 60') ||
        t.contains('in 30') ||
        t.length < 25;
  }

  bool _isBlog(Video v) {
    final t = v.title.toLowerCase();
    return t.contains('tip') ||
        t.contains('guide') ||
        t.contains('how to') ||
        t.contains('rule') ||
        t.contains('mistake') ||
        t.contains('list') ||
        t.contains('thing') ||
        t.contains('way') ||
        t.contains('reason') ||
        t.contains('lesson');
  }

  // Static curated free finance books (Open Library public domain)
  List<Video> get _bookVideos => [
    Video(
      id: 'book_richest_man',
      title: 'The Richest Man in Babylon — George S. Clason',
      description:
          'Classic personal finance book using parables set in ancient Babylon. '
          'Timeless lessons on saving, investing, and building wealth.',
      channelId: 'books',
      channelName: 'Free Finance Library',
      publishedAt: FeedProvider._epoch,
      thumbnailUrl:
          'https://covers.openlibrary.org/b/id/8739161-L.jpg',
    ),
    Video(
      id: 'book_think_grow',
      title: 'Think and Grow Rich — Napoleon Hill',
      description:
          'One of the best-selling self-help books of all time. Hill studied '
          'over 500 successful people to identify the secrets of wealth.',
      channelId: 'books',
      channelName: 'Free Finance Library',
      publishedAt: FeedProvider._epoch,
      thumbnailUrl:
          'https://covers.openlibrary.org/b/id/8739505-L.jpg',
    ),
    Video(
      id: 'book_common_stocks',
      title: 'Common Stocks and Uncommon Profits — Philip Fisher',
      description:
          'A classic investment guide on how to identify outstanding '
          'companies and hold them for the long term.',
      channelId: 'books',
      channelName: 'Free Finance Library',
      publishedAt: FeedProvider._epoch,
      thumbnailUrl:
          'https://covers.openlibrary.org/b/id/7222246-L.jpg',
    ),
    Video(
      id: 'book_millionaire_next_door',
      title: 'The Millionaire Next Door — Thomas Stanley',
      description:
          'Reveals that most millionaires live below their means, work hard, '
          'and avoid the trappings of a high-consumption lifestyle.',
      channelId: 'books',
      channelName: 'Free Finance Library',
      publishedAt: FeedProvider._epoch,
      thumbnailUrl:
          'https://covers.openlibrary.org/b/id/8091016-L.jpg',
    ),
    Video(
      id: 'book_intelligent_investor',
      title: 'The Intelligent Investor — Benjamin Graham',
      description:
          'Warren Buffett\'s favourite book. The definitive guide on value '
          'investing, margin of safety, and long-term wealth building.',
      channelId: 'books',
      channelName: 'Free Finance Library',
      publishedAt: FeedProvider._epoch,
      thumbnailUrl:
          'https://covers.openlibrary.org/b/id/8739161-L.jpg',
    ),
  ];

  static final _epoch = DateTime(2000);

  // ── Init ─────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _loadSaved();
    await refresh();
  }

  // ── Tab ──────────────────────────────────────────────────────────────────────
  void setTab(FeedTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  // ── Fetch ────────────────────────────────────────────────────────────────────
  Future<void> refresh({bool force = false}) async {
    _state = FeedState.loading;
    _errorMessage = null;
    notifyListeners();

    var successCount = 0;
    final futures = ChannelData.all.map((ch) async {
      try {
        final videos =
            await RssService.instance.fetchVideos(ch.id, forceRefresh: force);
        _videosByChannel[ch.id] = videos;
        successCount++;
      } on Exception catch (e) {
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

  // ── Saved ────────────────────────────────────────────────────────────────────
  bool isVideoSaved(String id) => _savedVideoIds.contains(id);

  Future<void> toggleSaved(Video video) async {
    if (_savedVideoIds.contains(video.id)) {
      _savedVideoIds.remove(video.id);
    } else {
      _savedVideoIds.add(video.id);
    }
    await _persistSaved();
    notifyListeners();
  }

  List<Video> get savedVideos {
    final all = _videosByChannel.values.expand((v) => v).toList();
    return all
        .where((v) => _savedVideoIds.contains(v.id))
        .toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConfig.prefSavedVideos) ?? [];
    _savedVideoIds = raw.toSet();
  }

  Future<void> _persistSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        AppConfig.prefSavedVideos, _savedVideoIds.toList());
  }
}
