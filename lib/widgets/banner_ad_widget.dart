import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ad = AdService.instance.bannerAd;
    if (ad == null) return const SizedBox.shrink();

    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}

/// Wrapped with a labelled container for transparency
class LabelledBannerAd extends StatelessWidget {
  const LabelledBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    final ad = AdService.instance.bannerAd;
    if (ad == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 0),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 1),
          child: Text('Advertisement',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9, letterSpacing: 0.5)),
        ),
        SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ],
    );
  }
}
