import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/video.dart';
import '../services/ad_service.dart';
import '../services/engagement_service.dart';
import '../theme/app_theme.dart';

/// Full-screen 9:16 Shorts player — TikTok/Reels-quality scroll UX.
///
/// ─── WHY PAGEVIEW + OUTER GESTUREDETECTOR ────────────────────────────────
/// YouTube's YoutubePlayer wraps an Android WebView that intercepts all touch
/// events at the platform level before Flutter's gesture arena runs. A plain
/// PageView can never win the gesture competition against the WebView.
///
/// Fix: PageView.physics = NeverScrollableScrollPhysics. A GestureDetector
/// with HitTestBehavior.opaque sits *above* the PageView in the widget tree,
/// so Flutter consults it first and it claims vertical drags exclusively.
///
/// ─── SCROLL FEEL (matched to TikTok / Instagram Reels) ──────────────────
/// • Position threshold  : 20 % of page height  (not 30 %)
/// • Velocity threshold  : 800 px/s              (fast-fling trigger)
/// • Rubber-band at edges: 25 % dampening when past first/last video
/// • Pause on drag start : active video pauses the moment the finger moves;
///   resumes automatically once the page settles.
/// • Haptic on commit    : HapticFeedback.lightImpact() when page changes.
/// • Snap animation      : 280 ms Curves.decelerate (matches platform feel).
///
/// ─── BUG FIXES OVER PREVIOUS VERSION ────────────────────────────────────
/// 1. Snap logic used incorrect velocity-direction conditions — slow drags
///    past the threshold never committed to a new page.  Fixed: separated
///    velocity check from position check with correct signs.
/// 2. "Cancel anytime" promo chip was misleading; addressed upstream.
/// 3. _onDragStart was a no-op; now sets _isDragging so the active
///    _ShortPage can pause immediately.
/// 4. Drag update used raw clamp(0, maxExtent) — felt "locked" at edges;
///    replaced with rubber-band dampening.
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
  int  _currentIndex = 0;
  bool _isDragging   = false;

  // Tuning constants — match TikTok / Instagram Reels research.
  static const double _positionThreshold = 0.20; // 20 % of page height
  static const double _velocityThreshold = 800.0; // px/s  fast-fling trigger
  static const double _rubberBandFactor  = 0.25;  // 25 % resistance at edges
  static const Duration _snapDuration    = Duration(milliseconds: 280);
  static const Curve    _snapCurve       = Curves.decelerate;

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

  // ── Rubber-band helper ───────────────────────────────────────────────────

  /// Applies elastic resistance when the user drags past the first or last
  /// video — identical feel to iOS lists and TikTok edge behaviour.
  double _rubberBand(double rawOffset) {
    final max = _pageController.position.maxScrollExtent;
    if (rawOffset < 0)   return rawOffset * _rubberBandFactor;
    if (rawOffset > max) return max + (rawOffset - max) * _rubberBandFactor;
    return rawOffset;
  }

  // ── Gesture handlers ────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails _) {
    // Pause the active video the instant the finger moves — same as TikTok.
    if (!_isDragging) setState(() => _isDragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_pageController.hasClients) return;
    // Swipe UP  → dy negative → offset increases → next video
    // Swipe DOWN → dy positive → offset decreases → prev video
    final rawOffset = _pageController.offset - details.delta.dy;
    _pageController.jumpTo(_rubberBand(rawOffset));
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_pageController.hasClients) return;

    final velocity = details.primaryVelocity ?? 0.0;
    // page is a fractional position; _currentIndex is the last committed page.
    // pageFraction > 0 → dragged toward next; < 0 → dragged toward prev.
    final page         = _pageController.page ?? _currentIndex.toDouble();
    final pageFraction = page - _currentIndex; // range ≈ -1..1

    var targetPage = _currentIndex;

    // ── Commit to NEXT ───────────────────────────────────────────────────
    // Fast upward fling  (velocity < 0 in Flutter's y-axis convention)
    // OR  slow drag that crossed the 20 % threshold toward next.
    if (velocity < -_velocityThreshold || pageFraction > _positionThreshold) {
      targetPage = (_currentIndex + 1).clamp(0, widget.shorts.length - 1);
    }
    // ── Commit to PREV ───────────────────────────────────────────────────
    // Fast downward fling OR slow drag past threshold toward prev.
    else if (velocity > _velocityThreshold || pageFraction < -_positionThreshold) {
      targetPage = (_currentIndex - 1).clamp(0, widget.shorts.length - 1);
    }
    // Otherwise: snap back to current page (incomplete drag).

    // Haptic feedback on a real page change — matches iOS/Android platform feel.
    if (targetPage != _currentIndex) {
      HapticFeedback.lightImpact();
    }

    _pageController
        .animateToPage(targetPage,
            duration: _snapDuration, curve: _snapCurve)
        .then((_) {
      // Re-enable playback after the snap animation finishes.
      if (mounted) setState(() => _isDragging = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // GestureDetector with HitTestBehavior.opaque sits ABOVE the PageView
      // in Flutter's widget tree so it wins the hit-test before the WebView's
      // platform handler can claim vertical drag events.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart:  _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd:    _onDragEnd,
        child: Stack(
          children: [
            PageView.builder(
              controller:      _pageController,
              scrollDirection: Axis.vertical,
              // NeverScrollableScrollPhysics: the PageView never competes with
              // the WebView — all navigation goes through our drag handlers.
              physics:   const NeverScrollableScrollPhysics(),
              itemCount: widget.shorts.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                unawaited(AdService.instance.onShortScrolled());
              },
              itemBuilder: (context, index) => _ShortPage(
                key: ValueKey(widget.shorts[index].id),
                video:              widget.shorts[index],
                isActive:           index == _currentIndex,
                autoPlayOnActivate: index != widget.initialIndex ||
                    widget.autoPlayFirst,
                // Tell the active page to pause during scroll — the video
                // stays paused until the snap animation completes (i.e. until
                // _isDragging becomes false again in _onDragEnd).
                pauseForScroll: _isDragging && index == _currentIndex,
              ),
            ),

            // ── Back button ────────────────────────────────────────────────
            Positioned(
              top:  MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // ── Swipe hint: shown only on the very first short ─────────────
            // Disappears as soon as the user moves away from the initial video.
            if (widget.shorts.length > 1 &&
                _currentIndex == widget.initialIndex &&
                !_isDragging)
              const Positioned(
                bottom: 10,
                left:   0,
                right:  0,
                child:  Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard_arrow_up_rounded,
                          color: Colors.white54, size: 22),
                      Text('Swipe for next',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 11)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Individual short page
// ─────────────────────────────────────────────────────────────────────────────

class _ShortPage extends StatefulWidget {
  final Video video;
  final bool  isActive;
  final bool  autoPlayOnActivate;
  /// True while the parent is animating a page change — the active video
  /// pauses for the duration and resumes once the snap settles.
  final bool  pauseForScroll;

  const _ShortPage({
    required this.video,
    required this.isActive,
    required this.autoPlayOnActivate,
    required this.pauseForScroll,
    super.key,
  });

  @override
  State<_ShortPage> createState() => _ShortPageState();
}

class _ShortPageState extends State<_ShortPage> {
  late YoutubePlayerController _controller;
  bool   _ready        = false;
  bool   _playing      = false;
  bool   _userStarted  = false;
  double _progress     = 0;

  // Pause-icon auto-hide: show the icon briefly, then fade after 700 ms.
  bool   _showPauseIcon = false;
  Timer? _pauseIconTimer;

  // Rate-limit controller callbacks to 15 fps — the WebView message channel
  // can fire more frequently than the screen refresh rate.
  int _lastMs = 0;

  @override
  void initState() {
    super.initState();
    final autoPlay = widget.autoPlayOnActivate && widget.isActive;
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: YoutubePlayerFlags(
        autoPlay:      autoPlay,
        loop:          true,
        hideControls:  true,
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

    if (ready != _ready ||
        playing != _playing ||
        (prog - _progress).abs() > 0.005) {
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

    // ── Pause during scroll ──────────────────────────────────────────────
    // pauseForScroll only applies when this page IS the active one.
    if (widget.pauseForScroll && !old.pauseForScroll && widget.isActive) {
      _controller.pause();
      if (mounted) setState(() => _playing = false);
      return; // Don't process isActive changes while scroll is in progress.
    }

    // ── Page deactivated (user scrolled to a different short) ────────────
    if (!widget.isActive && old.isActive) {
      _controller.pause();
      _pauseIconTimer?.cancel();
      if (mounted) setState(() {
        _playing      = false;
        _showPauseIcon = false;
      });
      return;
    }

    // ── Page activated (scroll settled on this short) ────────────────────
    if (widget.isActive && !old.isActive && widget.autoPlayOnActivate) {
      _userStarted = true;
      unawaited(EngagementService.instance.recordView(widget.video));
      if (_ready) _controller.play();
      // If not ready yet, the onReady callback below starts playback.
    }

    // ── Scroll released on this (already-active) page ────────────────────
    // old.pauseForScroll was true, now it's false → resume.
    if (!widget.pauseForScroll && old.pauseForScroll && widget.isActive) {
      if (_ready && _userStarted) _controller.play();
    }
  }

  @override
  void dispose() {
    _pauseIconTimer?.cancel();
    _controller
      ..removeListener(_onUpdate)
      ..dispose();
    super.dispose();
  }

  // ── Tap to play / pause ─────────────────────────────────────────────────

  void _togglePlay() {
    _userStarted = true;
    if (_playing) {
      _controller.pause();
      // Show the pause icon briefly then hide it after 700 ms — same as
      // TikTok and YouTube Shorts.
      _pauseIconTimer?.cancel();
      setState(() => _showPauseIcon = true);
      _pauseIconTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showPauseIcon = false);
      });
    } else {
      _controller.play();
      _pauseIconTimer?.cancel();
      setState(() => _showPauseIcon = false);
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

          // ── Player fills screen in 9:16 via FittedBox ──────────────────
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
                        !widget.pauseForScroll &&
                        (widget.autoPlayOnActivate || _userStarted)) {
                      _controller.play();
                    }
                  },
                  bufferIndicator: const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // ── Tap-to-play/pause ────────────────────────────────────────────
          // HitTestBehavior.opaque is required: SizedBox.expand() has no
          // child, so the default deferToChild behaviour returns false from
          // hitTest() and onTap never fires.  opaque forces the detector to
          // participate in hit testing regardless of its child's result.
          //
          // The outer GestureDetector (vertical drag) and this inner one
          // (tap) both enter Flutter's gesture arena; the arena
          // disambiguator hands taps to the inner detector and vertical
          // drags to the outer one — they never conflict.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _togglePlay,
            child: const SizedBox.expand(),
          ),

          // ── Loading spinner (before first play) ─────────────────────────
          if (!_ready && _userStarted)
            const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.gold, strokeWidth: 2.5),
            ),

          // ── Initial play button (not yet tapped) ─────────────────────────
          if (!_userStarted)
            Center(
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 38),
              ),
            ),

          // ── Pause icon (auto-hides after 700 ms) ────────────────────────
          if (_showPauseIcon)
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

          // ── Bottom gradient + title + progress bar ──────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin:  Alignment.bottomCenter,
                  end:    Alignment.topCenter,
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
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value:           _progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.gold),
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
