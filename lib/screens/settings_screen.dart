import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/feed_provider.dart';
import '../services/ad_service.dart';
import '../services/iap_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/video_card.dart';
import '../data/channel_data.dart';

// ═════════════════════════════════════════════════════════════════════════════
// SAVED SCREEN
// ═════════════════════════════════════════════════════════════════════════════
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
              child: const Text('Clear all',
                  style: TextStyle(color: AppTheme.error)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: saved.isEmpty
                ? _EmptySaved()
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
                          AdService.instance.onVideoOpened();
                          final uri = Uri.parse(video.watchUrl);
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                        onSave: () => provider.toggleSaved(video),
                        onShare: () =>
                            Share.share('${video.title}\n${video.watchUrl}'),
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
      BuildContext context, FeedProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all bookmarks?'),
        content:
            const Text('This will remove all your saved videos permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      for (final v in provider.savedVideos.toList()) {
        await provider.toggleSaved(v);
      }
    }
  }
}

class _EmptySaved extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_add_outlined,
                size: 64, color: AppTheme.textMuted(context)),
            const SizedBox(height: 20),
            Text('No bookmarks yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Tap the ⋮ menu on any video to bookmark it.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _SectionHeader('Remove Ads'),
                _RemoveAdsSection(),
                const Divider(height: 32),
                _SectionHeader('About'),
                _AboutSection(),
              ],
            ),
          ),
          const LabelledBannerAd(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.gold, letterSpacing: 0.5, fontSize: 12)),
    );
  }
}

// ── Remove Ads Section ────────────────────────────────────────────────────────
class _RemoveAdsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IapService>();
    final adsGone = AdService.instance.adsRemoved;

    if (adsGone) {
      return _TileCard(
        icon: Icons.check_circle_rounded,
        iconColor: AppTheme.success,
        title: 'Ads Removed',
        subtitle: 'You\'re enjoying an ad-free experience. Thank you!',
      );
    }

    if (!iap.available) {
      return _TileCard(
        icon: Icons.block_rounded,
        iconColor: AppTheme.error,
        title: 'Purchases Unavailable',
        subtitle: 'In-app purchases are not available on this device.',
      );
    }

    if (iap.products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Support FinReels and enjoy an ad-free experience.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        ...iap.products.map((product) => _IapTile(product: product)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextButton(
            onPressed: iap.purchasePending ? null : iap.restorePurchases,
            child: const Text('Restore Purchases'),
          ),
        ),
        if (iap.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(iap.error!,
                style: const TextStyle(color: AppTheme.error, fontSize: 13),
                textAlign: TextAlign.center),
          ),
      ],
    );
  }
}

class _IapTile extends StatelessWidget {
  final dynamic product; // ProductDetails
  const _IapTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final iap = context.read<IapService>();
    final names = {
      'finreels_no_ads_1day': ('Remove Ads', '24 Hours', Icons.timer_outlined),
      'finreels_no_ads_weekly': ('Remove Ads', '1 Week', Icons.calendar_view_week_rounded),
      'finreels_no_ads_monthly': ('Remove Ads', '1 Month', Icons.calendar_month_rounded),
    };
    final info = names[product.id];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.dividerColor(context), width: 0.5),
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(info?.$3 ?? Icons.shopping_bag_outlined,
                color: AppTheme.gold, size: 20),
          ),
          title: Text(
            '${info?.$1 ?? product.title} — ${info?.$2 ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(product.description,
              style: const TextStyle(fontSize: 12)),
          trailing: FilledButton(
            onPressed: () => iap.purchase(product),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(product.price,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ),
    );
  }
}

// ── About Section ─────────────────────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TileCard(
          icon: Icons.play_circle_rounded,
          iconColor: AppTheme.gold,
          title: 'FinReels',
          subtitle: 'Financial literacy content from the best channels',
        ),
        _TileCard(
          icon: Icons.business_rounded,
          iconColor: AppTheme.gold,
          title: 'Chas Tech Group',
          subtitle: 'by chAs · com.chastech.finreels',
        ),
        InkWell(
          onTap: () async {
            final uri = Uri.parse(
                'https://youtube.com/@theschoolofhardknocks');
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          },
          child: _TileCard(
            icon: Icons.open_in_new_rounded,
            iconColor: AppTheme.gold,
            title: 'School of Hard Knocks',
            subtitle: 'Visit the main channel on YouTube',
          ),
        ),
      ],
    );
  }
}

class _TileCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _TileCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppTheme.dividerColor(context), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
