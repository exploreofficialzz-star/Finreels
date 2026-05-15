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
import '../widgets/video_card.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();
    final saved = provider.savedVideos;
    final channels = {for (final ch in provider.channels) ch.id: ch};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        actions: [
          if (saved.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context, provider),
              child: const Text(
                'Clear all',
                style: TextStyle(color: AppTheme.error),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: saved.isEmpty
                ? const _EmptySaved()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: saved.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final video = saved[i];
                      final channel =
                          channels[video.channelId] ?? ChannelData.all.first;
                      return VideoCard(
                        video: video,
                        channel: channel,
                        compact: true,
                        saved: true,
                        onTap: () async {
                          unawaited(AdService.instance.onVideoOpened());
                          final uri = Uri.parse(video.watchUrl);
                          if (await canLaunchUrl(uri)) {
                            unawaited(launchUrl(uri));
                          }
                        },
                        onSave: () => provider.toggleSaved(video),
                        onShare: () => Share.share(
                          '${video.title}\n${video.watchUrl}',
                        ),
                      );
                    },
                  ),
          ),
          const LabelledBannerAd(),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    FeedProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all bookmarks?'),
        content: const Text(
          'This will remove all your saved videos permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Clear all',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      for (final v in provider.savedVideos.toList()) {
        await provider.toggleSaved(v);
      }
    }
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_add_outlined,
              size: 64,
              color: AppTheme.textMuted(context),
            ),
            const SizedBox(height: 20),
            Text(
              'No bookmarks yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the ⋮ menu on any video to bookmark it.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
