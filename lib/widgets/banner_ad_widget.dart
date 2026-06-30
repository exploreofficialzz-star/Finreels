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
  int  _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    AdService.instance.addListener(_onAdsServiceChanged);
    if (!AdService.instance.adsRemoved) _load();
  }

  /// Fires the instant a purchase completes (or status is otherwise
  /// re-checked) — disposes the now-unwanted ad immediately instead of
  /// leaving it loaded in memory until some unrelated rebuild hides it.
  void _onAdsServiceChanged() {
    if (!mounted) return;
    if (AdService.instance.adsRemoved && _ad != null) {
      _ad!.dispose();
      setState(() { _ad = null; _loaded = false; });
    }
  }

  void _load() {
    _ad?.dispose();
    _ad = BannerAd(
      adUnitId: AppConfig.bannerAdUnitId,
      size:     AdSize.banner,
      request:  const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
          _retryCount = 0;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
          if (_retryCount < _maxRetries) {
            _retryCount++;
            final delay = Duration(seconds: 15 * _retryCount);
            Future.delayed(delay, () {
              if (mounted) _load();
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    AdService.instance.removeListener(_onAdsServiceChanged);
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

/// Sticky bottom banner — owns its own [BannerAd] instance.
/// Safe to place once per screen. Rebuilds itself when the ad loads.
class StickyBannerBar extends StatefulWidget {
  const StickyBannerBar({super.key});

  @override
  State<StickyBannerBar> createState() => _StickyBannerBarState();
}

class _StickyBannerBarState extends State<StickyBannerBar> {
  BannerAd? _ad;
  bool _loaded = false;
  int  _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    AdService.instance.addListener(_onAdsServiceChanged);
    if (!AdService.instance.adsRemoved) _load();
  }

  void _onAdsServiceChanged() {
    if (!mounted) return;
    if (AdService.instance.adsRemoved && _ad != null) {
      _ad!.dispose();
      setState(() { _ad = null; _loaded = false; });
    }
  }

  void _load() {
    _ad?.dispose();
    _ad     = null;
    _loaded = false;

    _ad = BannerAd(
      adUnitId: AppConfig.bannerAdUnitId,
      size:     AdSize.banner,
      request:  const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
          _retryCount = 0;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
          if (_retryCount < _maxRetries) {
            _retryCount++;
            final delay = Duration(seconds: 15 * _retryCount);
            Future.delayed(delay, () {
              if (mounted) _load();
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    AdService.instance.removeListener(_onAdsServiceChanged);
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
        SizedBox(
          width:  _ad!.size.width.toDouble(),
          height: _ad!.size.height.toDouble(),
          child:  AdWidget(ad: _ad!),
        ),
      ],
    );
  }
}
