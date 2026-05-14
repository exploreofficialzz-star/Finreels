class Video {
  final String id;
  final String title;
  final String description;
  final String channelId;
  final String channelName;
  final DateTime publishedAt;
  final String thumbnailUrl;

  const Video({
    required this.id,
    required this.title,
    required this.description,
    required this.channelId,
    required this.channelName,
    required this.publishedAt,
    required this.thumbnailUrl,
  });

  String get watchUrl => 'https://www.youtube.com/watch?v=$id';
  String get thumbnailHd => 'https://img.youtube.com/vi/$id/maxresdefault.jpg';
  String get thumbnailMq => 'https://img.youtube.com/vi/$id/mqdefault.jpg';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'channelId': channelId,
        'channelName': channelName,
        'publishedAt': publishedAt.toIso8601String(),
        'thumbnailUrl': thumbnailUrl,
      };

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        channelId: json['channelId'] as String,
        channelName: json['channelName'] as String,
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        thumbnailUrl: json['thumbnailUrl'] as String,
      );

  @override
  bool operator ==(Object other) => other is Video && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
