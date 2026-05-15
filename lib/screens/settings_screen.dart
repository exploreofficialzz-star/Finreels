import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/ad_service.dart';
import '../services/iap_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN
// ═══════════════════════════════════════════════════════════════════════════
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
              children: const [
                _SectionHeader('Remove Ads'),
                _RemoveAdsSection(),
                Divider(height: 32),
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

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.gold,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
      ),
    );
  }
}

// ── Remove Ads Section ────────────────────────────────────────────────────────
class _RemoveAdsSection extends StatelessWidget {
  const _RemoveAdsSection();

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IapService>();
    final adsGone = AdService.instance.adsRemoved;

    if (adsGone) {
      return const _TileCard(
        icon: Icons.check_circle_rounded,
        iconColor: AppTheme.success,
        title: 'Ads Removed',
        subtitle: "You're enjoying an ad-free experience. Thank you!",
      );
    }

    if (!iap.available) {
      return const _TileCard(
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
        ...iap.products.map((p) => _IapTile(product: p)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextButton(
            onPressed:
                iap.purchasePending ? null : iap.restorePurchases,
            child: const Text('Restore Purchases'),
          ),
        ),
        if (iap.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              iap.error!,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

// ── IAP Tile ──────────────────────────────────────────────────────────────────
class _IapTile extends StatelessWidget {
  final ProductDetails product;
  const _IapTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final iap = context.read<IapService>();

    final info = <String, (String, String, IconData)>{
      'finreels_no_ads_1day': ('Remove Ads', '24 Hours', Icons.timer_outlined),
      'finreels_no_ads_weekly': (
        'Remove Ads',
        '1 Week',
        Icons.calendar_view_week_rounded,
      ),
      'finreels_no_ads_monthly': (
        'Remove Ads',
        '1 Month',
        Icons.calendar_month_rounded,
      ),
    }[product.id];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerColor(context), width: 0.5),
        ),
        child: ListTile(
          leading: SizedBox(
            width: 40,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                info?.$3 ?? Icons.shopping_bag_outlined,
                color: AppTheme.gold,
                size: 20,
              ),
            ),
          ),
          title: Text(
            '${info?.$1 ?? product.title} — ${info?.$2 ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            product.description,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: FilledButton(
            onPressed: () => unawaited(iap.purchase(product)),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              product.price,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

// ── About Section ─────────────────────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _TileCard(
          icon: Icons.play_circle_rounded,
          iconColor: AppTheme.gold,
          title: 'FinReels',
          subtitle: 'Financial literacy content from the best channels',
        ),
        const _TileCard(
          icon: Icons.business_rounded,
          iconColor: AppTheme.gold,
          title: 'chAs Tech Group',
          subtitle: 'by chAs · com.chastech.finreels',
        ),
        InkWell(
          onTap: () async {
            final uri =
                Uri.parse('https://youtube.com/@theschoolofhardknocks');
            if (await canLaunchUrl(uri)) unawaited(launchUrl(uri));
          },
          child: const _TileCard(
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

// ── Shared Tile Card ──────────────────────────────────────────────────────────
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerColor(context), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
