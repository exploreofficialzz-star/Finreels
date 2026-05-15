import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/video.dart';

class RssService {
  RssService._();
  static final RssService instance = RssService._();

  // In-memory cache: channelId → (videos, fetchedAt)
  final Map<String, List<Video>> _cache = {};
  final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheTtl = Duration(minutes: 10);

  Future<List<Video>> fetchVideos(String channelId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheFresh(channelId)) {
      return _cache[channelId]!;
    }

    final url =
        'https://www.youtube.com/feeds/videos.xml?channel_id=$channelId';

    try {
      final response = await http
          .get(Uri.parse(url), headers: {
            'Accept': 'application/atom+xml,application/xml,text/xml',
            'User-Agent': 'FinReels/1.0 (+com.chastech.finreels)',
          })
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final videos = _parseRss(response.body, channelId);
      _cache[channelId] = videos;
      _cacheTime[channelId] = DateTime.now();
      return videos;
    } on Exception catch (_) {
      // Serve stale cache rather than crashing
      if (_cache.containsKey(channelId)) return _cache[channelId]!;
      rethrow;
    }
  }

  List<Video> _parseRss(String xmlBody, String channelId) {
    final doc = XmlDocument.parse(xmlBody);
    final entries = doc.findAllElements('entry');

    return entries.map((entry) {
      // Video ID
      final rawId =
          entry.findElements('yt:videoId').firstOrNull?.innerText ?? '';
      final fallbackId = _extractIdFromUrn(
          entry.findElements('id').firstOrNull?.innerText ?? '');
      final videoId = rawId.isNotEmpty ? rawId : fallbackId;

      // Title — decode HTML entities from CDATA
      final title =
          entry.findElements('title').firstOrNull?.innerText.trim() ??
              'Untitled';

      // Channel name
      final channelName = entry
              .findElements('author')
              .firstOrNull
              ?.findElements('name')
              .firstOrNull
              ?.innerText
              .trim() ??
          '';

      // Published date
      final pubStr =
          entry.findElements('published').firstOrNull?.innerText ?? '';
      final publishedAt = DateTime.tryParse(pubStr) ?? DateTime.now();

      // Thumbnail — prefer media:thumbnail url attribute
      final mediaThumb =
          entry.findElements('media:thumbnail').firstOrNull?.getAttribute('url')
              ?? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';

      // Description
      final description =
          entry.findElements('media:description').firstOrNull?.innerText.trim()
              ?? entry.findElements('summary').firstOrNull?.innerText.trim()
              ?? '';

      return Video(
        id: videoId,
        title: title,
        description: description,
        channelId: channelId,
        channelName: channelName,
        publishedAt: publishedAt,
        thumbnailUrl: mediaThumb,
      );
    }).where((v) => v.id.isNotEmpty).toList();
  }

  String _extractIdFromUrn(String urn) {
    // Format: yt:video:VIDEO_ID
    final match = RegExp(r'yt:video:(.+)$').firstMatch(urn);
    return match?.group(1) ?? '';
  }

  bool _isCacheFresh(String channelId) {
    if (!_cache.containsKey(channelId)) return false;
    return DateTime.now().difference(_cacheTime[channelId]!) < _cacheTtl;
  }

  void clearCache([String? channelId]) {
    if (channelId != null) {
      _cache.remove(channelId);
      _cacheTime.remove(channelId);
    } else {
      _cache.clear();
      _cacheTime.clear();
    }
  }
}
