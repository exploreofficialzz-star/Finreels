import 'dart:math';

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
  final Random _random = Random();

  FeedTab _activeTab = FeedTab.all;
  FeedTab get activeTab => _activeTab;

  var _savedVideoIds = <String>{};
  Set<String> get savedVideoIds => _savedVideoIds;

  List<Channel> get channels => ChannelData.all;

  List<Video> getVideosFor(String channelId) =>
      _videosByChannel[channelId] ?? [];

  // ── Filtered + randomised feed ───────────────────────────────────────────────
  List<Video> get feedVideos {
    // Merge all channel videos
    final all = _videosByChannel.values.expand((v) => v).toList();

    switch (_activeTab) {
      case FeedTab.all:
        // Randomise order so all channels get exposure equally
        return _shuffleByChannel(all.where((v) => !_isBook(v)).toList());
      case FeedTab.videos:
        return _shuffleByChannel(
            all.where((v) => !_isShort(v) && !_isBlog(v) && !_isBook(v)).toList());
      case FeedTab.shorts:
        return _shuffleByChannel(
            all.where((v) => _isShort(v) && !_isBook(v)).toList());
      case FeedTab.blogs:
        // ONLY real blog/advice content — strict filter
        return _shuffleByChannel(
            all.where((v) => _isBlogStrict(v) && !_isBook(v)).toList());
      case FeedTab.books:
        return _bookVideos;
    }
  }

  /// Interleaves videos from different channels so no channel dominates.
  List<Video> _shuffleByChannel(List<Video> videos) {
    if (videos.isEmpty) return videos;

    // Group by channelId
    final Map<String, List<Video>> grouped = {};
    for (final v in videos) {
      (grouped[v.channelId] ??= []).add(v);
    }

    // Sort each group by date (newest first)
    for (final list in grouped.values) {
      list.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    }

    // Round-robin interleave — pick one from each channel in turn
    final result = <Video>[];
    final keys = grouped.keys.toList()..shuffle(_random);
    var maxLen = grouped.values.map((l) => l.length).fold(0, max);

    for (var i = 0; i < maxLen; i++) {
      for (final key in keys) {
        final list = grouped[key]!;
        if (i < list.length) result.add(list[i]);
      }
    }
    return result;
  }

  // ── Content type detection ────────────────────────────────────────────────────
  bool _isShort(Video v) {
    final t = v.title.toLowerCase();
    final d = v.description.toLowerCase();
    return t.contains('#short') ||
        t.contains('shorts') ||
        d.contains('#shorts') ||
        t.contains(' 60s') ||
        t.contains(' 30s') ||
        t.length < 25;
  }

  /// Strict blog filter — only listicles and how-to content
  bool _isBlogStrict(Video v) {
    final t = v.title.toLowerCase();
    // Must match specific blog patterns AND NOT be a short
    if (_isShort(v)) return false;
    return (t.startsWith('how to') ||
        t.startsWith('why ') ||
        t.startsWith('what ') ||
        RegExp(r'^\d+ (ways|tips|things|rules|reasons|lessons|steps|mistakes)').hasMatch(t) ||
        t.contains(' tips ') ||
        t.contains(' guide') ||
        t.contains(' rules') ||
        t.contains(' lessons') ||
        t.contains(' mistakes') ||
        t.contains(' steps to'));
  }

  bool _isBook(Video v) => v.channelId == 'books';

  // ── Free books library ────────────────────────────────────────────────────────
  static final _epoch = DateTime(2000);

  List<Video> get _bookVideos => [
        Video(
          id: 'book_richest_man',
          title: 'The Richest Man in Babylon — George S. Clason',
          description:
              'Classic personal finance book using parables set in ancient '
              'Babylon. Timeless lessons on saving, investing, and building '
              'wealth. The oldest wealth-building advice still relevant today.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/8739161-L.jpg',
        ),
        Video(
          id: 'book_think_grow',
          title: 'Think and Grow Rich — Napoleon Hill',
          description:
              'One of the best-selling self-help books of all time. Hill '
              'studied 500+ successful people to extract 13 wealth principles. '
              'A masterclass in success mindset.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/8739505-L.jpg',
        ),
        Video(
          id: 'book_rich_dad',
          title: 'Rich Dad Poor Dad — Robert Kiyosaki',
          description:
              'What the rich teach their kids about money that the poor and '
              'middle class do not. The most-read personal finance book of all '
              'time. Changes how you think about money forever.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/9253566-L.jpg',
        ),
        Video(
          id: 'book_millionaire_next_door',
          title: 'The Millionaire Next Door — Thomas Stanley',
          description:
              'The surprising truth about America\'s wealthy. Most millionaires '
              'live below their means and build wealth quietly. Real research, '
              'real data — how ordinary people build extraordinary wealth.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/8091016-L.jpg',
        ),
        Video(
          id: 'book_intelligent_investor',
          title: 'The Intelligent Investor — Benjamin Graham',
          description:
              'Warren Buffett\'s favourite book and the bible of value investing. '
              'The definitive guide on margin of safety and long-term wealth. '
              'Every serious investor must read this.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/8235963-L.jpg',
        ),
        Video(
          id: 'book_psychology_money',
          title: 'The Psychology of Money — Morgan Housel',
          description:
              '19 short stories about how people think about money and how to '
              'make better financial decisions. Timeless lessons on wealth, '
              'greed and happiness from a modern perspective.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/10521270-L.jpg',
        ),
        Video(
          id: 'book_zero_to_one',
          title: 'Zero to One — Peter Thiel',
          description:
              'Notes on startups and how to build the future. Peter Thiel '
              'reveals the contrarian truths about innovation and how the '
              'most valuable companies create something entirely new.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/8471611-L.jpg',
        ),
      ];

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
        final videos = await RssService.instance
            .fetchVideos(ch.id, forceRefresh: force);
        _videosByChannel[ch.id] = videos;
        successCount++;
      } on Exception catch (e) {
        debugPrint('[FeedProvider] Error fetching ${ch.name}: $e');
      }
    });
    await Future.wait(futures);

    _state = successCount > 0 ? FeedState.loaded : FeedState.error;
    _errorMessage = successCount == 0
        ? 'Could not load content. Check your connection.'
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
