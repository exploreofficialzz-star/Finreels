import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/channel_data.dart';
import '../providers/feed_provider.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/video_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _ChannelFilterBar(),
          Expanded(child: _FeedBody(scrollController: _scrollController)),
          const LabelledBannerAd(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.gold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.black, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('FinReels'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () =>
              context.read<FeedProvider>().refresh(force: true),
          tooltip: 'Refresh',
        ),
      ],
    );
  }
}

// ── Channel Filter Bar ────────────────────────────────────────────────────────
class _ChannelFilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();
    final selected = provider.selectedChannel;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => provider.selectChannel(null),
              selectedColor: AppTheme.gold,
              labelStyle: TextStyle(
                color: selected == null ? Colors.black : null,
                fontWeight:
                    selected == null ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          ...ChannelData.all.map((ch) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(ch.name.split(' ').first),
                  selected: selected?.id == ch.id,
                  onSelected: (_) {
                    provider.selectChannel(ch);
                    AdService.instance.onChannelSwitched();
                  },
                  selectedColor: ch.accentColor,
                  labelStyle: TextStyle(
                    color: selected?.id == ch.id ? Colors.white : null,
                    fontWeight: selected?.id == ch.id
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Feed Body ─────────────────────────────────────────────────────────────────
class _FeedBody extends StatelessWidget {
  final ScrollController scrollController;
  const _FeedBody({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();

    switch (provider.state) {
      case FeedState.idle:
      case FeedState.loading:
        if (provider.feedVideos.isEmpty) return const ShimmerLoader();
        return _buildList(context, provider);

      case FeedState.error:
        return _ErrorView(
            message: provider.errorMessage ?? 'Something went wrong.',
            onRetry: () => provider.refresh(force: true));

      case FeedState.loaded:
        if (provider.feedVideos.isEmpty) {
          return const Center(child: Text('No videos found.'));
        }
        return _buildList(context, provider);
    }
  }

  Widget _buildList(BuildContext context, FeedProvider provider) {
    final videos = provider.feedVideos;
    final channels = {for (final ch in provider.channels) ch.id: ch};

    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () => provider.refresh(force: true),
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: videos.length,
        separatorBuilder: (_, i) {
          // Insert a banner ad every 5 videos
          if ((i + 1) % 5 == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: const [
                  LabelledBannerAd(),
                  SizedBox(height: 12),
                ],
              ),
            );
          }
          return const SizedBox(height: 16);
        },
        itemBuilder: (context, i) {
          final video = videos[i];
          final channel = channels[video.channelId] ??
              ChannelData.all.first;

          return VideoCard(
            video: video,
            channel: channel,
            saved: provider.isVideoSaved(video.id),
            onTap: () async {
              unawaited(AdService.instance.onVideoOpened());
              final uri = Uri.parse(video.watchUrl);
              if (await canLaunchUrl(uri)) unawaited(launchUrl(uri));
            },
            onSave: () => provider.toggleSaved(video),
            onShare: () => Share.share(
                '${video.title}\n\nWatch on YouTube: ${video.watchUrl}',
                subject: video.title),
          );
        },
      ),
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
