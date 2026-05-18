import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hive/hive.dart';

import '../models/video.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';

// ── Book source types ─────────────────────────────────────────────────────────

enum _SourceType { epub, web }

class _BookSource {
  final _SourceType type;
  final String url;
  const _BookSource(this.type, this.url);
}

const _allowedHosts = {
  'archive.org',
  'www.archive.org',
  'gutenberg.org',
  'www.gutenberg.org',
  'openlibrary.org',
  'www.openlibrary.org',
};

const Map<String, _BookSource> _sources = {
  'book_richest_man': _BookSource(
    _SourceType.epub,
    'https://www.gutenberg.org/cache/epub/1297/pg1297-images.epub',
  ),
  'book_think_grow': _BookSource(
    _SourceType.web,
    'https://archive.org/stream/ThinkAndGrowRich_201810/Think-and-Grow-Rich_djvu.txt',
  ),
  'book_rich_dad': _BookSource(
    _SourceType.web,
    'https://archive.org/details/richdadpoordadrob00kiyo',
  ),
  'book_millionaire_next_door': _BookSource(
    _SourceType.web,
    'https://archive.org/details/millionairenextd00stan',
  ),
  'book_intelligent_investor': _BookSource(
    _SourceType.web,
    'https://archive.org/details/TheIntelligentInvestor_201806',
  ),
  'book_psychology_money': _BookSource(
    _SourceType.web,
    'https://archive.org/search?query=psychology+of+money+housel',
  ),
  'book_zero_to_one': _BookSource(
    _SourceType.web,
    'https://archive.org/details/zerotoonenotesonst00thie',
  ),
};

// ── Screen ────────────────────────────────────────────────────────────────────

class BookDetailScreen extends StatefulWidget {
  final Video book;
  const BookDetailScreen({required this.book, super.key});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _showReader = false;
  bool _isLoading = true;
  double _loadProgress = 0;

  // EPUB state
  final EpubController _epubController = EpubController();
  String? _lastCfi;


  // Hive box for persisting reading position
  Box<String>? _progressBox;

  _BookSource get _source =>
      _sources[widget.book.id] ??
      _BookSource(
        _SourceType.web,
        'https://archive.org/search?query=${Uri.encodeComponent(widget.book.title)}',
      );

  String get _progressKey => 'epub_cfi_${widget.book.id}';

  @override
  void initState() {
    super.initState();
    unawaited(AdService.instance.onVideoOpened());
    _progressBox = Hive.box<String>('reading_progress');
    _lastCfi = _progressBox?.get(_progressKey);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showReader) return _buildReader();
    return _buildDetail();
  }

  // ── Detail screen ─────────────────────────────────────────────────────────

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
                            // Restore progress badge
                            if (_lastCfi != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.success
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Continue reading',
                                    style: TextStyle(
                                        color: AppTheme.success,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('About this book',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(widget.book.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.6)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => setState(() {
                        _showReader = true;
                        _isLoading = true;
                        _loadProgress = 0;
                      }),
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(
                        _lastCfi != null ? 'Continue Reading' : 'Read Inside App',
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

  // ── Reader ────────────────────────────────────────────────────────────────

  Widget _buildReader() {
    final source = _source;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.book.title.split('—').first.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() {
            _showReader = false;
            _isLoading = true;
            _loadProgress = 0;
          }),
        ),
      ),
      body: source.type == _SourceType.epub
          ? _buildEpubReader(source.url)
          : _buildWebReader(source.url),
    );
  }

  // ── EPUB reader (flutter_epub_viewer) — EpubFlow.scrolled ────────────────

  Widget _buildEpubReader(String url) {
    return Stack(
      children: [
        EpubViewer(
          epubSource: EpubSource.fromUrl(url),
          epubController: _epubController,
          displaySettings: EpubDisplaySettings(
            flow: EpubFlow.scrolled, // continuous vertical scroll
            snap: false,
            allowScriptedContent: true,
          ),
          onEpubLoaded: () async {
            if (mounted) setState(() => _isLoading = false);
            // Restore last saved position after load
            if (_lastCfi != null && _lastCfi!.isNotEmpty) {
              _epubController.display(cfi: _lastCfi!);
            }
          },
          onChaptersLoaded: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onRelocated: (location) {
            if (!mounted) return;
            final cfi = location.startCfi;
            if (cfi.isNotEmpty) {
              _lastCfi = cfi;
              _progressBox?.put(_progressKey, cfi);
            }
          },
          onTextSelected: (_) {},
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: AppTheme.gold),
          ),
      ],
    );
  }

  // ── Web reader (flutter_inappwebview) ────────────────────────────────────

  Widget _buildWebReader(String url) {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(url)),
          initialSettings: InAppWebViewSettings(
            useShouldOverrideUrlLoading: true,
            allowsInlineMediaPlayback: true,
          ),
          onLoadStart: (_, __) {
            if (mounted) { setState(() => _isLoading = true); }
          },
          onLoadStop: (_, __) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _loadProgress = 1;
              });
            }
          },
          onProgressChanged: (_, progress) {
            if (mounted) {
              setState(() {
                _loadProgress = progress / 100.0;
                if (progress >= 100) _isLoading = false;
              });
            }
          },
          shouldOverrideUrlLoading: (_, navigationAction) async {
            final uri = navigationAction.request.url;
            if (uri != null && _allowedHosts.contains(uri.host)) {
              return NavigationActionPolicy.ALLOW;
            }
            return NavigationActionPolicy.CANCEL;
          },
        ),
        if (_isLoading && _loadProgress > 0 && _loadProgress < 1)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _loadProgress,
              color: AppTheme.gold,
              backgroundColor: Colors.transparent,
              minHeight: 3,
            ),
          ),
        if (_isLoading && _loadProgress == 0)
          const Center(
            child: CircularProgressIndicator(color: AppTheme.gold),
          ),
      ],
    );
  }
}
