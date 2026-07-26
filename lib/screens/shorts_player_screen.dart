import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/video.dart';
import '../services/ad_service.dart';
import '../services/engagement_service.dart';
import '../theme/app_theme.dart';

/// Full-screen 9:16 Shorts player.
///
/// WHY THE PAGEVIEW APPROACH FAILS:
/// YouTube's `YoutubePlayer` uses an Android WebView which intercepts all
/// touch events at the platform level — before Flutter's gesture arena even
/// runs. When a `PageView` and a WebView overlap, the WebView always wins the
/// gesture competition, so the user can't swipe to the next short by dragging
/// over the video. Using `_EasySnapPhysics` on the `PageView` doesn't help
/// because the competing gesture recognizers never see the touch events in the
/// first place.
///
/// THE FIX — outer GestureDetector + NeverScrollableScrollPhysics:
/// 1. The `PageView`'s own physics are set to `NeverScrollableScrollPhysics()`
///    so it never competes with the WebView.
/// 2. A `GestureDetector` at the Scaffold body level (above the WebView in
///    the widget tree AND using `HitTestBehavior.opaque`) wins the gesture
///    arena before the WebView can claim it, because `opaque` means this
///    detector is consulted FIRST. It claims vertical drag events exclusively.
/// 3. `onVerticalDragUpdate` drives `PageController.position.moveTo()` for
///    a smooth finger-following effect (user sees the next short peeking in).
/// 4. `onVerticalDragEnd` commits the page change based on velocity or
///    distance — exactly like TikTok/Instagram Reels.
class ShortsPlayerScreen extends StatefulWidget {
  final List<Video> shorts;
  final int initialIndex;
  final bool autoPlayFirst;

  const ShortsPlayerScreen({
    required this.shorts,
    required this.initialIndex,
    this.autoPlayFirst = true,
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  // ── Gesture handlers: claim vertical drag BEFORE the WebView does ─────────

  void _onDragStart(DragStartDetails details) {}

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_pageController.hasClients) return;
    // Move the page by the negative of the drag delta (swipe up → increase offset)
    final newOffset = (_pageController.offset - details.delta.dy)
        .clamp(0.0, _pageController.position.maxScrollExtent);
    _pageController.jumpTo(newOffset);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_pageController.hasClients) return;
    final velocity = details.primaryVelocity ?? 0;
    final page     = _pageController.page ?? _currentIndex.toDouble();

    var targetPage = _currentIndex;
    // Commit to next page: fast fling OR dragged > 30% of page height
    if (velocity < -400 || (velocity >= 0 && (page - _currentIndex) > 0.3)) {
      targetPage = (_currentIndex + 1).clamp(0, widget.shorts.length - 1);
    } else if (velocity > 400 || (velocity <= 0 && (_currentIndex - page) > 0.3)) {
      targetPage = (_currentIndex - 1).clamp(0, widget.shorts.length - 1);
    }

    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // GestureDetector ABOVE everything else, HitTestBehavior.opaque:
      // this widget is consulted FIRST in Flutter's hit-test traversal and
      // claims vertical drags before the WebView's platform handler sees them.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: Stack(
          children: [
            PageView.builder(
              controller:      _pageController,
              scrollDirection: Axis.vertical,
              // NeverScrollableScrollPhysics: the PageView never competes with
              // the WebView or the outer GestureDetector for touch events — all
              // page navigation goes through our own drag handlers above.
              physics:         const NeverScrollableScrollPhysics(),
              itemCount:       widget.shorts.length,
              onPageChanged:   (index) {
                setState(() => _currentIndex = index);
                unawaited(AdService.instance.onShortScrolled());
              },
              itemBuilder: (context, index) => _ShortPage(
                key: ValueKey(widget.shorts[index].id),
                video:             widget.shorts[index],
                isActive:          index == _currentIndex,
                autoPlayOnActivate: index != widget.initialIndex || widget.autoPlayFirst,
              ),
            ),

            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Swipe hint: small up-arrow at the bottom (fades after first swipe)
            if (widget.shorts.length > 1 && _currentIndex == widget.initialIndex)
              const Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard_arrow_up_rounded,
                          color: Colors.white54, size: 22),
                      Text('Swipe for next',
                          style: TextStyle(color: Colors.white38, fontSize: 11)),
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

// ── Individual short page ────────────────────────────────────────────────────

class _ShortPage extends StatefulWidget {
  final Video video;
  final bool  isActive;
  final bool  autoPlayOnActivate;

  const _ShortPage({
    required this.video,
    required this.isActive,
    required this.autoPlayOnActivate,
    super.key,
  });

  @override
  State<_ShortPage> createState() => _ShortPageState();
}

class _ShortPageState extends State<_ShortPage> {
  late YoutubePlayerController _controller;
  bool   _ready       = false;
  bool   _playing     = false;
  bool   _userStarted = false;
  double _progress    = 0;

  // Rate-limit controller updates to 15 fps — each tick fires from the WebView
  // message channel which can be very frequent.
  int _lastMs = 0;

  @override
  void initState() {
    super.initState();
    final autoPlay = widget.autoPlayOnActivate && widget.isActive;
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: YoutubePlayerFlags(
        autoPlay:     autoPlay,
        loop:         true,
        hideControls: true,
        enableCaption: false,
      ),
    )..addListener(_onUpdate);
    if (autoPlay) {
      _userStarted = true;
      unawaited(EngagementService.instance.recordView(widget.video));
    }
  }

  void _onUpdate() {
    if (!mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastMs < 66) return; // 15 fps cap
    _lastMs = now;

    final v       = _controller.value;
    final ready   = v.isReady;
    final playing = v.playerState == PlayerState.playing;
    final pos     = v.position.inMilliseconds.toDouble();
    final dur     = v.metaData.duration.inMilliseconds.toDouble();
    final prog    = dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0;

    if (ready != _ready || playing != _playing || (prog - _progress).abs() > 0.005) {
      setState(() {
        _ready    = ready;
        _playing  = playing;
        _progress = prog;
      });
    }
  }

  @override
  void didUpdateWidget(_ShortPage old) {
    super.didUpdateWidget(old);
    if (!widget.isActive) {
      _controller.pause();
      if (mounted) setState(() => _playing = false);
    } else if (widget.autoPlayOnActivate) {
      _userStarted = true;
      unawaited(EngagementService.instance.recordView(widget.video));
      if (_ready) _controller.play();
      // If not ready yet, onReady callback below handles it.
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onUpdate)
      ..dispose();
    super.dispose();
  }

  void _togglePlay() {
    _userStarted = true;
    if (_playing) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width:  size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),

          // Player fills screen in 9:16 via FittedBox
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width:  size.width,
                height: size.width * (16 / 9),
                child: YoutubePlayer(
                  controller: _controller,
                  onReady: () {
                    if (!mounted) return;
                    setState(() => _ready = true);
                    if (widget.isActive &&
                        (widget.autoPlayOnActivate || _userStarted)) {
                      _controller.play();
                    }
                  },
                  bufferIndicator: const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // Tap to play/pause — note: we DON'T use HitTestBehavior.opaque here
          // because the parent GestureDetector (in ShortsPlayerScreen.build)
          // already claims opaque hits for vertical drags. Making this one
          // opaque too would prevent the drag handler from firing.
          GestureDetector(
            onTap: _togglePlay,
            child: const SizedBox.expand(),
          ),

          // Loading / initial play button
          if (!_ready || (!_playing && !_userStarted))
            Center(
              child: _userStarted && !_ready
                  ? const CircularProgressIndicator(
                      color: AppTheme.gold, strokeWidth: 2.5)
                  : Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 38),
                    ),
            ),

          // Pause icon (momentary, fades after a beat)
          if (_userStarted && !_playing && _ready)
            Center(
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pause_rounded,
                    color: Colors.white, size: 38),
              ),
            ),

          // Bottom gradient + title + progress bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end:   Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   14,
                        fontWeight: FontWeight.w600,
                        height:     1.35,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value:           _progress,
                        backgroundColor: Colors.white24,
                        valueColor:      const AlwaysStoppedAnimation(AppTheme.gold),
                        minHeight:       3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
