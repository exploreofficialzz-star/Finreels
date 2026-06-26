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

  @override
  Widget build(BuildContext context) {
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
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
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
