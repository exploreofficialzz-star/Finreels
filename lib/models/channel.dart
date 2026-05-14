import 'package:flutter/material.dart';

class Channel {
  final String id;
  final String name;
  final String handle;
  final String description;
  final Color accentColor;
  final String category;
  final String focus;
  final String initials;

  const Channel({
    required this.id,
    required this.name,
    required this.handle,
    required this.description,
    required this.accentColor,
    required this.category,
    required this.focus,
    required this.initials,
  });

  String get rssUrl =>
      'https://www.youtube.com/feeds/videos.xml?channel_id=$id';

  String get channelUrl => 'https://www.youtube.com/channel/$id';

  String get youtubeHandle => 'https://www.youtube.com/$handle';
}
