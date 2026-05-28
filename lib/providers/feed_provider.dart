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

  Map<String, List<Video>> _videosByChannel = {};
  final Map<FeedTab, List<Video>> _tabCache = {};

  FeedTab _activeTab = FeedTab.videos;
  FeedTab get activeTab => _activeTab;

  final _random = Random();
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
      FeedTab.books  => _bookVideos,
    };
  }

  List<Video> _roundRobin(List<Video> videos) {
    if (videos.isEmpty) return const [];
    final grouped = <String, List<Video>>{};
    for (final v in videos) { (grouped[v.channelId] ??= []).add(v); }
    for (final l in grouped.values) { l.sort((a, b) => b.publishedAt.compareTo(a.publishedAt)); }
    final keys   = grouped.keys.toList()..shuffle(_random);
    final maxLen = grouped.values.map((l) => l.length).fold(0, max);
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

  List<Video> get _bookVideos => [
    Video(id:'book_richest_man',title:'The Richest Man in Babylon — George S. Clason',
      description:'Timeless laws of money: pay yourself first, make money work for you.',
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://covers.openlibrary.org/b/id/8739161-L.jpg'),
    Video(id:'book_think_grow',title:'Think and Grow Rich — Napoleon Hill',
      description:'13 principles of wealth distilled from 500+ successful people.',
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://covers.openlibrary.org/b/id/8739505-L.jpg'),
    Video(id:'book_rich_dad',title:'Rich Dad Poor Dad — Robert Kiyosaki',
      description:'Assets vs liabilities and the mindset shift to build wealth.',
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://covers.openlibrary.org/b/id/9253566-L.jpg'),
    Video(id:'book_psychology_money',title:'The Psychology of Money — Morgan Housel',
      description:'19 short stories on wealth, greed and happiness.',
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://covers.openlibrary.org/b/id/10521270-L.jpg'),
    Video(id:'book_intelligent_investor',title:'The Intelligent Investor — Benjamin Graham',
      description:"Warren Buffett's favourite book. The bible of value investing.",
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://covers.openlibrary.org/b/id/8235963-L.jpg'),
    Video(id:'book_zero_to_one',title:'Zero to One — Peter Thiel',
      description:'Contrarian truths about building the future from scratch.',
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://covers.openlibrary.org/b/id/8471611-L.jpg'),
    Video(id:'book_100m_offers',title:r'$100M Offers — Alex Hormozi',
      description:'How to make offers so good people feel stupid saying no.',
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://covers.openlibrary.org/b/id/13166048-L.jpg'),
    Video(id:'book_atomic_habits',title:'Atomic Habits — James Clear',
      description:'Tiny changes, remarkable results. The 1% better every day framework.',
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://covers.openlibrary.org/b/id/10348396-L.jpg'),
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
