import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/channel_data.dart';
import '../models/feed_tab.dart';
import '../models/video.dart';
import '../providers/feed_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/inline_video_card.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/video_card.dart';
import 'blog_feed_screen.dart';
import 'book_detail_screen.dart';
import 'shorts_player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AppHeader(),
            _FeedTabBar(),
            const Expanded(child: _FeedBody()),
          ],
        ),
      ),
    );
  }
}

// ── App Header ────────────────────────────────────────────────────────────────
class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.gold,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.black, size: 22),
          ),
          const SizedBox(width: 10),
          Text(
            'FinReels',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: AppTheme.textMuted(context)),
            onPressed: () =>
                context.read<FeedProvider>().refresh(force: true),
          ),
        ],
      ),
    );
  }
}

// ── Feed Tab Bar ──────────────────────────────────────────────────────────────
class _FeedTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();
    final active = provider.activeTab;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: FeedTab.values.map((tab) {
          final isActive = tab == active;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => provider.setTab(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.gold
                      : AppTheme.surfaceColor(context),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.gold
                        : AppTheme.dividerColor(context),
                  ),
                ),
                child: Text(
                  tab.label,
                  style: TextStyle(
                    color: isActive
                        ? Colors.black
                        : AppTheme.textSecondary(context),
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Feed Body ─────────────────────────────────────────────────────────────────
class _FeedBody extends StatefulWidget {
  const _FeedBody();

  @override
  State<_FeedBody> createState() => _FeedBodyState();
}

class _FeedBodyState extends State<_FeedBody> {
  int _tapCount = 0;
  // Active video for single-playback enforcement in feed
  String? _activeVideoId;

  void _onVideoTap(BuildContext context, Video video) {
    _tapCount++;
    if (_tapCount.isEven) {
      unawaited(AdService.instance.showInterstitial());
    }

    if (video.channelId == 'books') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailScreen(book: video)),
      );
      return;
    }
    // Shorts from the feed grid navigate to full-screen shorts player
    final provider = context.read<FeedProvider>();
    if (provider.activeTab == FeedTab.shorts) {
      final shorts = provider.feedVideos;
      final idx = shorts.indexOf(video);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShortsPlayerScreen(
            shorts: shorts,
            initialIndex: idx < 0 ? 0 : idx,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();

    // Blogs tab — real RSS feed
    if (provider.activeTab == FeedTab.blogs) {
      return const BlogFeedScreen();
    }

    // Books tab
    if (provider.activeTab == FeedTab.books) {
      return _BooksGrid(onTap: (v) => _onVideoTap(context, v));
    }

    // Shorts tab — vertical grid, tapping opens full-screen player
    if (provider.activeTab == FeedTab.shorts) {
      final shorts = provider.feedVideos;
      if (provider.state == FeedState.loading && shorts.isEmpty) {
        return const ShimmerLoader();
      }
      return _ShortsGrid(
        videos: shorts,
        onTap: (v) => _onVideoTap(context, v),
        onRefresh: () => provider.refresh(force: true),
      );
    }

    // All / Videos — inline playback feed
    switch (provider.state) {
      case FeedState.idle:
      case FeedState.loading:
        if (provider.feedVideos.isEmpty) return const ShimmerLoader();
        return _buildInlineFeed(context, provider);
      case FeedState.error:
        return _ErrorView(
          message: provider.errorMessage ?? 'Something went wrong.',
          onRetry: () => provider.refresh(force: true),
        );
      case FeedState.loaded:
        if (provider.feedVideos.isEmpty) {
          return Center(
            child: Text(
              'No ${provider.activeTab.label.toLowerCase()} found.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return _buildInlineFeed(context, provider);
    }
  }

  /// Inline feed — videos play inside cards, one at a time.
  Widget _buildInlineFeed(BuildContext context, FeedProvider provider) {
    final videos = provider.feedVideos;

    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () => provider.refresh(force: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: videos.length,
        separatorBuilder: (_, i) {
          if ((i + 1) % 3 == 0) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: LabelledBannerAd(),
            );
          }
          return const SizedBox(height: 14);
        },
        itemBuilder: (context, i) {
          final video = videos[i];
          final channel =
              ChannelData.byId[video.channelId] ?? ChannelData.fallback;
          return InlineVideoCard(
            key: ValueKey(video.id),
            video: video,
            channel: channel,
            saved: provider.isVideoSaved(video.id),
            activeVideoId: _activeVideoId,
            onBecomeVisible: (id) {
              if (_activeVideoId != id) {
                setState(() => _activeVideoId = id);
              }
            },
            onSave: () => provider.toggleSaved(video),
            onShare: () =>
                Share.share('${video.title}\n${video.watchUrl}'),
          );
        },
      ),
    );
  }
}

// ── Shorts Grid ───────────────────────────────────────────────────────────────
class _ShortsGrid extends StatelessWidget {
  final List<Video> videos;
  final void Function(Video) onTap;
  final Future<void> Function() onRefresh;

  const _ShortsGrid({
    required this.videos,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return Center(
        child: Text('No shorts found.',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 9 / 16,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: videos.length,
        itemBuilder: (context, i) {
          final video = videos[i];
          final channel =
              ChannelData.byId[video.channelId] ?? ChannelData.fallback;
          return RepaintBoundary(
            child: GestureDetector(
              onTap: () => onTap(video),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.thumbnailMq,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: AppTheme.surfaceElevated(context),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                          stops: [0.45, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(height: 3, color: channel.accentColor),
                    ),
                    const Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 4)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Books Grid ────────────────────────────────────────────────────────────────
class _BooksGrid extends StatelessWidget {
  final void Function(Video) onTap;
  const _BooksGrid({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final books = context.read<FeedProvider>().feedVideos;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final book = books[i];
        return RepaintBoundary(
          child: GestureDetector(
            onTap: () => onTap(book),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.dividerColor(context), width: 0.5),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      bottomLeft: Radius.circular(13),
                    ),
                    child: Image.network(
                      book.thumbnailUrl,
                      width: 90,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 120,
                        color: AppTheme.gold.withValues(alpha: 0.15),
                        child: const Icon(Icons.menu_book_rounded,
                            color: AppTheme.gold, size: 36),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('📚 FREE BOOK',
                                style: TextStyle(
                                  color: AppTheme.gold,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                )),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.35),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            book.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textMuted(context)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: AppTheme.textMuted(context)),
            const SizedBox(height: 20),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
