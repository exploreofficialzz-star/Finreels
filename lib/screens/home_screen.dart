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
import '../widgets/shimmer_loader.dart';
import '../widgets/video_card.dart';
import 'video_player_screen.dart';

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
      height: 42,
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
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.gold
                      : AppTheme.surfaceColor(context),
                  borderRadius: BorderRadius.circular(20),
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
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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
  // Aggressive ad counter — interstitial every 1-2 taps
  int _tapCount = 0;

  void _onVideoTap(BuildContext context, Video video) {
    _tapCount++;
    // Show interstitial every 2nd tap
    if (_tapCount.isEven) {
      unawaited(AdService.instance.showInterstitial());
    }

    final channels = {for (final ch in ChannelData.all) ch.id: ch};
    final channel = channels[video.channelId] ?? ChannelData.all.first;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(video: video, channel: channel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();

    // Books tab — special UI
    if (provider.activeTab == FeedTab.books) {
      return _BooksGrid(onTap: (v) => _onVideoTap(context, v));
    }

    switch (provider.state) {
      case FeedState.idle:
      case FeedState.loading:
        if (provider.feedVideos.isEmpty) {
          return const ShimmerLoader();
        }
        return _buildList(context, provider);
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
        return _buildList(context, provider);
    }
  }

  Widget _buildList(BuildContext context, FeedProvider provider) {
    final videos = provider.feedVideos;
    final channels = {for (final ch in provider.channels) ch.id: ch};

    // Shorts tab — horizontal scrolling grid
    if (provider.activeTab == FeedTab.shorts) {
      return _ShortsGrid(
        videos: videos,
        channels: channels,
        onTap: (v) => _onVideoTap(context, v),
      );
    }

    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () => provider.refresh(force: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: videos.length,
        separatorBuilder: (_, i) {
          // Banner ad slot every 3 items
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
          final channel = channels[video.channelId] ?? ChannelData.all.first;
          return VideoCard(
            video: video,
            channel: channel,
            saved: provider.isVideoSaved(video.id),
            onTap: () => _onVideoTap(context, video),
            onSave: () => provider.toggleSaved(video),
            onShare: () => Share.share(
              '${video.title}\n${video.watchUrl}',
            ),
          );
        },
      ),
    );
  }
}

// ── Shorts Grid ───────────────────────────────────────────────────────────────
class _ShortsGrid extends StatelessWidget {
  final List<Video> videos;
  final Map<String, dynamic> channels; // Channel values
  final void Function(Video) onTap;

  const _ShortsGrid({
    required this.videos,
    required this.channels,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
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
        return _ShortCard(
          video: video,
          onTap: () => onTap(video),
        );
      },
    );
  }
}

class _ShortCard extends StatelessWidget {
  final Video video;
  final VoidCallback onTap;

  const _ShortCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              video.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.surfaceElevated(context),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            // Play icon
            const Center(
              child: Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white70, size: 42),
            ),
            // Title at bottom
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
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
    final provider = context.read<FeedProvider>();
    final books = provider.feedVideos;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final book = books[i];
        return GestureDetector(
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
                // Book cover
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
                // Info
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
                          child: const Text(
                            'FREE BOOK',
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
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
              ],
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
