import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/ad_service.dart';
import '../services/iap_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadNotifPref();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = 'v${info.version}');
  }

  Future<void> _loadNotifPref() async {
    final enabled =
        await NotificationService.instance.areNotificationsEnabled();
    if (mounted) setState(() => _notificationsEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
              children: [
                const _SectionHeader('Remove Ads'),
                const _RemoveAdsSection(),
                const _SectionHeader('Notifications'),
                _NotificationTile(
                  enabled: _notificationsEnabled,
                  onChanged: (v) async {
                    await NotificationService.instance
                        .setNotificationsEnabled(v);
                    setState(() => _notificationsEnabled = v);
                  },
                ),
                const _SectionHeader('Support'),
                _ActionTile(
                  icon: Icons.star_rounded,
                  iconColor: AppTheme.gold,
                  title: 'Rate FinReels',
                  subtitle: 'Enjoying the app? Leave us a review!',
                  onTap: () async {
                    final review = InAppReview.instance;
                    if (await review.isAvailable()) {
                      await review.requestReview();
                    } else {
                      unawaited(review.openStoreListing(
                          appStoreId: 'com.chastech.finreels'));
                    }
                  },
                ),
                _ActionTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: AppTheme.gold,
                  title: 'Privacy Policy',
                  subtitle: 'How we handle your data',
                  onTap: () async {
                    final uri = Uri.parse(
                        'https://sites.google.com/view/finreels-privacy');
                    if (await canLaunchUrl(uri)) {
                      unawaited(launchUrl(uri,
                          mode: LaunchMode.externalApplication));
                    }
                  },
                ),
                _ActionTile(
                  icon: Icons.description_outlined,
                  iconColor: AppTheme.gold,
                  title: 'Terms of Service',
                  subtitle: 'App usage terms and conditions',
                  onTap: () async {
                    final uri = Uri.parse(
                        'https://sites.google.com/view/finreels-terms');
                    if (await canLaunchUrl(uri)) {
                      unawaited(launchUrl(uri,
                          mode: LaunchMode.externalApplication));
                    }
                  },
                ),
                _SectionHeader('About'),
                _InfoTile(
                  icon: Icons.play_circle_rounded,
                  iconColor: AppTheme.gold,
                  title: 'FinReels',
                  subtitle: 'Financial literacy video hub · $_version',
                ),
                const _InfoTile(
                  icon: Icons.business_rounded,
                  iconColor: AppTheme.gold,
                  title: 'by chAs',
                  subtitle: 'chAs Tech Group · com.chastech.finreels',
                ),
              ],
            ),
          ),
          if (!AdService.instance.adsRemoved) const LabelledBannerAd(),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.gold,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

// ── Remove Ads ─────────────────────────────────────────────────────────────────
class _RemoveAdsSection extends StatelessWidget {
  const _RemoveAdsSection();

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IapService>();
    final adsGone = AdService.instance.adsRemoved;

    if (adsGone) {
      return const _InfoTile(
        icon: Icons.check_circle_rounded,
        iconColor: AppTheme.success,
        title: 'Ads Removed ✓',
        subtitle: "You're enjoying an ad-free experience. Thank you!",
      );
    }

    if (!iap.available) {
      return const _InfoTile(
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Support FinReels and watch without interruptions.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        ...iap.products.map((p) => _IapTile(product: p)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextButton(
            onPressed: iap.purchasePending ? null : iap.restorePurchases,
            child: const Text('Restore Purchases'),
          ),
        ),
        if (iap.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              iap.error!,
              style: const TextStyle(color: AppTheme.error, fontSize: 12),
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

    final info = <String, (String, IconData)>{
      'finreels_no_ads_1day':
          ('24 Hours Ad-Free', Icons.timer_outlined),
      'finreels_no_ads_weekly':
          ('1 Week Ad-Free', Icons.calendar_view_week_rounded),
      'finreels_no_ads_monthly':
          ('1 Month Ad-Free', Icons.calendar_month_rounded),
    }[product.id];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppTheme.dividerColor(context), width: 0.5),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(info?.$2 ?? Icons.shopping_bag_outlined,
                color: AppTheme.gold, size: 20),
          ),
          title: Text(
            info?.$1 ?? product.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: Text(
            'One-time purchase · removes all ads',
            style: TextStyle(
                fontSize: 12, color: AppTheme.textMuted(context)),
          ),
          trailing: FilledButton(
            onPressed: iap.purchasePending
                ? null
                : () => unawaited(iap.purchase(product)),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              product.price,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Notification Toggle ───────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppTheme.dividerColor(context), width: 0.5),
        ),
        child: SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_rounded,
                color: AppTheme.gold, size: 20),
          ),
          title: const Text('New Content Alerts',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(
            'Get notified when channels post new videos',
            style: TextStyle(
                fontSize: 12, color: AppTheme.textMuted(context)),
          ),
          value: enabled,
          activeColor: AppTheme.gold,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Action Tile ───────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.dividerColor(context), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
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
              Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted(context), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info Tile ─────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InfoTile({
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
                color: iconColor.withValues(alpha: 0.12),
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
