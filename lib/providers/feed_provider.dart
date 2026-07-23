import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../data/channel_data.dart';
import '../data/resource_category_data.dart';
import '../models/channel.dart';
import '../models/feed_tab.dart';
import '../models/resource_category.dart' show VerifiedBook;
import '../models/video.dart';
import '../services/blog_rss_service.dart';
import '../services/engagement_service.dart';
import '../services/rss_service.dart';
import '../services/user_profile_service.dart';

enum FeedState { idle, loading, loaded, error }

class FeedProvider extends ChangeNotifier {
  FeedProvider() {
    // Books re-sort is cheap (no network) so it's safe to do live: clear
    // just that tab's cache and let it recompute next access. Channel
    // order (Videos/Shorts) intentionally stays "next launch only" — see
    // _buildSessionChannelOrder — since re-sorting those live would mean
    // touching the round-robin/session-order logic mid-scroll.
    UserProfileService.instance.addListener(_onProfileChanged);
  }

  void _onProfileChanged() {
    _tabCache.remove(FeedTab.books);
    // BlogRssService.combinedBlogFeeds is selection-scoped (general +
    // whatever categories are currently selected — see that file), so a
    // changed selection must drop its 10-minute cache too, or the Blogs tab
    // could keep showing the previous selection's articles for up to that
    // long after switching category.
    BlogRssService.instance.clearCache();
    notifyListeners();
    // Pulls in the newly-selected category's channels right away instead
    // of making the person wait for next app open. Silent = no loading
    // spinner flash; _eagerChannels() picks up the new selection itself.
    unawaited(refresh(force: true, silent: true));
  }

  @override
  void dispose() {
    UserProfileService.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

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

  // ── Session channel order ─────────────────────────────────────────────────
  // Shuffled once at FeedProvider construction (= once per app launch).
  // Stable within the session so refreshing doesn't reorder the feed.
  // Different every launch → fresh channel at the top each time the user opens.
  // Three layers, in priority order:
  //   1. Explicit "My Business" selection (UserProfileService) — strongest signal, the person said so directly.
  //   2. Learned engagement (EngagementService) — channels this person actually watches/saves rank higher.
  //   3. Shuffle — anything with no signal yet gets a fair, random shot at the top so discovery still happens.
  final List<String> _sessionChannelOrder = _buildSessionChannelOrder();

  // ── Eager-fetch scope ─────────────────────────────────────────────────
  // See ChannelData.eagerFor — general channels always fetched, category-
  // tagged channels only fetched if the user selected that category.
  static List<Channel> _eagerChannels() =>
      ChannelData.eagerFor(UserProfileService.instance.selectedCategoryIds);

  static List<String> _buildSessionChannelOrder() {
    final shuffled = _eagerChannels().map((c) => c.id).toList()..shuffle();
    final ranked = EngagementService.instance.sortByEngagement(shuffled);
    final selected = UserProfileService.instance.selectedCategoryIds;
    if (selected.isEmpty) return ranked;
    final boosted = ChannelData.combined
        .where((c) => selected.contains(c.resourceCategoryId))
        .map((c) => c.id)
        .toList();
    if (boosted.isEmpty) return ranked;
    ranked.removeWhere(boosted.contains);
    return [...boosted, ...ranked];
  }

  var _savedVideoIds = <String>{};

  List<Channel> get channels => ChannelData.combined;
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
      FeedTab.books  => List.unmodifiable(_allBookVideos),
    };
  }

  /// The original 10 hand-picked classics/playbooks, plus real named books
  /// pulled from assets/data/resources/{categoryId}.json — general ones
  /// (categoryId == null) always, and category-specific ones ONLY for
  /// categories the person actually selected (UserProfileService).
  ///
  /// This intentionally does NOT fall back to "show every category's books
  /// when nothing's selected" the way the old CategoryPlaybookData version
  /// did — a fashion designer must never see a doctor's books (or any other
  /// unselected category's) just because they haven't picked one yet.
  /// Skipping onboarding simply means "general books only" until they do.
  ///
  /// Selected-category books come first (the same "your stuff first"
  /// priority every other tab already gives a selected category), then the
  /// general library. No CategoryPlaybookData here any more — that generated
  /// "Business of X" content still exists (see CategoryDetailScreen's own
  /// "Read the Business Playbook" card, clearly labelled as FinReels
  /// Research) but it stopped being presented as a Book here, since it was
  /// close to identical filler for every Skill category and isn't a
  /// substitute for a real, named book.
  List<Video> get _allBookVideos {
    final selected = UserProfileService.instance.selectedCategoryIds;
    final verified = ResourceCategoryData.verifiedBooks.where(
      (b) => b.categoryId == null || selected.contains(b.categoryId),
    );
    final mine = <VerifiedBook>[];
    final general = <VerifiedBook>[];
    for (final b in verified) {
      (b.categoryId == null ? general : mine).add(b);
    }
    return [
      ...mine.map(_videoFromVerifiedBook),
      ..._bookVideos,
      ...general.map(_videoFromVerifiedBook),
    ];
  }

  static Video _videoFromVerifiedBook(VerifiedBook b) {
    final slug = '${b.categoryId ?? 'general'}_${b.title}'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final id = 'vbook_$slug';
    return Video(
      id: id,
      title: b.title,
      description: b.freeSourceNote != null
          ? '${b.author} · ${b.freeSourceNote}'
          : b.author,
      channelId: 'verified_book',
      channelName: b.author,
      publishedAt: _epoch,
      thumbnailUrl: '', // BookCoverImage falls back to a placeholder cover.
      freeSourceUrl: b.freeSourceUrl,
      freeSourceType: b.freeSourceType,
      sourceCategoryId: b.categoryId,
    );
  }

  List<Video> _roundRobin(List<Video> videos) {
    if (videos.isEmpty) return const [];
    final grouped = <String, List<Video>>{};
    for (final v in videos) { (grouped[v.channelId] ??= []).add(v); }
    for (final l in grouped.values) { l.sort((a, b) => b.publishedAt.compareTo(a.publishedAt)); }
    // Use the session channel order (shuffled once at launch, stable during session).
    // Filter to only channels that have content of this type, preserving session order.
    final keys = _sessionChannelOrder.where(grouped.containsKey).toList()
        ..addAll(grouped.keys.where((k) => !_sessionChannelOrder.contains(k)));
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

  bool _isBook(Video v) => v.channelId == 'books' || v.channelId == 'verified_book';

  // ── Books ─────────────────────────────────────────────────────────────────────

  static final _epoch = DateTime(2000);

  // static final → created exactly once, not on every access.
  static final List<Video> _bookVideos = [
    // ── Public domain classics — read in full via EPUB, free, no login ──────
    Video(id:'book_richest_man',
      title:'The Richest Man in Babylon — George S. Clason',
      description:'Timeless laws of money: pay yourself first, make money work for you.',
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://covers.openlibrary.org/b/isbn/9780451205360-L.jpg'),
    Video(id:'book_think_grow',
      title:'Think and Grow Rich — Napoleon Hill',
      description:"13 principles of wealth distilled from 500+ of history's most successful people.",
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://covers.openlibrary.org/b/isbn/9781585424337-L.jpg'),
    Video(id:'book_science_rich',
      title:'The Science of Getting Rich — Wallace D. Wattles',
      description:'The original 1910 law-of-attraction wealth blueprint that inspired The Secret.',
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://archive.org/services/img/science_gettingrich_1005_librivox'),
    Video(id:'book_art_money',
      title:'The Art of Money Getting — P. T. Barnum',
      description:"20 golden rules for making money from America's greatest showman (1880).",
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://www.globalgreyebooks.com/content/book-covers/p-t-barnum_art-of-money-getting.jpg'),
    Video(id:'book_as_man_thinketh',
      title:'As a Man Thinketh — James Allen',
      description:'How your thoughts shape your wealth, health, and circumstances (1903).',
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://covers.openlibrary.org/b/id/14828006-L.jpg'),
    Video(id:'book_eight_pillars',
      title:'Eight Pillars of Prosperity — James Allen',
      description:'Energy, economy, integrity, and five more virtues that build lasting wealth (1911).',
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://archive.org/services/img/eightpillarsofprosperity_1411_librivox'),
    Video(id:'book_master_key',
      title:'The Master Key System — Charles F. Haanel',
      description:'A 24-week course on mastering the mind to attract wealth and success (1912).',
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://covers.openlibrary.org/b/olid/OL25601790M-L.jpg'),
    Video(id:'book_popular_delusions',
      title:'Extraordinary Popular Delusions — Charles Mackay',
      description:'The tulip mania, South Sea bubble and how crowds go financially mad (1841).',
      channelId:'books',channelName:'Free Finance Library',publishedAt:_epoch,
      thumbnailUrl:'https://covers.openlibrary.org/b/id/8100251-L.jpg'),

    // ── Bundled masterclass playbooks — ship inside the app, fully offline ──
    Video(id:'book_five_buckets_playbook',
      title:'The Five Buckets: Build What They Can Never Take From You',
      description:'An encyclopedic masterclass on Knowledge, Skills, Network, Resources & Reputation — inspired by Steven Bartlett\'s 5-Bucket framework.',
      channelId:'books',channelName:'Masterclass Playbooks',publishedAt:_epoch,
      thumbnailUrl:'assets/books/five_buckets_playbook_cover.jpg'),
    Video(id:'book_five_buckets_complete',
      title:'The Five Buckets: A Field Manual for Unstoppable Success',
      description:'How to build unshakeable knowledge, master high-value skills, engineer powerful networks, command strategic resources, and forge a reputation that opens doors before you knock.',
      channelId:'books',channelName:'Masterclass Playbooks',publishedAt:_epoch,
      thumbnailUrl:'assets/books/five_buckets_complete_cover.jpg'),
  ];

  // ── Init ──────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadSaved();

    // 1. Load disk cache → instant first render (whatever we last had).
    await _loadDiskCache();
    final hasCached = _videosByChannel.isNotEmpty;

    // 2. ALWAYS force a true network refresh on app open. YouTube's RSS
    // feed always returns exactly the latest 15 videos per channel — this
    // forced refresh is what guarantees that "latest 15" window is
    // genuinely up to date every time the user opens the app, rather than
    // potentially serving a stale cached 15 from up to 30 minutes ago.
    // silent: true when we already have something on screen, so this
    // happens quietly in the background with no spinner flash.
    await refresh(force: true, silent: hasCached);
  }

  Future<void> _loadDiskCache() async {
    final snap = <String, List<Video>>{};
    for (final ch in ChannelData.combined) {
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

  DateTime? _lastForcedRefreshAt;

  /// [silent] = true → skip loading spinner, update quietly in background.
  /// Used on app resume and on init when cache is already visible.
  Future<void> refresh({bool force = false, bool silent = false}) async {
    if (!silent) {
      _state = FeedState.loading;
      _errorMessage = null;
      notifyListeners();
    }

    final channels = _eagerChannels();
    final snap = <String, List<Video>>{};

    // Staggered parallel: channel[i] waits i×200 ms before its first request.
    // All run concurrently inside Future.wait — total time ≈ slowest fetch.
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

    // snap COMPLETELY REPLACES _videosByChannel (not merged/appended) — this
    // is what ensures each channel's video list is always exactly its
    // current latest 15 from YouTube's RSS feed, never a stale mix of old
    // and new entries.
    _videosByChannel = Map.unmodifiable(snap);
    _tabCache.clear();
    _state = total > 0 ? FeedState.loaded : FeedState.error;
    _errorMessage = total == 0 ? 'Could not load content. Check your connection.' : null;

    if (force) _lastForcedRefreshAt = DateTime.now();

    notifyListeners();
  }

  /// Called when the app resumes from the background. Forces a true
  /// network refresh — but only if it's been a while since the last one,
  /// so rapid app-switching (checking a notification and coming straight
  /// back, for example) doesn't hammer YouTube's RSS endpoint with repeat
  /// requests every few seconds.
  Future<void> refreshOnResume() async {
    final last = _lastForcedRefreshAt;
    final dueForRefresh = last == null ||
        DateTime.now().difference(last) > const Duration(minutes: 3);
    if (!dueForRefresh) return;
    await refresh(force: true, silent: true);
  }

  // ── Saved ─────────────────────────────────────────────────────────────────────

  bool isVideoSaved(String id) => _savedVideoIds.contains(id);

  Future<void> toggleSaved(Video video) async {
    final wasSaved = _savedVideoIds.contains(video.id);
    wasSaved ? _savedVideoIds.remove(video.id) : _savedVideoIds.add(video.id);
    if (!wasSaved) {
      // Saving (not un-saving) is a stronger signal than just opening.
      unawaited(EngagementService.instance.recordSave(video));
    }
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
