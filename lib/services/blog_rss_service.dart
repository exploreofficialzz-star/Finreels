import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

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

/// RSS feed sources for the Blogs tab.
/// All URLs support HTTP so cleartext traffic must be enabled in the manifest.
const List<Map<String, String>> kBlogFeeds = [
  {
    'name': 'Investopedia',
    'url': 'https://www.investopedia.com/feedbuilder/feed/getfeed?feedName=rss_headline',
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

  // 10-minute in-memory cache
  List<BlogArticle>? _cache;
  DateTime? _cacheTime;
  static const _cacheTtl = Duration(minutes: 10);

  bool get _isCacheFresh =>
      _cache != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTtl;

  Future<List<BlogArticle>> fetchAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheFresh) return _cache!;

    // Run all feed fetches in parallel
    final futures = kBlogFeeds.map((feed) => _fetchFeed(
          url: feed['url']!,
          sourceName: feed['name']!,
        ));

    final results = await Future.wait(futures, eagerError: false);
    final articles = results.expand((list) => list).toList();

    // Sort newest first — offload to compute so UI thread is free
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
      final response = await http
          .get(Uri.parse(url), headers: {
            'User-Agent': 'FinReels/1.0 (+com.chastech.finreels)',
            'Accept': 'application/rss+xml, application/xml, text/xml',
          })
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return [];

      // Parse on background thread to avoid jank
      final body = response.body;
      return await compute(
        (args) => _parseBody(args[0] as String, args[1] as String),
        [body, sourceName],
      );
    } catch (e) {
      debugPrint('[BlogRssService] Failed to fetch $sourceName: $e');
      return [];
    }
  }

  static List<BlogArticle> _parseBody(String body, String sourceName) {
    try {
      // Try RSS first, fall back to Atom
      RssFeed? rss;
      AtomFeed? atom;
      try {
        rss = RssFeed.parse(body);
      } catch (_) {
        atom = AtomFeed.parse(body);
      }

      if (rss != null) {
        return (rss.items ?? []).map((item) {
          final url = item.link ?? '';
          if (url.isEmpty) return null;

          // Extract first image from enclosure or media content
          String? thumb = item.enclosure?.url;
          if (thumb == null || thumb.isEmpty) {
            // Try media:content
            final media = item.media?.contents;
            if (media != null && media.isNotEmpty) {
              thumb = media.first.url;
            }
          }

          return BlogArticle(
            title: _clean(item.title ?? 'Untitled'),
            url: url,
            sourceName: sourceName,
            thumbnailUrl: thumb,
            publishedAt: item.pubDate ?? DateTime.now(),
            excerpt: _clean(item.description ?? ''),
          );
        }).whereType<BlogArticle>().toList();
      }

      if (atom != null) {
        return (atom.items ?? []).map((item) {
          final url = item.links?.firstOrNull?.href ?? '';
          if (url.isEmpty) return null;

          return BlogArticle(
            title: _clean(item.title ?? 'Untitled'),
            url: url,
            sourceName: sourceName,
            thumbnailUrl: null,
            publishedAt: item.updated ?? DateTime.now(),
            excerpt: _clean(item.summary ?? ''),
          );
        }).whereType<BlogArticle>().toList();
      }
    } catch (e) {
      debugPrint('[BlogRssService] Parse error for $sourceName: $e');
    }
    return [];
  }

  /// Strip HTML tags and trim whitespace from feed text.
  static String _clean(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<BlogArticle> _sortArticles(List<BlogArticle> articles) {
    articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return articles;
  }

  void clearCache() {
    _cache = null;
    _cacheTime = null;
  }
}
