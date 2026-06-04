import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/book_insights_data.dart';
import '../models/video.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Source routing — only Richest Man uses EPUB; all others use in-app insights
// ─────────────────────────────────────────────────────────────────────────────

enum _SourceType { epub, insights }

class _BookSource {
  final _SourceType type;
  final String? epubUrl;
  const _BookSource.epub(this.epubUrl) : type = _SourceType.epub;
  const _BookSource.insights() : type = _SourceType.insights, epubUrl = null;
}

const Map<String, _BookSource> _sources = {
  // ── Project Gutenberg — public domain, no login ──────────────────────────
  'book_richest_man': _BookSource.epub(
    'https://www.gutenberg.org/cache/epub/1297/pg1297-images.epub',
  ),
  'book_as_man_thinketh': _BookSource.epub(
    'https://www.gutenberg.org/cache/epub/4507/pg4507-images.epub',
  ),
  'book_science_rich': _BookSource.epub(
    'https://www.gutenberg.org/cache/epub/59844/pg59844-images.epub',
  ),
  'book_popular_delusions': _BookSource.epub(
    'https://www.gutenberg.org/cache/epub/636/pg636-images.epub',
  ),
  // ── Global Grey — public domain, direct EPUB, no login ──────────────────
  'book_think_grow': _BookSource.epub(
    'https://www.globalgreyebooks.com/ebooks/napoleon-hill_think-and-grow-rich.epub',
  ),
  'book_art_money': _BookSource.epub(
    'https://www.globalgreyebooks.com/ebooks/p-t-barnum_art-of-money-getting.epub',
  ),
  'book_eight_pillars': _BookSource.epub(
    'https://www.globalgreyebooks.com/ebooks/james-allen_eight-pillars-of-prosperity.epub',
  ),
  'book_master_key': _BookSource.epub(
    'https://www.globalgreyebooks.com/ebooks/charles-f-haanel_master-key-system.epub',
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class BookDetailScreen extends StatefulWidget {
  final Video book;
  const BookDetailScreen({required this.book, super.key});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _showReader = false;
  bool _isLoading  = true;

  // EPUB
  final EpubController _epubController = EpubController();
  String? _lastCfi;
  Box<String>? _progressBox;

  _BookSource get _source =>
      _sources[widget.book.id] ?? const _BookSource.insights();

  String get _progressKey => 'epub_cfi_${widget.book.id}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AdService.instance.onContentTapped());
    });
    _progressBox = Hive.box<String>('reading_progress');
    _lastCfi = _progressBox?.get(_progressKey);
  }

  @override
  Widget build(BuildContext context) {
    if (_showReader) return _buildReader();
    return _buildDetail();
  }

  // ── Detail / landing page ──────────────────────────────────────────────────

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
                  // Cover + meta
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
                              child: const Text(
                                '📚 FREE BOOK',
                                style: TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1),
                              ),
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
                            if (_lastCfi != null &&
                                _source.type == _SourceType.epub) ...[
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.gold, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(widget.book.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.6)),

                  const SizedBox(height: 32),

                  // Primary CTA
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () {
                        // Fire interstitial on every book read tap
                        unawaited(AdService.instance.onBookRead());
                        setState(() {
                          _showReader = true;
                          _isLoading  = true;
                        });
                      },
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(
                        _lastCfi != null
                            ? 'Continue Reading'
                            : 'Read Full Book Free',
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
                      widget.book.id.startsWith('book_richest') ||
                              widget.book.id.startsWith('book_as_man') ||
                              widget.book.id.startsWith('book_science') ||
                              widget.book.id.startsWith('book_popular')
                          ? 'Reads free via Project Gutenberg (public domain)'
                          : 'Reads free via Global Grey ebooks (public domain)',
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

  // ── Reader router ──────────────────────────────────────────────────────────

  Widget _buildReader() {
    if (_source.type == _SourceType.epub) {
      return _buildEpubReader(_source.epubUrl!);
    }
    return _buildInsightsReader();
  }

  // ── EPUB reader ────────────────────────────────────────────────────────────

  Widget _buildEpubReader(String url) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title.split('—').first.trim(),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() {
            _showReader = false;
            _isLoading  = true;
          }),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                EpubViewer(
                  epubSource: EpubSource.fromUrl(url),
                  epubController: _epubController,
                  displaySettings: EpubDisplaySettings(
                    flow: EpubFlow.scrolled,
                    snap: false,
                    allowScriptedContent: true,
                  ),
                  onEpubLoaded: () async {
                    if (mounted) setState(() => _isLoading = false);
                    if (_lastCfi != null && _lastCfi!.isNotEmpty) {
                      _epubController.display(cfi: _lastCfi!);
                    }
                  },
                  onChaptersLoaded: (_) {
                    if (mounted) setState(() => _isLoading = false);
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
                      child: CircularProgressIndicator(color: AppTheme.gold)),
              ],
            ),
          ),
          // Banner ad inside reader
          if (!AdService.instance.adsRemoved) const StickyBannerBar(),
        ],
      ),
    );
  }

  // ── In-app insights reader ─────────────────────────────────────────────────

  Widget _buildInsightsReader() {
    final insight = findInsight(widget.book.id);

    if (insight == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.book.title.split('—').first.trim()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => setState(() => _showReader = false),
          ),
        ),
        body: const Center(child: Text('Content coming soon.')),
      );
    }

    return _InsightsReaderScreen(
      insight: insight,
      onBack: () => setState(() => _showReader = false),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Insights reader — standalone stateful widget
// ─────────────────────────────────────────────────────────────────────────────

class _InsightsReaderScreen extends StatefulWidget {
  final BookInsightData insight;
  final VoidCallback onBack;
  const _InsightsReaderScreen({required this.insight, required this.onBack});

  @override
  State<_InsightsReaderScreen> createState() => _InsightsReaderScreenState();
}

class _InsightsReaderScreenState extends State<_InsightsReaderScreen> {
  final int _adEveryN = 4;

  Future<void> _openPurchaseLink() async {
    final uri = Uri.parse(widget.insight.purchaseUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insight = widget.insight;

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? AppTheme.darkText : AppTheme.lightText),
          onPressed: widget.onBack,
        ),
        title: Text(
          insight.title.split('—').first.replaceAll(r'$', r'\$').trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'Get full book',
            icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.gold),
            onPressed: _openPurchaseLink,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                // ── Intro card ───────────────────────────────────────────
                _IntroCard(insight: insight),
                const SizedBox(height: 24),

                // ── Chapter tiles ────────────────────────────────────────
                ...List.generate(insight.chapters.length, (i) {
                  final chapter = insight.chapters[i];
                  final widgets = <Widget>[
                    _ChapterCard(chapter: chapter, isDark: isDark),
                    const SizedBox(height: 16),
                  ];

                  // Insert inline banner ad every _adEveryN chapters
                  if (!AdService.instance.adsRemoved &&
                      (i + 1) % _adEveryN == 0 &&
                      i != insight.chapters.length - 1) {
                    widgets.add(const StickyBannerBar());
                    widgets.add(const SizedBox(height: 16));
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widgets,
                  );
                }),

                // ── Buy the full book CTA ────────────────────────────────
                _BuyFullBookCard(
                  insight: insight,
                  onTap: _openPurchaseLink,
                ),
              ],
            ),
          ),

          // Sticky banner at bottom of reader
          if (!AdService.instance.adsRemoved) const StickyBannerBar(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _IntroCard extends StatelessWidget {
  final BookInsightData insight;
  const _IntroCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.gold.withValues(alpha: 0.20), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('KEY INSIGHTS',
                    style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'by ${insight.author}',
            style: const TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            insight.intro,
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatefulWidget {
  final BookChapter chapter;
  final bool isDark;
  const _ChapterCard({required this.chapter, required this.isDark});

  @override
  State<_ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<_ChapterCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _expanded
                ? AppTheme.gold.withValues(alpha: 0.35)
                : AppTheme.dividerColor(context),
            width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row (always visible)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.chapter.title,
                      style: TextStyle(
                        color: widget.isDark
                            ? AppTheme.darkText
                            : AppTheme.lightText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.gold,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // Expanded body
          if (_expanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                widget.chapter.body,
                style: TextStyle(
                  color: widget.isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 14,
                  height: 1.65,
                ),
              ),
            ),
            if (widget.chapter.keyPoints.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text('Key Takeaways',
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    )),
              ),
              ...widget.chapter.keyPoints.map(
                (pt) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Icon(Icons.circle,
                            color: AppTheme.gold, size: 6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(pt,
                            style: TextStyle(
                              color: widget.isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                              fontSize: 13,
                              height: 1.5,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _BuyFullBookCard extends StatelessWidget {
  final BookInsightData insight;
  final VoidCallback onTap;
  const _BuyFullBookCard({required this.insight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withValues(alpha: 0.15),
            AppTheme.gold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.gold.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.menu_book_rounded, color: AppTheme.gold, size: 36),
          const SizedBox(height: 12),
          const Text('Enjoyed the insights?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            'Get the full book to read every chapter, '
            'story, and example in detail.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.shopping_bag_rounded, size: 18),
              label: const Text('Get Full Book on Amazon',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll leave FinReels to open Amazon',
            style: TextStyle(
                color: AppTheme.textMuted(context), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
