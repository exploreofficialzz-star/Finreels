import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/video.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';

/// Books open in an in-app WebView pointing to a real readable page.
/// We use Open Library's read-online feature which works in WebView.
class BookDetailScreen extends StatefulWidget {
  final Video book;
  const BookDetailScreen({required this.book, super.key});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _showReader = false;

  // Open Library work IDs that are freely readable online
  static const Map<String, String> _olWorkIds = {
    'book_richest_man':      'OL19300W',     // The Richest Man in Babylon
    'book_think_grow':       'OL1738V',      // Think and Grow Rich
    'book_common_stocks':    'OL3965598W',   // Common Stocks and Uncommon Profits
    'book_millionaire_next_door': 'OL24296W', // The Millionaire Next Door
    'book_intelligent_investor': 'OL98136W', // The Intelligent Investor
    'book_rich_dad':         'OL82565W',     // Rich Dad Poor Dad
    'book_psychology_money': 'OL21998941W',  // The Psychology of Money
  };

  // Direct readable URLs via Open Library's read-online viewer
  static const Map<String, String> _readUrls = {
    'book_richest_man':
        'https://www.gutenberg.org/cache/epub/1297/pg1297.txt',
    'book_think_grow':
        'https://archive.org/stream/ThinkAndGrowRich_201810/Think-and-Grow-Rich_djvu.txt',
    'book_common_stocks':
        'https://archive.org/details/commonstocksunco00fish',
    'book_millionaire_next_door':
        'https://archive.org/details/millionairenextd00stan',
    'book_intelligent_investor':
        'https://archive.org/details/TheIntelligentInvestor_201806',
    'book_rich_dad':
        'https://archive.org/details/richdadpoordadrob00kiyo',
    'book_psychology_money':
        'https://archive.org/search?query=psychology+of+money+housel',
  };

  void _initWebView() {
    final url = _readUrls[widget.book.id] ??
        'https://archive.org/search?query=${Uri.encodeComponent(widget.book.title)}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.bgColor(context))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
      ))
      ..loadRequest(Uri.parse(url));
  }

  @override
  void initState() {
    super.initState();
    unawaited(AdService.instance.onVideoOpened());
  }

  @override
  Widget build(BuildContext context) {
    if (_showReader) return _buildReader();
    return _buildDetail();
  }

  // ── Detail / intro screen ────────────────────────────────────────────────────
  Widget _buildDetail() {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(title: const Text('Free Book')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.book.thumbnailUrl,
                          width: 110,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 110,
                            height: 160,
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.menu_book_rounded,
                                color: AppTheme.gold, size: 48),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('📚 FREE BOOK',
                                  style: TextStyle(
                                      color: AppTheme.gold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1)),
                            ),
                            const SizedBox(height: 10),
                            Text(widget.book.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        height: 1.35)),
                            const SizedBox(height: 6),
                            Text(widget.book.channelName,
                                style: TextStyle(
                                    color: AppTheme.textMuted(context),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('About this book',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(widget.book.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.6)),
                  const SizedBox(height: 32),
                  // Read button — opens in-app
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () {
                        _initWebView();
                        setState(() => _showReader = true);
                      },
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const Text('Read Inside App',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Reads via Internet Archive & Project Gutenberg',
                      style: TextStyle(
                          color: AppTheme.textMuted(context), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!AdService.instance.adsRemoved) const LabelledBannerAd(),
        ],
      ),
    );
  }

  // ── In-app reader ────────────────────────────────────────────────────────────
  Widget _buildReader() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.book.title.split('—').first.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _showReader = false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.gold),
            ),
        ],
      ),
    );
  }
}
