import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../data/resource_category_data.dart';

/// A single parsed blog article from an RSS/Atom feed.
class BlogArticle {
  final String title;
  final String url;
  final String sourceName;
  final String? thumbnailUrl;
  final DateTime publishedAt;
  final String excerpt;

  /// Which of the 60 categories this feed is tagged to, if any — see
  /// verified_resources.json. Null for the 5 general-purpose feeds.
  final String? categoryId;

  const BlogArticle({
    required this.title,
    required this.url,
    required this.sourceName,
    required this.publishedAt,
    this.thumbnailUrl,
    this.excerpt = '',
    this.categoryId,
  });
}

/// Business, wealth and personal-growth RSS sources.
/// Replaces the previous news-heavy lineup (MarketWatch, Reuters).
const List<Map<String, String>> kBlogFeeds = [
  {
    'name': 'Entrepreneur',
    'url': 'https://www.entrepreneur.com/latest.rss',
  },
  {
    'name': 'Inc. Magazine',
    'url': 'https://www.inc.com/rss/',
  },
  {
    'name': 'Forbes Entrepreneurs',
    'url': 'https://www.forbes.com/entrepreneurs/feed/',
  },
  {
    'name': 'Harvard Business Review',
    'url': 'https://feeds.hbr.org/harvardbusiness',
  },
  {
    'name': 'Seth Godin',
    'url': 'https://seths.blog/feed/',
  },
];

/// [kBlogFeeds] above are the 5 general-purpose feeds. This adds every
/// category-tagged blog verified so far (see
/// assets/data/verified_resources.json). BlogRssService.fetchAll() reads
/// this combined list, not the bare constant, so newly-verified blogs
/// show up automatically.
List<Map<String, String>> get combinedBlogFeeds =>
    [...kBlogFeeds, ...ResourceCategoryData.verifiedBlogs];

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

    final futures = combinedBlogFeeds.map(
      (feed) => _fetchFeed(
        url: feed['url']!,
        sourceName: feed['name']!,
        categoryId: feed['categoryId'],
      ),
    );

    final results = await Future.wait(futures);
    final articles = results.expand((l) => l).toList();
    final sorted = await compute(_sortArticles, articles);
    _cache = sorted;
    _cacheTime = DateTime.now();
    return sorted;
  }

  Future<List<BlogArticle>> _fetchFeed({
    required String url,
    required String sourceName,
    String? categoryId,
  }) async {
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'FinReels/1.0 (+com.chastech.finreels)',
        'Accept': 'application/rss+xml, application/xml, text/xml',
      }).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return [];

      final body = response.body;
      return await compute<List<String>, List<BlogArticle>>(
        (args) => _parse(args[0], args[1], args[2].isEmpty ? null : args[2]),
        [body, sourceName, categoryId ?? ''],
      );
    } on Exception catch (e) {
      debugPrint('[BlogRssService] $sourceName failed: $e');
      return [];
    }
  }

  static List<BlogArticle> _parse(String body, String sourceName, [String? categoryId]) {
    try {
      final doc = XmlDocument.parse(body);

      // ── RSS 2.0 ──────────────────────────────────────────────────────────
      final rssItems = doc.findAllElements('item');
      if (rssItems.isNotEmpty) {
        return rssItems.map((item) {
          final link = _text(item, 'link') ?? _text(item, 'guid') ?? '';
          if (link.isEmpty) return null;

          var thumb = item.findElements('enclosure').firstOrNull
              ?.getAttribute('url');
          if (thumb == null || thumb.isEmpty) {
            thumb = item.findElements('media:content').firstOrNull
                ?.getAttribute('url');
          }
          // Try og:image or media:thumbnail
          if (thumb == null || thumb.isEmpty) {
            thumb = item.findElements('media:thumbnail').firstOrNull
                ?.getAttribute('url');
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
            categoryId: categoryId,
          );
        }).whereType<BlogArticle>().toList();
      }

      // ── Atom ─────────────────────────────────────────────────────────────
      final atomEntries = doc.findAllElements('entry');
      if (atomEntries.isNotEmpty) {
        return atomEntries.map((entry) {
          final link = entry.findElements('link').firstOrNull
              ?.getAttribute('href') ?? '';
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
            categoryId: categoryId,
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

  static DateTime? _parseRssDate(String s) {
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
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
