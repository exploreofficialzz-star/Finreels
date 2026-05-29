import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../screens/privacy_policy_screen.dart';
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
    if (mounted) {
      setState(() {
        _version = 'v${info.version.replaceAll('-debug', '')}';
      });
    }
  }

  Future<void> _loadNotifPref() async {
    final enabled =
        await NotificationService.instance.areNotificationsEnabled();
    if (mounted) setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
    }
  }

  @override
  Widget build(BuildContext context) {
    final iap     = context.watch<IapService>();
    final adsGone = AdService.instance.adsRemoved;
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Premium App Bar ─────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 110,
                  backgroundColor: AppTheme.bgColor(context),
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    title: Text(
                      'Settings',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkText
                            : AppTheme.lightText,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    expandedTitleScale: 1.0,
                  ),
                ),

                SliverToBoxAdapter(
                  child: Column(
                    children: [

                      // ── Remove Ads ──────────────────────────────────────
                      if (!adsGone) ...[
                        const _SectionHeader('✦  Go Ad-Free'),
                        _RemoveAdsSection(iap: iap),
                      ] else ...[
                        const _SectionHeader('Subscription'),
                        _AdsRemovedCard(),
                      ],

                      // ── Notifications ───────────────────────────────────
                      const _SectionHeader('Notifications'),
                      _ToggleTile(
                        icon: Icons.notifications_rounded,
                        title: 'New Content Alerts',
                        subtitle:
                            'Get notified when channels post new videos',
                        value: _notificationsEnabled,
                        onChanged: (v) async {
                          await NotificationService.instance
                              .setNotificationsEnabled(v);
                          setState(() => _notificationsEnabled = v);
                        },
                      ),

                      // ── Support ─────────────────────────────────────────
                      const _SectionHeader('Support'),
                      _SettingsTile(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFFBBF24),
                        title: 'Rate FinReels',
                        subtitle: 'Enjoying the app? Leave us a review!',
                        trailing: const Icon(Icons.chevron_right_rounded,
                            size: 20),
                        onTap: () async {
                          final review = InAppReview.instance;
                          if (await review.isAvailable()) {
                            unawaited(review.requestReview());
                          } else {
                            unawaited(review.openStoreListing(
                                appStoreId: AppConfig.packageName));
                          }
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.headset_mic_rounded,
                        iconColor: const Color(0xFF60A5FA),
                        title: 'Contact Support',
                        subtitle: 'Need help, support, questions or issues',
                        trailing: const Icon(Icons.chevron_right_rounded,
                            size: 20),
                        onTap: () => _launch(
                            'mailto:chastechnologiesllc@gmail.com'
                            '?subject=FinReels%20Support'
                            '&body=Hi%2C%20I%20need%20help%20with%3A%20'),
                      ),

                      // ── Legal ───────────────────────────────────────────
                      const _SectionHeader('Legal'),
                      _SettingsTile(
                        icon: Icons.privacy_tip_rounded,
                        iconColor: AppTheme.gold,
                        title: 'Privacy Policy',
                        subtitle: 'How we collect and use your data',
                        trailing: const Icon(Icons.chevron_right_rounded,
                            size: 20),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyScreen(),
                          ),
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.description_rounded,
                        iconColor: AppTheme.gold,
                        title: 'Terms of Service',
                        subtitle: 'App usage terms and conditions',
                        trailing: const Icon(Icons.chevron_right_rounded,
                            size: 20),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TermsOfServiceScreen(),
                          ),
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.gavel_rounded,
                        iconColor: AppTheme.gold,
                        title: 'Content Disclaimer',
                        subtitle: 'Videos are for educational purposes only',
                        trailing: const Icon(Icons.chevron_right_rounded,
                            size: 20),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ContentDisclaimerScreen(),
                          ),
                        ),
                      ),

                      // ── About ───────────────────────────────────────────
                      const _SectionHeader('About'),
                      _AppInfoCard(version: _version),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky banner at bottom for non-subscribers.
          if (!adsGone) const StickyBannerBar(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Remove Ads Section
// ─────────────────────────────────────────────────────────────────────────────

class _RemoveAdsSection extends StatelessWidget {
  final IapService iap;
  const _RemoveAdsSection({required this.iap});

  @override
  Widget build(BuildContext context) {
    // IAP not available on this device.
    // Helper: show "not available" snackbar.
    void showUnavailable() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'This offer is not currently available. Please try again later.',
          ),
          backgroundColor: AppTheme.surfaceColor(context),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // Determine which real products (if any) are loaded.
    final hasRealProducts = iap.available && iap.products.isNotEmpty;

    return Column(
      children: [
        // Hero promo card.
        _PromoCard(),

        const SizedBox(height: 12),

        // Pricing options — always visible, never a spinner.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: hasRealProducts
                ? iap.products
                    .map((p) => _PricingTile(product: p, iap: iap))
                    .toList()
                : [
                    _PricingTile.placeholder(
                      title: '24 Hours Ad-Free',
                      price: r'$0.99',
                      icon: Icons.timer_outlined,
                      iap: iap,
                      productId: AppConfig.iapNoAds1Day,
                      onUnavailable: showUnavailable,
                    ),
                    _PricingTile.placeholder(
                      title: '1 Week Ad-Free',
                      price: r'$2.99',
                      icon: Icons.calendar_view_week_rounded,
                      iap: iap,
                      productId: AppConfig.iapNoAdsWeekly,
                      onUnavailable: showUnavailable,
                    ),
                    _PricingTile.placeholder(
                      title: '1 Month Ad-Free',
                      price: r'$7.99',
                      icon: Icons.calendar_month_rounded,
                      iap: iap,
                      productId: AppConfig.iapNoAdsMonthly,
                      highlight: true,
                      onUnavailable: showUnavailable,
                    ),
                  ],
          ),
        ),

        // Restore button.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed:
                  iap.purchasePending ? null : iap.restorePurchases,
              child: Text(
                'Restore Previous Purchase',
                style: TextStyle(
                    color: AppTheme.textMuted(context), fontSize: 13),
              ),
            ),
          ),
        ),

        // Error message.
        if (iap.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              iap.error!,
              style:
                  const TextStyle(color: AppTheme.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),

        // Legal micro-copy required by Google Play.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(
            'Payment will be charged to your Google Play account. '
            'Your subscription will be applied for the selected period. '
            'Subscriptions are non-refundable.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

}

// ── Promo hero card ───────────────────────────────────────────────────────────

class _PromoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1208), Color(0xFF2C1F06)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppTheme.gold.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.block_rounded,
                      color: AppTheme.gold, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Go Ad-Free',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Watch all 12 channels without a single interruption. '
              'No banners, no pop-ups — just pure financial content.',
              style: TextStyle(
                color: Color(0xFFD4A84B),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                _PromoFeature('No banner ads'),
                SizedBox(width: 16),
                _PromoFeature('No interstitials'),
                SizedBox(width: 16),
                _PromoFeature('Cancel anytime'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoFeature extends StatelessWidget {
  final String label;
  const _PromoFeature(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            color: AppTheme.gold, size: 14),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Color(0xFFD4A84B),
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Pricing tile ──────────────────────────────────────────────────────────────

class _PricingTile extends StatelessWidget {
  final ProductDetails? product;
  final IapService iap;
  final String? _title;
  final String? _price;
  final IconData? _icon;
  final String? _productId;
  final bool highlight;
  final VoidCallback? _onUnavailable;

  const _PricingTile({
    required this.product,
    required this.iap,
  })  : _title = null,
        _price = null,
        _icon = null,
        _productId = null,
        highlight = false,
        _onUnavailable = null;

  const _PricingTile.placeholder({
    required String title,
    required String price,
    required IconData icon,
    required this.iap,
    required String productId,
    this.highlight = false,
    VoidCallback? onUnavailable,
  })  : product = null,
        _title = title,
        _price = price,
        _icon = icon,
        _productId = productId,
        _onUnavailable = onUnavailable;

  static const _meta = <String, (String, IconData)>{
    AppConfig.iapNoAds1Day:
        ('24 Hours Ad-Free', Icons.timer_outlined),
    AppConfig.iapNoAdsWeekly:
        ('1 Week Ad-Free', Icons.calendar_view_week_rounded),
    AppConfig.iapNoAdsMonthly:
        ('1 Month Ad-Free', Icons.calendar_month_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final id    = product?.id ?? _productId ?? '';
    final meta  = _meta[id];
    final title = meta?.$1 ?? _title ?? product?.title ?? id;
    final icon  = meta?.$2 ?? _icon  ?? Icons.shopping_bag_outlined;
    final price = product?.price ?? _price ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.gold.withValues(alpha: 0.07)
            : AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? AppTheme.gold.withValues(alpha: 0.5)
              : AppTheme.dividerColor(context),
          width: highlight ? 1.5 : 0.5,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.gold, size: 20),
        ),
        title: Row(
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            if (highlight) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.gold,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('BEST VALUE',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ),
            ],
          ],
        ),
        subtitle: Text(
          'Removes all ads for the full period',
          style: TextStyle(
              fontSize: 11, color: AppTheme.textMuted(context)),
        ),
        trailing: iap.purchasePending
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                    color: AppTheme.gold, strokeWidth: 2))
            : FilledButton(
                onPressed: product != null
                    ? () => unawaited(iap.purchase(product!))
                    : _onUnavailable,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(price,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
              ),
      ),
    );
  }
}

// ── Ads removed card ──────────────────────────────────────────────────────────

class _AdsRemovedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF052E16), Color(0xFF064E3B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  const Text('Ad-Free Active ✓',
                      style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const SizedBox(height: 3),
                  Text("You're enjoying uninterrupted financial content.",
                      style: TextStyle(
                          color: AppTheme.success.withValues(alpha: 0.8),
                          fontSize: 12,
                          height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App info card ─────────────────────────────────────────────────────────────

class _AppInfoCard extends StatelessWidget {
  final String version;
  const _AppInfoCard({required this.version});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.dividerColor(context), width: 0.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // App icon — gradient rounded square, WHITE arrow.
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [
                        AppTheme.goldLight,
                        AppTheme.gold,
                        AppTheme.goldDark,
                      ],
                      center: Alignment.topLeft,
                      radius: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: [
                      const Text('FinReels',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(
                        'Financial Literacy · Unlocked · $version',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared building blocks
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.gold,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
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
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                IconTheme(
                  data: IconThemeData(
                      color: AppTheme.textMuted(context), size: 20),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.dividerColor(context), width: 0.5),
        ),
        child: SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          secondary: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.gold, size: 20),
          ),
          title: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 12)),
          value: value,
          activeColor: AppTheme.gold,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
