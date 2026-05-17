import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../services/blog_rss_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_loader.dart';
import 'blog_reader_screen.dart';

/// Blogs tab — fetches RSS from 3 finance sources and displays articles
/// as cards. Tapping opens the article inline via BlogReaderScreen.
class BlogFeedScreen extends StatefulWidget {
  const BlogFeedScreen({super.key});

  @override
  State<BlogFeedScreen> createState() => _BlogFeedScreenState();
}

class _BlogFeedScreenState extends State<BlogFeedScreen> {
  List<BlogArticle> _articles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final articles =
          await BlogRssService.instance.fetchAll(forceRefresh: force);
      if (mounted) setState(() => _articles = articles);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load articles.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _articles.isEmpty) return const ShimmerLoader();

    if (_error != null && _articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 52, color: AppTheme.textMuted(context)),
            const SizedBox(height: 16),
            Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              onPressed: () => _load(force: true),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () => _load(force: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        itemCount: _articles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final article = _articles[i];
          return RepaintBoundary(
            child: _BlogCard(
              article: article,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlogReaderScreen(
                    url: article.url,
                    title: article.title,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final BlogArticle article;
  final VoidCallback onTap;

  const _BlogCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppTheme.dividerColor(context), width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (article.thumbnailUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                child: CachedNetworkImage(
                  imageUrl: article.thumbnailUrl!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _PlaceholderThumb(context),
                ),
              )
            else
              _PlaceholderThumb(context),

            // Text content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source + date row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            article.sourceName.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeago.format(article.publishedAt),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Headline
                    Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w600, height: 1.35),
                    ),
                    if (article.excerpt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        article.excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  final BuildContext ctx;
  const _PlaceholderThumb(this.ctx);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated(ctx),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          bottomLeft: Radius.circular(15),
        ),
      ),
      child: Icon(Icons.article_outlined,
          color: AppTheme.textMuted(ctx), size: 32),
    );
  }
}
