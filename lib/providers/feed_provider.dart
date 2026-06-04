
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

  Map<String, List<Video>> _videosByChannel = {};
  final Map<FeedTab, List<Video>> _tabCache = {};

  FeedTab _activeTab = FeedTab.videos;
  FeedTab get activeTab => _activeTab;

  /// All cached video lists across every tab — used for deep-link lookup.
  List<List<Video>> get allVideos => FeedTab.values
      .map((t) => _tabCache[t] ?? _compute(t))
      .toList();

  var _savedVideoIds = <String>{};

  List<Channel> get channels => ChannelData.all;
  List<Video> getVideosFor(String channelId) => _videosByChannel[channelId] ?? [];

  // ── Per-tab cached list ───────────────────────────────────────────────────────

  List<Video> get feedVideos => _tabCache[_activeTab] ??= _compute(_activeTab);

  List<Video> _compute(FeedTab tab) {
    final all = _videosByChannel.values.expand((v) => v).toList();
    return switch (tab) {
      FeedTab.videos =>
        _roundRobin(all.where((v) => !v.isShort && !_isBook(v)).toList()),
      FeedTab.shorts =>
        _roundRobin(all.where((v) => v.isShort && !_isBook(v)).toList()),
      FeedTab.blogs  =>
        _roundRobin(all.where((v) => _isBlog(v) && !_isBook(v)).toList()),
      FeedTab.books  => List.unmodifiable(_bookVideos),
    };
  }

  List<Video> _roundRobin(List<Video> videos) {
    if (videos.isEmpty) return const [];
    final grouped = <String, List<Video>>{};
    for (final v in videos) { (grouped[v.channelId] ??= []).add(v); }
    for (final l in grouped.values) { l.sort((a, b) => b.publishedAt.compareTo(a.publishedAt)); }
    // Stable sort by channelId — prevents channels reordering on every refresh
    final keys   = grouped.keys.toList()..sort();
    final maxLen = grouped.values.map((l) => l.length).fold(0, (a, b) => a > b ? a : b);
    final result = <Video>[];
    for (var i = 0; i < maxLen; i++) {
      for (final k in keys) {
        final l = grouped[k]!;
        if (i < l.length) result.add(l[i]);
      }
    }
    return List.unmodifiable(result);
  }

  // ── Content detection ─────────────────────────────────────────────────────────

  bool _isBlog(Video v) {
    if (v.isShort || _isBook(v)) return false;
    final t = v.title.toLowerCase();
    return t.startsWith('how to') || t.startsWith('why ') || t.startsWith('what ') ||
        RegExp(r'^\d+ (ways|tips|things|rules|reasons|lessons|steps|mistakes)').hasMatch(t) ||
        t.contains(' tips') || t.contains(' guide') || t.contains(' rules') ||
        t.contains(' lessons') || t.contains(' mistakes');
  }

  bool _isBook(Video v) => v.channelId == 'books';

  // ── Books ─────────────────────────────────────────────────────────────────────

  static final _epoch = DateTime(2000);

  // ── Books — static so cover URLs and objects are created exactly once ────────
  static final List<Video> _bookVideos = [
    Video(id:'book_richest_man',
      title:'The Richest Man in Babylon — George S. Clason',
      description:'Timeless laws of money: pay yourself first, make money work for you.',
      channelId:'books', channelName:'Free Finance Library', publishedAt:_epoch,
      // ISBN cover — confirmed working in previous build
      thumbnailUrl:'https://covers.openlibrary.org/b/isbn/9780451205360-L.jpg'),
    Video(id:'book_think_grow',
      title:'Think and Grow Rich — Napoleon Hill',
      description:"13 principles of wealth distilled from 500+ of history's most successful people.",
      channelId:'books', channelName:'Free Finance Library', publishedAt:_epoch,
      // ISBN cover — confirmed working in previous build
      thumbnailUrl:'https://covers.openlibrary.org/b/isbn/9781585424337-L.jpg'),
    Video(id:'book_science_rich',
      title:'The Science of Getting Rich — Wallace D. Wattles',
      description:'The original 1910 law-of-attraction wealth blueprint that inspired The Secret.',
      channelId:'books', channelName:'Free Finance Library', publishedAt:_epoch,
      // Cover ID 1992072 confirmed from Open Library og:image (OL8879112M)
      thumbnailUrl:'https://covers.openlibrary.org/b/id/1992072-L.jpg'),
    Video(id:'book_art_money',
      title:'The Art of Money Getting — P. T. Barnum',
      description:"20 golden rules for making money from America's greatest showman (1880).",
      channelId:'books', channelName:'Free Finance Library', publishedAt:_epoch,
      // GlobalGrey cover confirmed working in original build
      thumbnailUrl:'https://www.globalgreyebooks.com/content/book-covers/p-t-barnum_art-of-money-getting.jpg'),
    Video(id:'book_as_man_thinketh',
      title:'As a Man Thinketh — James Allen',
      description:'How your thoughts shape your wealth, health, and circumstances (1903).',
      channelId:'books', channelName:'Free Finance Library', publishedAt:_epoch,
      // Cover ID 14828006 confirmed from Open Library og:image
      thumbnailUrl:'https://covers.openlibrary.org/b/id/14828006-L.jpg'),
    Video(id:'book_eight_pillars',
      title:'Eight Pillars of Prosperity — James Allen',
      description:'Energy, economy, integrity, and five more virtues that build lasting wealth (1911).',
      channelId:'books', channelName:'Free Finance Library', publishedAt:_epoch,
      // Archive.org scanned book cover — reliable public domain thumbnail
      thumbnailUrl:'https://archive.org/services/img/eightpillarsofpr0000alle'),
    Video(id:'book_master_key',
      title:'The Master Key System — Charles F. Haanel',
      description:'A 24-week course on mastering the mind to attract wealth and success (1912).',
      channelId:'books', channelName:'Free Finance Library', publishedAt:_epoch,
      // Edition OLID confirmed from Open Library search: OL25601790M
      thumbnailUrl:'https://covers.openlibrary.org/b/olid/OL25601790M-L.jpg'),
    Video(id:'book_popular_delusions',
      title:'Extraordinary Popular Delusions — Charles Mackay',
      description:'The tulip mania, South Sea bubble and how crowds go financially mad (1841).',
      channelId:'books', channelName:'Free Finance Library', publishedAt:_epoch,
      // Cover ID 8100251 — confirmed working in the original version of this app
      thumbnailUrl:'https://covers.openlibrary.org/b/id/8100251-L.jpg'),
  ];

  // ── Init ──────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadSaved();

    // 1. Load disk cache → instant first render.
    await _loadDiskCache();
    final hasCached = _videosByChannel.isNotEmpty;

    // 2. Network refresh — silent (no spinner) if data already on screen.
    await refresh(silent: hasCached);
  }

  Future<void> _loadDiskCache() async {
    final snap = <String, List<Video>>{};
    for (final ch in ChannelData.all) {
      final cached = await RssService.instance.getCached(ch.id);
      if (cached.isNotEmpty) snap[ch.id] = cached;
    }
    if (snap.isNotEmpty) {
      _videosByChannel = Map.unmodifiable(snap);
      _tabCache.clear();
      _state = FeedState.loaded;
      notifyListeners();
    }
  }

  // ── Tab ───────────────────────────────────────────────────────────────────────

  void setTab(FeedTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  // ── Refresh ───────────────────────────────────────────────────────────────────

  /// [silent] = true → skip loading spinner, update quietly in background.
  /// Used on app resume and on init when cache is already visible.
  Future<void> refresh({bool force = false, bool silent = false}) async {
    if (!silent) {
      _state = FeedState.loading;
      _errorMessage = null;
      notifyListeners();
    }

    const channels = ChannelData.all;
    final snap = <String, List<Video>>{};

    // Staggered parallel: channel[i] waits i×200 ms before its first request.
    // All 10 run concurrently inside Future.wait — total time ≈ slowest fetch.
    // Stagger prevents burst; YouTube never sees >1 request per 200 ms.
    await Future.wait(
      List.generate(channels.length, (i) async {
        final ch = channels[i];
        snap[ch.id] = await RssService.instance.fetchVideos(
          ch.id,
          forceRefresh: force,
          staggerMs:    i * 200,
        );
      }),
    );

    final total = snap.values.fold(0, (s, l) => s + l.length);

    _videosByChannel = Map.unmodifiable(snap);
    _tabCache.clear();
    _state = total > 0 ? FeedState.loaded : FeedState.error;
    _errorMessage = total == 0 ? 'Could not load content. Check your connection.' : null;

    notifyListeners();
  }

  // ── Saved ─────────────────────────────────────────────────────────────────────

  bool isVideoSaved(String id) => _savedVideoIds.contains(id);

  Future<void> toggleSaved(Video video) async {
    _savedVideoIds.contains(video.id)
        ? _savedVideoIds.remove(video.id)
        : _savedVideoIds.add(video.id);
    await _persistSaved();
    notifyListeners();
  }

  List<Video> get savedVideos => _videosByChannel.values
      .expand((v) => v)
      .where((v) => _savedVideoIds.contains(v.id))
      .toList()
    ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _savedVideoIds = (prefs.getStringList(AppConfig.prefSavedVideos) ?? []).toSet();
  }

  Future<void> _persistSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConfig.prefSavedVideos, _savedVideoIds.toList());
  }
}
