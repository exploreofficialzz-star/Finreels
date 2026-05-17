import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/channel.dart';
import '../models/video.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';

/// Strategy: YouTube blocks WebView embedding for most videos (Error 150/153).
/// Instead we show a high-quality thumbnail with a play button.
/// Tapping "Watch" launches the YouTube app (deep link) → browser fallback.
/// This is reliable, fast, and works for 100% of videos.
class VideoPlayerScreen extends StatefulWidget {
  final Video video;
  final Channel channel;

  const VideoPlayerScreen({
    required this.video,
    required this.channel,
    super.key,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    unawaited(AdService.instance.onVideoOpened());
    // Auto-launch YouTube after a short delay so the ad fires first
    Future.delayed(const Duration(milliseconds: 400), _openInYouTube);
  }

  Future<void> _openInYouTube() async {
    if (_launching) return;
    setState(() => _launching = true);

    // Try YouTube app deep link first, fall back to browser
    final appUri = Uri.parse('vnd.youtube:${widget.video.id}');
    final webUri = Uri.parse(widget.video.watchUrl);

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } on Exception catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }

    if (mounted) setState(() => _launching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        title: Text(widget.channel.name,
            style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share(
                '${widget.video.title}\n${widget.video.watchUrl}'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Thumbnail player ────────────────────────────────────────────────
          AspectRatio(
            aspectRatio: 16 / 9,
            child: GestureDetector(
              onTap: _openInYouTube,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail
                  CachedNetworkImage(
                    imageUrl: widget.video.thumbnailHd,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => CachedNetworkImage(
                      imageUrl: widget.video.thumbnailMq,
                      fit: BoxFit.cover,
                    ),
                    errorWidget: (_, __, ___) => CachedNetworkImage(
                      imageUrl: widget.video.thumbnailMq,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: AppTheme.surfaceElevated(context),
                        child: const Center(
                          child: Icon(Icons.play_circle_outline_rounded,
                              color: AppTheme.gold, size: 56),
                        ),
                      ),
                    ),
                  ),
                  // Dark overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Play button
                  Center(
                    child: _launching
                        ? const CircularProgressIndicator(
                            color: AppTheme.gold, strokeWidth: 3)
                        : Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: AppTheme.gold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 44,
                            ),
                          ),
                  ),
                  // "Opens in YouTube" label at bottom
                  const Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius:
                              BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Text(
                            'Tap to watch in YouTube',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Channel accent strip
          Container(height: 3, color: widget.channel.accentColor),

          // ── Video info ──────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700, height: 1.3),
                  ),
                  const SizedBox(height: 14),

                  // Channel row
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: widget.channel.accentColor
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: widget.channel.accentColor
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: Text(
                            widget.channel.initials,
                            style: TextStyle(
                                color: widget.channel.accentColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.channel.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            Text(widget.channel.focus,
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Watch button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _openInYouTube,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        _launching ? 'Opening YouTube…' : 'Watch on YouTube',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  if (widget.video.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text('About this video',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: AppTheme.gold)),
                    const SizedBox(height: 8),
                    Text(
                      widget.video.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.6),
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (!AdService.instance.adsRemoved) const LabelledBannerAd(),
        ],
      ),
    );
  }
}
