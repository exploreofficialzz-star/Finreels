class Video {
  final String id;
  final String title;
  final String description;
  final String channelId;
  final String channelName;
  final DateTime publishedAt;
  final String thumbnailUrl;
  /// Original RSS link — YouTube Shorts have /shorts/ in this URL.
  final String? originalLink;

  const Video({
    required this.id,
    required this.title,
    required this.description,
    required this.channelId,
    required this.channelName,
    required this.publishedAt,
    required this.thumbnailUrl,
    this.originalLink,
  });

  /// True if this video is a YouTube Short.
  /// Primary signal: original RSS link contains /shorts/ path.
  /// Fallback: explicit #shorts hashtag in title or description.
  bool get isShort {
    if (originalLink != null && originalLink!.contains('/shorts/')) return true;
    final t = title.toLowerCase();
    final d = description.toLowerCase();
    return t.contains('#shorts') ||
        t.contains('#short') ||
        d.contains('#shorts') ||
        d.contains('#short') ||
        d.contains('/shorts/') ||
        d.contains('youtube.com/shorts');
  }

  String get watchUrl =>
      isShort ? 'https://www.youtube.com/shorts/$id'
               : 'https://www.youtube.com/watch?v=$id';

  /// Books (channelId == 'books') are not real YouTube videos — their `id`
  /// is a synthetic key like 'book_richest_man', so constructing a
  /// img.youtube.com URL from it would always 404. Books must use their
  /// own [thumbnailUrl] (which may be a network cover or a bundled asset
  /// path) everywhere a thumbnail is requested.
  String get thumbnailHd =>
      channelId == 'books' ? thumbnailUrl
                            : 'https://img.youtube.com/vi/$id/maxresdefault.jpg';
  String get thumbnailMq =>
      channelId == 'books' ? thumbnailUrl
                            : 'https://img.youtube.com/vi/$id/mqdefault.jpg';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'channelId': channelId,
        'channelName': channelName,
        'publishedAt': publishedAt.toIso8601String(),
        'thumbnailUrl': thumbnailUrl,
        if (originalLink != null) 'originalLink': originalLink,
      };

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        channelId: json['channelId'] as String,
        channelName: json['channelName'] as String,
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        thumbnailUrl: json['thumbnailUrl'] as String,
        originalLink: json['originalLink'] as String?,
      );

  @override
  bool operator ==(Object other) => other is Video && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
