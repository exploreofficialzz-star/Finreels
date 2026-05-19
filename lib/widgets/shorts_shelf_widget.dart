import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';

import '../data/channel_data.dart';
import '../models/video.dart';
import '../screens/shorts_player_screen.dart';
import '../theme/app_theme.dart';

/// Fix 5 — Shorts Shelf
/// A horizontally scrolling carousel of 9:16 short-form cards.
/// Rendered inline in the unified All-tab feed every N video items.
/// Uses ListView.builder (not a fixed Row) for efficiency.
class ShortsShelfWidget extends StatelessWidget {
  final List<Video> shorts;

  const ShortsShelfWidget({required this.shorts, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, color: AppTheme.gold, size: 13),
                    SizedBox(width: 3),
                    Text(
                      'SHORTS',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Horizontal carousel
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shorts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final video = shorts[i];
              final channel =
                  ChannelData.byId[video.channelId] ?? ChannelData.fallback;
              return RepaintBoundary(
                child: _ShortCard(
                  key: ValueKey(video.id),
                  video: video,
                  channelColor: channel.accentColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShortsPlayerScreen(
                        shorts: shorts,
                        initialIndex: i,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ShortCard extends StatelessWidget {
  final Video video;
  final Color channelColor;
  final VoidCallback onTap;

  const _ShortCard({
    required this.video,
    required this.channelColor,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 9:16 at height 220 → width ≈ 124
    const cardWidth = 124.0;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: cardWidth,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: video.thumbnailMq,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => ColoredBox(
                  color: AppTheme.surfaceElevated(context),
                  child: Center(
                    child: Icon(Icons.play_circle_outline_rounded,
                        color: AppTheme.textMuted(context), size: 28),
                  ),
                ),
              ),
              // Gradient overlay
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.45, 1.0],
                  ),
                ),
              ),
              // Channel accent strip
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(height: 3, color: channelColor),
              ),
              // Play icon
              const Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
              // Title
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
