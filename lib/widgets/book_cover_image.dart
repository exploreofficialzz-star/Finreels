import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

/// Renders a book cover from either:
///  • a bundled Flutter asset (path starts with 'assets/'), or
///  • a remote network URL (Open Library, Global Grey, archive.org, etc.)
///
/// Used everywhere a book thumbnail appears (Books tab list, book detail
/// header, Saved/Bookmarks list) so local PDF-book covers and remote
/// EPUB-book covers render identically with the same placeholder and
/// error-fallback behaviour.
class BookCoverImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const BookCoverImage({
    required this.url,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  bool get _isAsset => url.startsWith('assets/');
  bool get _isEmpty => url.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    if (_isEmpty) {
      final fb = _fallback(context);
      return borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: fb)
          : fb;
    }
    final image = _isAsset ? _buildAsset(context) : _buildNetwork(context);
    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _buildAsset(BuildContext context) {
    return Image.asset(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallback(context),
    );
  }

  Widget _buildNetwork(BuildContext context) {
    // Book cover URLs come from varied external sources (Open Library,
    // Global Grey, archive.org) whose actual resolution is unpredictable —
    // some scans run well beyond 1000px wide. Deriving the decode target
    // from this widget's own requested size (scaled for device pixel
    // ratio) keeps every cover's memory footprint proportional to how
    // large it's actually rendered, rather than whatever the source
    // happens to be. Falls back to a generous fixed size only for the one
    // caller (video_card.dart, book cards in a Stack.expand) that doesn't
    // pass explicit width/height.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth  = width  != null ? (width! * dpr).round()  : 480;
    final cacheHeight = height != null ? (height! * dpr).round() : 640;

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFF1E1E1E),
        highlightColor: const Color(0xFF2C2C2C),
        child: SizedBox(
          width: width,
          height: height,
          child: const ColoredBox(color: Colors.white),
        ),
      ),
      errorWidget: (_, __, ___) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final iconSize = (width != null && width! < 80) ? 22.0 : 40.0;
    return Container(
      width: width,
      height: height,
      color: AppTheme.gold.withValues(alpha: 0.15),
      child: Icon(Icons.menu_book_rounded, color: AppTheme.gold, size: iconSize),
    );
  }
}
