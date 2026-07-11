import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../services/ad_service.dart';
import '../services/engagement_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';

/// Opens a blog article URL inside the app using flutter_inappwebview.
/// Navigation is intercepted — only the article's own domain is allowed through.
/// A gold LinearProgressIndicator shows load progress at the top.
class BlogReaderScreen extends StatefulWidget {
  final String url;
  final String title;

  /// Set when this article came from a category-tagged feed (see
  /// BlogArticle.categoryId) — lets the reader feed that back into
  /// EngagementService the same way opening a category playbook does.
  final String? categoryId;

  const BlogReaderScreen({
    required this.url,
    required this.title,
    this.categoryId,
    super.key,
  });

  @override
  State<BlogReaderScreen> createState() => _BlogReaderScreenState();
}

class _BlogReaderScreenState extends State<BlogReaderScreen> {
  double _progress = 0;
  bool _loading = true;
  late final String _allowedHost;

  @override
  void initState() {
    super.initState();
    _allowedHost = Uri.tryParse(widget.url)?.host ?? '';
    if (widget.categoryId != null) {
      unawaited(EngagementService.instance.recordCategoryInterest(widget.categoryId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: _loading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  color: AppTheme.gold,
                  backgroundColor: Colors.transparent,
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                useShouldOverrideUrlLoading: true,
                allowsInlineMediaPlayback: true,
              ),
              onLoadStart: (_, __) {
                if (mounted) setState(() => _loading = true);
              },
              onLoadStop: (_, __) {
                if (mounted) setState(() => _loading = false);
              },
              onProgressChanged: (_, progress) {
                if (mounted) {
                  setState(() {
                    _progress = progress / 100.0;
                    if (progress >= 100) _loading = false;
                  });
                }
              },
              // Block navigation away from the article's origin domain
              shouldOverrideUrlLoading: (_, action) async {
                final uri = action.request.url;
                if (uri == null) return NavigationActionPolicy.CANCEL;
                final host = uri.host;
                // Allow same domain and common CDN subdomains
                if (host == _allowedHost ||
                    host.endsWith('.$_allowedHost') ||
                    _allowedHost.isEmpty) {
                  return NavigationActionPolicy.ALLOW;
                }
                return NavigationActionPolicy.CANCEL;
              },
            ),
          ),
          // Sticky banner ad — visible for the entire time the user is
          // reading the article, pinned to the bottom of the screen.
          ListenableBuilder(
            listenable: AdService.instance,
            builder: (_, __) => AdService.instance.adsRemoved
                ? const SizedBox.shrink()
                : const StickyBannerBar(),
          ),
        ],
      ),
    );
  }
}
