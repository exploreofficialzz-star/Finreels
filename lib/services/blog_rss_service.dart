import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// A single parsed blog article from an RSS/Atom feed.
class BlogArticle {
  final String title;
  final String url;
  final String sourceName;
  final String? thumbnailUrl;
  final DateTime publishedAt;
  final String excerpt;

  const BlogArticle({
    required this.title,
    required this.url,
    required this.sourceName,
    required this.publishedAt,
    this.thumbnailUrl,
    this.excerpt = '',
  });
}

/// Finance RSS/Atom sources for the Blogs tab.
/// Uses the xml package (already in project) — no extra dependency.
const List<Map<String, String>> kBlogFeeds = [
  {
    'name': 'Investopedia',
    'url':
        'https://www.investopedia.com/feedbuilder/feed/getfeed?feedName=rss_headline',
  },
  {
    'name': 'MarketWatch',
    'url': 'https://feeds.content.dowjones.io/public/rss/mw_realtimeheadlines',
  },
  {
    'name': 'Reuters Business',
    'url': 'https://feeds.reuters.com/reuters/businessNews',
  },
];

class BlogRssService {
  BlogRssService._();
  static final BlogRssService instance = BlogRssService._();

  List<BlogArticle>? _cache;
  DateTime? _cacheTime;
  static const _cacheTtl = Duration(minutes: 10);

  bool get _isCacheFresh =>
      _cache != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTtl;

  Future<List<BlogArticle>> fetchAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheFresh) return _cache!;

    final futures = kBlogFeeds.map(
      (feed) => _fetchFeed(url: feed['url']!, sourceName: feed['name']!),
    );

    final results = await Future.wait(futures, eagerError: false);
    final articles = results.expand((l) => l).toList();
    final sorted = await compute(_sortArticles, articles);
    _cache = sorted;
    _cacheTime = DateTime.now();
    return sorted;
  }

  Future<List<BlogArticle>> _fetchFeed({
    required String url,
    required String sourceName,
  }) async {
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'FinReels/1.0 (+com.chastech.finreels)',
        'Accept': 'application/rss+xml, application/xml, text/xml',
      }).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return [];

      final body = response.body;
      // Typed list avoids unnecessary_cast warnings in compute callback
      return await compute<List<String>, List<BlogArticle>>(
        (args) => _parse(args[0], args[1]),
        [body, sourceName],
      );
    } on Exception catch (e) {
      debugPrint('[BlogRssService] $sourceName failed: $e');
      return [];
    }
  }

  /// Parses RSS 2.0 and Atom using the existing xml ^6.x package.
  static List<BlogArticle> _parse(String body, String sourceName) {
    try {
      final doc = XmlDocument.parse(body);

      // ── RSS 2.0 ──────────────────────────────────────────────────────────
      final rssItems = doc.findAllElements('item');
      if (rssItems.isNotEmpty) {
        return rssItems.map((item) {
          final link = _text(item, 'link') ?? _text(item, 'guid') ?? '';
          if (link.isEmpty) return null;

          String? thumb = item.findElements('enclosure').firstOrNull?.getAttribute('url');
          if (thumb == null || thumb.isEmpty) {
            thumb = item.findElements('media:content').firstOrNull?.getAttribute('url');
          }

          final pubStr = _text(item, 'pubDate') ?? '';
          final published = _parseRssDate(pubStr) ?? DateTime.now();

          return BlogArticle(
            title: _clean(_text(item, 'title') ?? 'Untitled'),
            url: link,
            sourceName: sourceName,
            thumbnailUrl: thumb,
            publishedAt: published,
            excerpt: _clean(_text(item, 'description') ?? ''),
          );
        }).whereType<BlogArticle>().toList();
      }

      // ── Atom ─────────────────────────────────────────────────────────────
      final atomEntries = doc.findAllElements('entry');
      if (atomEntries.isNotEmpty) {
        return atomEntries.map((entry) {
          final link =
              entry.findElements('link').firstOrNull?.getAttribute('href') ?? '';
          if (link.isEmpty) return null;

          final updStr =
              _text(entry, 'updated') ?? _text(entry, 'published') ?? '';
          final published = DateTime.tryParse(updStr) ?? DateTime.now();

          return BlogArticle(
            title: _clean(_text(entry, 'title') ?? 'Untitled'),
            url: link,
            sourceName: sourceName,
            publishedAt: published,
            excerpt: _clean(_text(entry, 'summary') ?? ''),
          );
        }).whereType<BlogArticle>().toList();
      }
    } on Exception catch (e) {
      debugPrint('[BlogRssService] Parse error for $sourceName: $e');
    }
    return [];
  }

  static String? _text(XmlElement el, String tag) =>
      el.findElements(tag).firstOrNull?.innerText.trim();

  static String _clean(String raw) => raw
      .replaceAll(RegExp('<[^>]*>'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Handles RFC 822 (RSS) and ISO 8601 (Atom) date strings.
  static DateTime? _parseRssDate(String s) {
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    // Strip "Wed, " prefix from RFC 822 and retry
    final trimmed = s.replaceFirst(RegExp(r'^[A-Za-z]+,\s*'), '');
    return DateTime.tryParse(trimmed);
  }

  static List<BlogArticle> _sortArticles(List<BlogArticle> articles) =>
      articles..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

  void clearCache() {
    _cache = null;
    _cacheTime = null;
  }
}
