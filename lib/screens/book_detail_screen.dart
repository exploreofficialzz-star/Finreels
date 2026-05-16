import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/video.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';

// Book entries include a readUrl pointing to Project Gutenberg / Open Library.
// The Video model reuses `watchUrl` for this — we route book IDs here instead.

class BookDetailScreen extends StatelessWidget {
  final Video book;

  const BookDetailScreen({required this.book, super.key});

  // Map book IDs to free reading URLs
  static const Map<String, String> _readUrls = {
    'book_richest_man':
        'https://www.gutenberg.org/ebooks/search/?query=richest+man+babylon',
    'book_think_grow':
        'https://www.gutenberg.org/ebooks/search/?query=think+and+grow+rich',
    'book_common_stocks':
        'https://archive.org/search?query=common+stocks+uncommon+profits',
    'book_millionaire_next_door':
        'https://archive.org/search?query=millionaire+next+door',
    'book_intelligent_investor':
        'https://archive.org/search?query=intelligent+investor+benjamin+graham',
  };

  Future<void> _openBook() async {
    final url = _readUrls[book.id] ??
        'https://archive.org/search?query=${Uri.encodeComponent(book.title)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
    }
  }

  @override
  Widget build(BuildContext context) {
    unawaited(AdService.instance.onVideoOpened()); // trigger ad on open

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        title: const Text('Free Book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: _openBook,
            tooltip: 'Read for free',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book cover + badge row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          book.thumbnailUrl,
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
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              book.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1.35),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              book.channelName,
                              style: TextStyle(
                                  color: AppTheme.textMuted(context),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  Text(
                    'About this book',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: AppTheme.gold,
                            fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    book.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.6),
                  ),

                  const SizedBox(height: 32),

                  // Read button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _openBook,
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const Text('Read for Free',
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
                      'Opens Project Gutenberg / Internet Archive',
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
}
