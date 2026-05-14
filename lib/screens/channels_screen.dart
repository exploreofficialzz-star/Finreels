import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/channel_data.dart';
import '../models/channel.dart';
import '../providers/feed_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/video_card.dart';

// ═════════════════════════════════════════════════════════════════════════════
// CHANNELS SCREEN
// ═════════════════════════════════════════════════════════════════════════════
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
              padding: const EdgeInsets.all(16),
              itemCount: ChannelData.all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final ch = ChannelData.all[i];
                return _ChannelTile(channel: ch);
              },
            ),
          ),
          const LabelledBannerAd(),
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
            builder: (_) => ChannelDetailScreen(channel: channel)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.dividerColor(context), width: 0.5),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: channel.accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: channel.accentColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Center(
                child: Text(channel.initials,
                    style: TextStyle(
                        color: channel.accentColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
            ),
            const SizedBox(width: 14),
            // Info
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
                    child: Text(channel.category,
                        style: TextStyle(
                            color: channel.accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
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

// ═════════════════════════════════════════════════════════════════════════════
// CHANNEL DETAIL SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class ChannelDetailScreen extends StatefulWidget {
  final Channel channel;
  const ChannelDetailScreen({super.key, required this.channel});

  @override
  State<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends State<ChannelDetailScreen> {
  Channel get ch => widget.channel;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();
    final videos = provider.getVideosFor(ch.id);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context),
                SliverToBoxAdapter(child: _buildAbout(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('Latest Videos',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
                if (videos.isEmpty)
                  const SliverToBoxAdapter(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: ShimmerLoader(count: 3)))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final video = videos[i];
                        // Insert ad every 4 videos
                        if (i > 0 && i % 4 == 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: const LabelledBannerAd(),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: VideoCard(
                            video: video,
                            channel: ch,
                            compact: true,
                            saved: provider.isVideoSaved(video.id),
                            onTap: () async {
                              AdService.instance.onVideoOpened();
                              final uri = Uri.parse(video.watchUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            onSave: () => provider.toggleSaved(video),
                            onShare: () => Share.share(
                                '${video.title}\n${video.watchUrl}'),
                          ),
                        );
                      },
                      childCount: videos.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
          const LabelledBannerAd(),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ch.accentColor.withValues(alpha: 0.8),
                ch.accentColor.withValues(alpha: 0.3),
                AppTheme.bgColor(context),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: ch.accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: ch.accentColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2)
                      ],
                    ),
                    child: Center(
                      child: Text(ch.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 26)),
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
                                fontSize: 20,
                                shadows: [
                                  Shadow(
                                      color: Colors.black26, blurRadius: 4)
                                ])),
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
      actions: [
        IconButton(
          icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
          onPressed: () async {
            final uri = Uri.parse(ch.youtubeHandle);
            if (await canLaunchUrl(uri)) unawaited(launchUrl(uri));
          },
          tooltip: 'Open on YouTube',
        ),
      ],
    );
  }

  Widget _buildAbout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ch.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(ch.focus,
                style: TextStyle(
                    color: ch.accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
          const SizedBox(height: 10),
          Text(ch.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
