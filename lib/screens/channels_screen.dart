import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/channel_data.dart';
import '../models/video.dart';
import '../providers/feed_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/shimmer_loader.dart';
import 'video_player_screen.dart';

/// Channels tab now shows YouTube Shorts from ALL channels in a grid.
class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  int _tapCount = 0;

  void _openVideo(Video video) {
    _tapCount++;
    if (_tapCount.isEven) unawaited(AdService.instance.showInterstitial());

    final channel = ChannelData.byId[video.channelId] ?? ChannelData.fallback;
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

    // Gather ALL videos and filter to shorts
    final allVideos = provider.channels
        .expand((ch) => provider.getVideosFor(ch.id))
        .toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    final shorts = allVideos.where((v) => _isShort(v)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shorts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.refresh(force: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildShortsGrid(context, shorts, provider.state),
          ),
          if (!AdService.instance.adsRemoved) const LabelledBannerAd(),
        ],
      ),
    );
  }

  bool _isShort(Video v) {
    final t = v.title.toLowerCase();
    final d = v.description.toLowerCase();
    return t.contains('#short') ||
        t.contains('shorts') ||
        d.contains('#shorts') ||
        t.contains('in 60') ||
        t.contains('in 30 ') ||
        // Videos with short titles tend to be Shorts
        v.title.length < 28;
  }

  Widget _buildShortsGrid(BuildContext context, List<Video> shorts, FeedState state) {
    if (state == FeedState.loading && shorts.isEmpty) {
      return const ShimmerLoader(count: 6);
    }
    if (shorts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_library_outlined,
                  size: 56, color: AppTheme.textMuted(context)),
              const SizedBox(height: 16),
              Text('No shorts yet — pull to refresh',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () =>
          context.read<FeedProvider>().refresh(force: true),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 110),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          // 9:16 ratio for vertical shorts
          childAspectRatio: 9 / 16,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: shorts.length,
        itemBuilder: (context, i) {
          final video = shorts[i];
          final channel =
              ChannelData.byId[video.channelId] ?? ChannelData.fallback;

          return _ShortCard(
            video: video,
            channelColor: channel.accentColor,
            onTap: () => _openVideo(video),
          );
        },
      ),
    );
  }
}

class _ShortCard extends StatelessWidget {
  final Video video;
  final Color channelColor;
  final VoidCallback onTap;

  const _ShortCard({
    required this.video,
    required this.channelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail — use mqdefault for 9:16 short thumbnails
            Image.network(
              video.thumbnailMq,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: AppTheme.surfaceElevated(context),
                child: Center(
                  child: Icon(Icons.play_circle_outline_rounded,
                      color: AppTheme.textMuted(context), size: 36),
                ),
              ),
            ),
            // Dark gradient
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
            // Channel accent line at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 3, color: channelColor),
            ),
            // Play button
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
            // Title
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
                  shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
