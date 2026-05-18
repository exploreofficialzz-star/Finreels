import 'video.dart';

/// Fix 5 — Unified Feed Engine
/// Sealed hierarchy lets the ListView.builder switch cleanly on type.
sealed class FeedItem {
  const FeedItem();
}

/// A regular long-form video card with inline playback.
final class VideoFeedItem extends FeedItem {
  final Video video;
  const VideoFeedItem(this.video);
}

/// A horizontal shelf of 9:16 short-form clips.
/// Rendered as a horizontally scrolling carousel inline in the main feed.
final class ShortsShelfFeedItem extends FeedItem {
  final List<Video> shorts;
  const ShortsShelfFeedItem(this.shorts);
}

/// A book entry in the Books tab.
final class BookFeedItem extends FeedItem {
  final Video book;
  const BookFeedItem(this.book);
}
