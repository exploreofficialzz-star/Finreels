import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';
import '../services/ad_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BannerAdWidget
//
// The original banner_ad_widget.dart shared ONE BannerAd instance from
// AdService across every placement in the list. AdMob does not allow the
// same AdWidget to appear more than once in the widget tree simultaneously —
// doing so throws "This AdWidget is already in the Widget tree" at runtime.
//
// Fix: each _InlineBannerAd creates and owns its own BannerAd instance.
// The global AdService banner is kept for the sticky bottom bar only.
//
// Two widgets exported:
//   LabelledBannerAd  — inline list placement (creates its own BannerAd)
//   StickyBannerBar   — bottom of screen (uses AdService's shared instance)
// ─────────────────────────────────────────────────────────────────────────────

/// Inline banner — safe to place multiple times in a ListView/GridView.
/// Each instance creates and owns its own [BannerAd].
class LabelledBannerAd extends StatefulWidget {
  const LabelledBannerAd({super.key});

  @override
  State<LabelledBannerAd> createState() => _LabelledBannerAdState();
}

class _LabelledBannerAdState extends State<LabelledBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!AdService.instance.adsRemoved) _load();
  }

  void _load() {
    _ad = BannerAd(
      adUnitId: AppConfig.bannerAdUnitId,
      size:     AdSize.banner,
      request:  const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null || AdService.instance.adsRemoved) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            'Advertisement',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9, letterSpacing: 0.5),
          ),
        ),
        SizedBox(
          width:  _ad!.size.width.toDouble(),
          height: _ad!.size.height.toDouble(),
          child:  AdWidget(ad: _ad!),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Sticky bottom banner — uses the global AdService instance (one per screen).
/// Place this ONCE per screen at the very bottom.
class StickyBannerBar extends StatelessWidget {
  const StickyBannerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ad = AdService.instance.bannerAd;
    if (ad == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        SizedBox(
          width:  ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child:  AdWidget(ad: ad),
        ),
      ],
    );
  }
}
