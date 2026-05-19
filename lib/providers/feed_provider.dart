import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../data/channel_data.dart';
import '../models/channel.dart';
import '../models/feed_item.dart';
import '../models/feed_tab.dart';
import '../models/video.dart';
import '../services/rss_service.dart';

export '../models/feed_item.dart';

enum FeedState { idle, loading, loaded, error }

/// Fix 2 — Race Conditions & Content Shuffling
/// Key changes:
/// 1. refresh() collects ALL channel data first, then does a single atomic
///    setState (notifyListeners) — never mutates live data mid-render.
/// 2. feedVideos and unifiedFeedItems are cached snapshots computed once per
///    refresh, not re-shuffled on every getter access (which was the root cause
///    of cards jumping positions on every build).
/// 3. ValueKeys are assigned by the caller using video.id — stable across frames.
class FeedProvider extends ChangeNotifier {
  FeedState _state = FeedState.idle;
  FeedState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Immutable snapshot set atomically after each successful refresh.
  Map<String, List<Video>> _videosByChannel = {};

  // Per-tab stable caches — only invalidated on refresh.
  final Map<FeedTab, List<Video>> _tabCache = {};
  List<FeedItem>? _unifiedCache;

  FeedTab _activeTab = FeedTab.all;
  FeedTab get activeTab => _activeTab;

  var _savedVideoIds = <String>{};
  Set<String> get savedVideoIds => _savedVideoIds;

  List<Channel> get channels => ChannelData.all;

  List<Video> getVideosFor(String channelId) =>
      _videosByChannel[channelId] ?? [];

  // ── Stable per-tab feed ──────────────────────────────────────────────────────

  /// Returns a stable, cached list for the active tab.
  /// Computed once per refresh — never reshuffled on rebuild.
  List<Video> get feedVideos => _tabCache[_activeTab] ??= _compute(_activeTab);

  List<Video> _compute(FeedTab tab) {
    final all = _videosByChannel.values.expand((v) => v).toList();
    return switch (tab) {
      FeedTab.all => _interleave(all.where((v) => !_isBook(v)).toList()),
      FeedTab.videos =>
        _interleave(all.where((v) => !_isShort(v) && !_isBlog(v) && !_isBook(v)).toList()),
      FeedTab.shorts => _interleave(all.where(_isShort).toList()),
      FeedTab.blogs => _interleave(all.where((v) => _isBlog(v) && !_isBook(v)).toList()),
      FeedTab.books => _bookVideos,
    };
  }

  // ── Fix 5 — Unified feed items (All tab) ─────────────────────────────────────

  /// Returns the unified feed for the All tab: regular videos interleaved
  /// with a horizontal shorts shelf every 4 video items.
  List<FeedItem> get unifiedFeedItems {
    if (_unifiedCache != null) return _unifiedCache!;

    final all = _videosByChannel.values.expand((v) => v).toList();
    final videos = _interleave(
        all.where((v) => !_isShort(v) && !_isBook(v)).toList());
    final shorts = _interleave(all.where(_isShort).toList());

    final items = <FeedItem>[];
    var shortsOffset = 0;
    const shelfSize = 8;
    const videosBetweenShelves = 4;

    for (var i = 0; i < videos.length; i++) {
      items.add(VideoFeedItem(videos[i]));
      // Insert a shorts shelf every N videos if shorts remain.
      if ((i + 1) % videosBetweenShelves == 0 && shortsOffset < shorts.length) {
        final end = (shortsOffset + shelfSize).clamp(0, shorts.length);
        items.add(ShortsShelfFeedItem(shorts.sublist(shortsOffset, end)));
        shortsOffset = end;
      }
    }

    _unifiedCache = List.unmodifiable(items);
    return _unifiedCache!;
  }

  // ── Interleave (stable — no random shuffle on every access) ──────────────────

  /// Groups videos by channel, sorts each group newest-first, then
  /// round-robin interleaves them. The channel order is sorted by ID
  /// so the result is deterministic for the same data.
  List<Video> _interleave(List<Video> videos) {
    if (videos.isEmpty) return const [];

    final grouped = <String, List<Video>>{};
    for (final v in videos) {
      (grouped[v.channelId] ??= []).add(v);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    }

    final keys = grouped.keys.toList()..sort(); // stable order
    final maxLen = grouped.values.map((l) => l.length).fold(0, max);
    final result = <Video>[];

    for (var i = 0; i < maxLen; i++) {
      for (final key in keys) {
        final list = grouped[key]!;
        if (i < list.length) result.add(list[i]);
      }
    }
    return List.unmodifiable(result);
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

  bool _isBlog(Video v) {
    if (_isShort(v)) return false;
    final t = v.title.toLowerCase();
    return t.startsWith('how to') ||
        t.startsWith('why ') ||
        t.startsWith('what ') ||
        RegExp(r'^\d+ (ways|tips|things|rules|reasons|lessons|steps|mistakes)')
            .hasMatch(t) ||
        t.contains(' tips ') ||
        t.contains(' guide') ||
        t.contains(' rules') ||
        t.contains(' lessons') ||
        t.contains(' mistakes') ||
        t.contains(' steps to');
  }

  bool _isBook(Video v) => v.channelId == 'books';

  // ── Free books ────────────────────────────────────────────────────────────────

  static final _epoch = DateTime(2000);

  List<Video> get _bookVideos => [
        // ── Wealth Building ────────────────────────────────────────────────────
        Video(
          id: 'book_richest_man',
          title: 'The Richest Man in Babylon — George S. Clason',
          description:
              'Classic personal finance parables set in ancient Babylon. '
              'Timeless laws of money: pay yourself first, make money work '
              'for you, protect your wealth. The oldest wealth advice that still works.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/8739161-L.jpg',
        ),
        Video(
          id: 'book_think_grow',
          title: 'Think and Grow Rich — Napoleon Hill',
          description:
              'Napoleon Hill studied 500+ of the most successful people in history '
              'and distilled 13 principles of wealth. The definitive success mindset '
              'book. A must-read for every entrepreneur.',
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
              'middle class do not. The most-read personal finance book ever. '
              'Teaches assets vs liabilities and the mindset shift needed to build wealth.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/9253566-L.jpg',
        ),
        Video(
          id: 'book_psychology_money',
          title: 'The Psychology of Money — Morgan Housel',
          description:
              '19 short stories on how people think about money. Timeless lessons '
              'on wealth, greed and happiness. Shows why behaviour matters more '
              'than knowledge when building long-term wealth.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/10521270-L.jpg',
        ),
        Video(
          id: 'book_millionaire_next_door',
          title: 'The Millionaire Next Door — Thomas Stanley',
          description:
              "The surprising truth about America's wealthy. Most millionaires "
              'live below their means and build quietly. Real research on how '
              'ordinary people build extraordinary net worth over time.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/8091016-L.jpg',
        ),
        Video(
          id: 'book_intelligent_investor',
          title: 'The Intelligent Investor — Benjamin Graham',
          description:
              "Warren Buffett's favourite book and the bible of value investing. "
              'Teaches margin of safety and long-term thinking. '
              'Every serious investor must read this classic.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/8235963-L.jpg',
        ),
        // ── Entrepreneurship & Business ────────────────────────────────────────
        Video(
          id: 'book_zero_to_one',
          title: 'Zero to One — Peter Thiel',
          description:
              'Peter Thiel reveals contrarian truths about building the future. '
              'The secret to a successful startup is creating something new — '
              'going from 0 to 1, not copying what already exists.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/8471611-L.jpg',
        ),
        Video(
          id: 'book_100m_offers',
          title: r'$100M Offers — Alex Hormozi',
          description:
              'How to make offers so good people feel stupid saying no. '
              'Alex Hormozi breaks down the exact framework he used to build '
              r'a $100M+ portfolio. The best sales and offer book written.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/13166048-L.jpg',
        ),
        Video(
          id: 'book_e_myth',
          title: 'The E-Myth Revisited — Michael Gerber',
          description:
              'Why most small businesses fail and what to do about it. '
              'The myth: entrepreneurs start businesses. The reality: they get '
              'trapped working IN them. Learn to work ON your business instead.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/7888438-L.jpg',
        ),
        Video(
          id: 'book_10x_rule',
          title: 'The 10X Rule — Grant Cardone',
          description:
              'Success is your duty, obligation and responsibility. Grant Cardone '
              'reveals why you must set targets 10x higher than you think you need '
              'and take 10x the action. The formula for massive success.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/8739700-L.jpg',
        ),
        // ── Personal Growth & Mindset ──────────────────────────────────────────
        Video(
          id: 'book_atomic_habits',
          title: 'Atomic Habits — James Clear',
          description:
              'Tiny changes, remarkable results. The most practical book ever '
              'written on building good habits and breaking bad ones. '
              'The 1% better every day framework that compounds into life-changing results.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/10348396-L.jpg',
        ),
        Video(
          id: 'book_compound_effect',
          title: 'The Compound Effect — Darren Hardy',
          description:
              'Small, consistent actions compounding over time produce extraordinary '
              'results. Darren Hardy, SUCCESS magazine publisher, reveals the '
              'strategy responsible for every top performer\'s success.',
          channelId: 'books',
          channelName: 'Free Finance Library',
          publishedAt: _epoch,
          thumbnailUrl: 'https://covers.openlibrary.org/b/id/8692432-L.jpg',
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

  // ── Fetch — Fix 2: single atomic update ──────────────────────────────────────

  Future<void> refresh({bool force = false}) async {
    _state = FeedState.loading;
    _errorMessage = null;
    notifyListeners();

    // Collect ALL channel data into a local map first.
    // Never mutate _videosByChannel while the UI is reading it.
    final snapshot = <String, List<Video>>{};
    var successCount = 0;

    await Future.wait(ChannelData.all.map((ch) async {
      // fetchVideos never throws — it returns [] on any error.
      // Count every response (even empty) as a success so one bad channel
      // ID cannot push us into the error state.
      final videos =
          await RssService.instance.fetchVideos(ch.id, forceRefresh: force);
      snapshot[ch.id] = videos;
      if (videos.isNotEmpty) successCount++;
    }));

    // Single atomic assignment + cache invalidation — no partial renders.
    _videosByChannel = Map.unmodifiable(snapshot);
    _tabCache.clear();
    _unifiedCache = null;

    final totalVideos = snapshot.values.fold(0, (sum, l) => sum + l.length);
    _state = totalVideos > 0 ? FeedState.loaded : FeedState.error;
    _errorMessage = totalVideos == 0
        ? 'Could not load content. Check your connection.'
        : null;
    notifyListeners(); // Single notify — UI rebuilds once with complete data.
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
