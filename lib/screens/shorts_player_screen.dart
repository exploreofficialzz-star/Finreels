import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/video.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';

/// Full-screen vertical Shorts player.
///
/// Key behaviours:
/// • NO auto-play on entry — user must tap the play button on the first short.
/// • Natural video ratio — AspectRatio is driven by the player itself via
///   YoutubePlayerBuilder; we never force 16:9. The video fills its natural
///   aspect ratio and is centred on a black background.
/// • Ad every 4 pages scrolled via [AdService.onShortScrolled].
/// • PageView.builder — each page owns its controller, disposed on eviction.
class ShortsPlayerScreen extends StatefulWidget {
  final List<Video> shorts;
  final int initialIndex;

  const ShortsPlayerScreen({
    required this.shorts,
    required this.initialIndex,
    super.key,
  });

  @override
  State<ShortsPlayerScreen> createState() => _ShortsPlayerScreenState();
}

class _ShortsPlayerScreenState extends State<ShortsPlayerScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.shorts.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              // Trigger ad every 4 shorts scrolled
              unawaited(AdService.instance.onShortScrolled());
            },
            itemBuilder: (context, index) => _ShortPage(
              video: widget.shorts[index],
              isActive: index == _currentIndex,
              // First page: user must tap. Subsequent pages: auto-play on swipe.
              autoPlayOnActivate: index != widget.initialIndex,
            ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// One page in the Shorts PageView.
/// Owns its [YoutubePlayerController], disposed in [dispose].
///
/// When [autoPlayOnActivate] is true (every page after the first),
/// the video plays automatically when it becomes the active page.
/// The first page requires an explicit tap.
class _ShortPage extends StatefulWidget {
  final Video video;
  final bool isActive;
  final bool autoPlayOnActivate;

  const _ShortPage({
    required this.video,
    required this.isActive,
    required this.autoPlayOnActivate,
  });

  @override
  State<_ShortPage> createState() => _ShortPageState();
}

class _ShortPageState extends State<_ShortPage> {
  late YoutubePlayerController _controller;
  bool _ready = false;
  bool _userStarted = false; // tracks whether user has tapped play

  @override
  void initState() {
    super.initState();
    // autoPlay only if this is NOT the entry page — entry page waits for tap.
    final shouldAutoPlay = widget.autoPlayOnActivate && widget.isActive;
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: YoutubePlayerFlags(
        autoPlay: shouldAutoPlay,
        loop: true,
        enableCaption: false,
      ),
    )..addListener(_onUpdate);
    if (shouldAutoPlay) _userStarted = true;
  }

  void _onUpdate() {
    if (!mounted) return;
    if (_controller.value.isReady != _ready) {
      setState(() => _ready = _controller.value.isReady);
    }
  }

  @override
  void didUpdateWidget(_ShortPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && _ready && (widget.autoPlayOnActivate || _userStarted)) {
      _controller.play();
    } else if (!widget.isActive) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onUpdate)
      ..dispose();
    super.dispose();
  }

  void _onTapPlay() {
    _userStarted = true;
    if (_ready) {
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),

          // ── Video in natural aspect ratio, centred ───────────────────────
          Center(
            child: YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: AppTheme.gold,
                progressColors: const ProgressBarColors(
                  playedColor: AppTheme.gold,
                  handleColor: AppTheme.gold,
                ),
                onReady: () {
                  if (mounted) {
                    setState(() => _ready = true);
                    if (widget.isActive &&
                        (widget.autoPlayOnActivate || _userStarted)) {
                      _controller.play();
                    }
                  }
                },
                bufferIndicator: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.gold,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              // Natural ratio: let the player size itself, don't force 16:9
              builder: (_, player) => player,
            ),
          ),

          // ── Tap-to-play overlay (shown until user starts playback) ────────
          if (!_userStarted)
            GestureDetector(
              onTap: _onTapPlay,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 40),
                ),
              ),
            ),

          // ── Title + gradient overlay ──────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 40),
                child: Text(
                  widget.video.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
              ),
            ),
          ),

          // Swipe hint
          const Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(Icons.keyboard_arrow_up_rounded,
                  color: Colors.white54, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
