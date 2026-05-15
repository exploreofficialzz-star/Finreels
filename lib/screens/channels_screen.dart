import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/channel_data.dart';
import '../models/channel.dart';
import '../models/video.dart';
import '../providers/feed_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/video_card.dart';
import 'video_player_screen.dart';

class ChannelsScreen extends StatelessWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Channels')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: ChannelData.all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _ChannelTile(channel: ChannelData.all[i]),
            ),
          ),
          if (!AdService.instance.adsRemoved) const LabelledBannerAd(),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  const _ChannelTile({required this.channel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChannelDetailScreen(channel: channel),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppTheme.dividerColor(context), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: channel.accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: channel.accentColor.withValues(alpha: 0.4),
                    width: 1.5),
              ),
              child: Center(
                child: Text(
                  channel.initials,
                  style: TextStyle(
                    color: channel.accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(channel.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: channel.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      channel.category,
                      style: TextStyle(
                          color: channel.accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(channel.focus,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted(context)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHANNEL DETAIL — shows latest videos + shorts from that channel
// ─────────────────────────────────────────────────────────────────────────────
class ChannelDetailScreen extends StatefulWidget {
  final Channel channel;
  const ChannelDetailScreen({required this.channel, super.key});

  @override
  State<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends State<ChannelDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tapCount = 0;

  Channel get ch => widget.channel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openVideo(Video video) {
    _tapCount++;
    if (_tapCount % 2 == 0) {
      unawaited(AdService.instance.showInterstitial());
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(video: video, channel: ch),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();
    final allVideos = provider.getVideosFor(ch.id);
    final shorts =
        allVideos.where((v) => v.title.length < 30).toList();
    final videos =
        allVideos.where((v) => v.title.length >= 30).toList();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: TabBar(
              controller: _tabController,
              indicatorColor: ch.accentColor,
              labelColor: ch.accentColor,
              unselectedLabelColor: AppTheme.textMuted(context),
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Videos'),
                Tab(text: 'Shorts'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _VideoList(
                videos: videos,
                channel: ch,
                provider: provider,
                onTap: _openVideo),
            _ShortsList(
                videos: shorts,
                channel: ch,
                provider: provider,
                onTap: _openVideo),
          ],
        ),
      ),
      bottomNavigationBar:
          AdService.instance.adsRemoved ? null : const LabelledBannerAd(),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ch.accentColor.withValues(alpha: 0.8),
                ch.accentColor.withValues(alpha: 0.25),
                AppTheme.bgColor(context),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: ch.accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ch.accentColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(ch.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(ch.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                        Text(ch.handle,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoList extends StatelessWidget {
  final List<Video> videos;
  final Channel channel;
  final FeedProvider provider;
  final void Function(Video) onTap;

  const _VideoList({
    required this.videos,
    required this.channel,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const Center(child: ShimmerLoader(count: 3));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: videos.length,
      separatorBuilder: (_, i) {
        if ((i + 1) % 4 == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LabelledBannerAd(),
          );
        }
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, i) {
        final video = videos[i];
        return VideoCard(
          video: video,
          channel: channel,
          compact: true,
          saved: provider.isVideoSaved(video.id),
          onTap: () => onTap(video),
          onSave: () => provider.toggleSaved(video),
          onShare: () => Share.share('${video.title}\n${video.watchUrl}'),
        );
      },
    );
  }
}

class _ShortsList extends StatelessWidget {
  final List<Video> videos;
  final Channel channel;
  final FeedProvider provider;
  final void Function(Video) onTap;

  const _ShortsList({
    required this.videos,
    required this.channel,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('No shorts from ${channel.name} yet.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ),
      );
    }
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
        return GestureDetector(
          onTap: () => onTap(video),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(video.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        ColoredBox(color: AppTheme.surfaceElevated(context))),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
                const Center(
                  child: Icon(Icons.play_circle_fill_rounded,
                      color: Colors.white70, size: 42),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
