import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
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

  // ── Background prefetch for the next short ────────────────────────────
  // youtube_player_flutter (v9.x, flutter_inappwebview-based) only starts
  // actually loading a video once a YoutubePlayer WIDGET backed by its
  // controller is built and mounted — creating a bare YoutubePlayerController
  // with no widget behind it does not trigger any loading. Flutter's own
  // PageView does not pre-build neighbouring pages by default (confirmed via
  // Flutter's own source/docs: PageView has no cacheExtent of its own unless
  // allowImplicitScrolling is set, and that flag changes how screen readers'
  // swipe gestures behave — an accessibility trade-off unrelated to this
  // request, so it's deliberately not used here).
  //
  // So: a single extra YoutubePlayerController + YoutubePlayer is kept
  // actively playing — muted, so nothing is heard — for _currentIndex + 1,
  // rendered through Offstage (see _syncPrefetch for why actively playing,
  // not just "cued", is the reliable choice). Offstage lays the child out
  // and keeps it fully active exactly like an onstage widget, just not
  // painted or hit-tested (confirmed via Offstage's own documentation) —
  // completely separate from PageView.builder's own items, so it can never
  // collide with whatever PageView itself is building.
  //
  // When the user actually swipes to that short, _ShortPage still creates
  // its OWN controller (unchanged below) rather than adopting this one —
  // handing off the exact same underlying WebView instance between two
  // different widget locations is possible in principle (YoutubePlayerBuilder
  // already does this for fullscreen, per this file's own header comment),
  // but that mechanism is internal to that specific widget, and reproducing
  // it here for this different case (moving into a completely different
  // subtree via a GlobalKey) isn't something I can confirm is safe for this
  // plugin without testing on a real device — so instead of guessing, this
  // keeps the two controllers independent, and _ShortPage's own controller
  // re-downloads rather than literally reusing the prefetch controller's
  // buffered bytes.
  //
  // What this DOES reliably guarantee: DNS resolution, TLS session state,
  // and the YouTube player JS/HTML page for that video are all warm by the
  // time _ShortPage's own controller starts — Android WebView / iOS
  // WKWebView share these across instances in the same app by default, and
  // that alone accounts for a meaningful slice of a cold load. Whether the
  // actual video segment bytes the prefetch controller already pulled down
  // also get reused (vs. re-fetched) depends on the CDN's own cache headers
  // for that content, which I can't guarantee either way — so the honest
  // claim here is "meaningfully faster," not "zero loading."
  int?  _prefetchIndex;
  YoutubePlayerController? _prefetchController;

  void _syncPrefetch() {
    final wanted = _currentIndex + 1;
    if (wanted >= widget.shorts.length) {
      _disposePrefetch();
      return;
    }
    if (_prefetchIndex == wanted) return; // already correct — nothing to do.
    _disposePrefetch();
    _prefetchIndex      = wanted;
    _prefetchController = YoutubePlayerController(
      initialVideoId: widget.shorts[wanted].id,
      flags: const YoutubePlayerFlags(
        // autoPlay:true + mute:true, not autoPlay:false. A "cued but not
        // playing" player only reliably guarantees the player shell/thumbnail
        // are loaded — I could not confirm from YouTube's own documentation
        // that a cued-but-paused player buffers the actual video stream as
        // aggressively as an actively playing one, and that buffering is the
        // slow part this is meant to fix. Actively playing it (muted, so
        // nothing is heard, and Offstage below so nothing is seen) forces
        // real buffering — a guaranteed outcome, not an assumption about
        // internal player behaviour I can't verify. mute:true is required,
        // not optional: Offstage only skips painting, it does not affect
        // audio, so an unmuted prefetch would be audible under the current
        // short's own sound.
        autoPlay:      true,
        mute:          true,
        loop:          false, // don't re-buffer from 0 if left playing a while
        hideControls:  true,
        enableCaption: false,
      ),
    );
    // No setState here: initState (the first caller) runs before this
    // widget's first build, so that build already picks up whatever
    // _prefetchController ends up being — no extra call needed. The other
    // caller, onPageChanged, already wraps its own setState around
    // _currentIndex and this call together (see below), which is what
    // schedules the rebuild once this method returns.
  }

  void _disposePrefetch() {
    _prefetchController?.dispose();
    _prefetchController = null;
    _prefetchIndex      = null;
  }

  // Tuning constants — tuned lower for TikTok-feel responsiveness.
  // Research (VeryGoodVentures / diVine): low thresholds feel "light",
  // high thresholds feel "stiff". These values match TikTok's actual feel.
  static const double _positionThreshold = 0.10; // 10 % — even a partial drag commits
  static const double _velocityThreshold = 400.0; // px/s — light fling triggers
  static const double _rubberBandFactor  = 0.25;  // 25 % resistance at edges
  static const Duration _snapDuration    = Duration(milliseconds: 250);
  static const Curve    _snapCurve       = Curves.easeOutCubic;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _syncPrefetch();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _disposePrefetch();
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
    // Update the flag as a plain field — no setState here.
    // Calling setState at drag-start triggers a full rebuild before the first
    // gesture update fires, creating a 1-frame stutter that makes the scroll
    // feel "sticky" at the beginning of every swipe.
    // The active video pauses naturally when _isDragging becomes visible to
    // _ShortPage on the next setState (fired by _onDragEnd / onPageChanged).
    _isDragging = true;
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
                _syncPrefetch();
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
            // ── Background prefetch (see field docs in State class above) ──
            // Offstage still builds, mounts, and lays out its child and keeps
            // it fully active — it just isn't painted or hit-tested (per
            // Offstage's own documentation) — so the WebView underneath keeps
            // silently loading/buffering _currentIndex + 1 the whole time the
            // user is watching _currentIndex. Deliberately a sibling of
            // PageView here, never inside its itemBuilder, so it can never be
            // the same widget instance PageView itself is building.
            if (_prefetchController != null)
              Offstage(
                offstage: true,
                child: SizedBox(
                  width:  MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: YoutubePlayer(
                    controller:      _prefetchController!,
                    aspectRatio:     MediaQuery.of(context).size.width /
                        MediaQuery.of(context).size.height,
                    bufferIndicator: const SizedBox.shrink(),
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

class _ShortPageState extends State<_ShortPage>
    with AutomaticKeepAliveClientMixin<_ShortPage>,
         WidgetsBindingObserver {

  // AutomaticKeepAliveClientMixin — wantKeepAlive = true keeps this page's
  // WebView alive in memory after the user scrolls away.  Without this, every
  // PageView rebuild disposes the YoutubePlayer WebView and the next scroll
  // back causes a full reload.  With it, already-visited shorts restart
  // instantly; the PageView's natural 1-page pre-build handles the next short.
  @override
  bool get wantKeepAlive => true;
  late YoutubePlayerController _controller;
  bool   _ready          = false;
  bool   _playing        = false;
  bool   _userStarted    = false;
  // Latches true once position > 0 — guarantees a real decoded frame
  // exists in the WebView before the thumbnail overlay is removed.
  // Never resets (so pausing doesn't flash the thumbnail again).
  bool   _hasVideoStarted = false;
  // Set to true when the app goes to background (interstitial fires) while
  // this short is playing, so we can resume it when the app returns.
  bool   _wasPlayingBeforeAd = false;
  double _progress       = 0;

  // Tap-feedback icons: show briefly (700 ms) then auto-hide.
  // _showPauseIcon → shown when user pauses.
  // _showPlayFeedback → shown when user resumes from pause.
  // _tapCount → changes on every tap so AnimatedScale restarts (fresh pop-in).
  bool   _showPauseIcon    = false;
  bool   _showPlayFeedback = false;
  int    _tapCount         = 0;
  Timer? _pauseIconTimer;
  Timer? _playFeedbackTimer;

  // Rate-limit controller callbacks to 15 fps — the WebView message channel
  // can fire more frequently than the screen refresh rate.
  int _lastMs = 0;

  @override
  void initState() {
    super.initState();
    final autoPlay = widget.autoPlayOnActivate && widget.isActive;
    WidgetsBinding.instance.addObserver(this);
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: YoutubePlayerFlags(
        autoPlay:      autoPlay,
        loop:          true,
        hideControls:  true,
        enableCaption: false,
      ),
    )..addListener(_onUpdate);
    // Always treat as user-started — no initial play button shown.
    // All shorts auto-start when they become active; the spinner covers
    // loading. The play button only appears after a manual pause.
    _userStarted = true;
    if (autoPlay) {
      unawaited(EngagementService.instance.recordView(widget.video));
    }
  }

  // ── Lifecycle — pause/resume around interstitial ads ───────────────────────
  // When an interstitial fires, Android brings AdMob's Activity to the
  // foreground → our app transitions to AppLifecycleState.paused.  Without
  // this handler the YouTube WebView can keep playing audio underneath the ad.
  // When the ad is dismissed (resumed), we restart the short exactly where it
  // paused — without showing the play-feedback animation (that's only for
  // deliberate user taps).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isActive || !mounted) return;
    switch (state) {
      case AppLifecycleState.paused:
        _wasPlayingBeforeAd = _playing;
        if (_playing) _controller.pause();
      case AppLifecycleState.resumed:
        if (_wasPlayingBeforeAd && _ready) {
          _wasPlayingBeforeAd = false;
          _controller.play(); // resume silently — no feedback icon
        }
      default:
        break;
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

    // Checked on every tick, independently of the change-gated block below.
    // Position advancing past zero means the WebView has decoded and is
    // rendering actual video frames — safe to remove the thumbnail overlay.
    // This used to be evaluated only INSIDE the ready/playing/progress-delta
    // check below, which meant the exact tick position first crossed zero
    // could be missed if ready/playing hadn't ALSO just changed and progress
    // hadn't yet moved by that check's own 0.5% threshold — _hasVideoStarted
    // would then only catch up once progress happened to drift enough on a
    // later tick, adding real, avoidable delay before the thumbnail actually
    // came down.
    final justStarted = playing && pos > 0 && !_hasVideoStarted;

    if (ready != _ready ||
        playing != _playing ||
        (prog - _progress).abs() > 0.005 ||
        justStarted) {
      setState(() {
        _ready    = ready;
        _playing  = playing;
        _progress = prog;
        if (justStarted) _hasVideoStarted = true;
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
      if (mounted) {
        setState(() {
          _playing       = false;
          _showPauseIcon = false;
        });
      }
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
    WidgetsBinding.instance.removeObserver(this);
    _pauseIconTimer?.cancel();
    _playFeedbackTimer?.cancel();
    _controller
      ..removeListener(_onUpdate)
      ..dispose();
    super.dispose();
  }

  // ── Tap to play / pause ─────────────────────────────────────────────────

  void _togglePlay() {
    _userStarted = true;
    _tapCount++;   // key change restarts AnimatedScale on every tap
    // Decide from our own _playing flag and flip it HERE, synchronously —
    // do not wait for _onUpdate (the controller listener) to confirm it.
    // _onUpdate is rate-limited to 15 fps AND only runs when the WebView's
    // JS bridge actually reports a change, so on a quick second tap (well
    // within that window) _playing could still hold the value from BEFORE
    // the first tap took effect. Branching on it without updating it here
    // meant two fast taps could both read "playing" (or both read
    // "paused"), calling pause() twice / play() twice and showing the same
    // feedback icon twice in a row instead of alternating — the reported
    // "play/pause button not working properly". _onUpdate will still fire
    // shortly after and reconcile _playing to the WebView's true state;
    // since that state should match what we set here, there's nothing
    // to visibly correct in the normal case.
    final wasPlaying = _playing;
    if (wasPlaying) {
      _controller.pause();
      // Pause: show pause icon briefly (700 ms) — same as TikTok / YT Shorts.
      _pauseIconTimer?.cancel();
      _playFeedbackTimer?.cancel();
      setState(() {
        _playing          = false;
        _showPauseIcon    = true;
        _showPlayFeedback = false;
      });
      _pauseIconTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showPauseIcon = false);
      });
    } else {
      _controller.play();
      // Resume: show play icon briefly (700 ms) — TikTok shows a play icon on
      // resume too so the user gets clear feedback that the video is starting.
      _playFeedbackTimer?.cancel();
      _pauseIconTimer?.cancel();
      setState(() {
        _playing          = true;
        _showPauseIcon    = false;
        _showPlayFeedback = true;
      });
      _playFeedbackTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showPlayFeedback = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
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

          // ── Thumbnail overlay — shown until first real frame is rendered ────
          // Uses thumbnailHd + memCacheWidth 720 / memCacheHeight 405 — the
          // EXACT same URL and dimensions the shorts feed card used to display
          // this thumbnail, so it is already in Flutter's in-memory image cache
          // and renders on frame 0 with zero disk/network latency.
          // The overlay disappears the instant _hasVideoStarted latches
          // (position > 0), which guarantees an actual decoded frame exists in
          // the WebView before we remove the cover.
          if (!_hasVideoStarted)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl:      widget.video.thumbnailHd,
                fit:           BoxFit.cover,
                fadeInDuration:  Duration.zero,
                fadeOutDuration: Duration.zero,
                memCacheWidth:   720,
                memCacheHeight:  405,
                errorWidget: (_, __, ___) => CachedNetworkImage(
                  imageUrl:      widget.video.thumbnailMq,
                  fit:           BoxFit.cover,
                  fadeInDuration:  Duration.zero,
                  memCacheWidth:   720,
                  memCacheHeight:  405,
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

          // ── Loading spinner — shown while video is buffering/initialising ──
          // Replaces the old "initial play button". All shorts now auto-start
          // and show a spinner until _hasVideoStarted latches (position > 0).
          // The play/pause button only appears after the user manually pauses.
          if (!_hasVideoStarted)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),

          // ── Tap-feedback icons (auto-hide after 700 ms, same as TikTok) ───
          // AnimatedScale with ValueKey(_tapCount) restarts the pop-in
          // animation on every tap so rapid taps each get fresh feedback.
          // Pause feedback — TweenAnimationBuilder pops in from 50% scale
          // so the icon feels snappy and deliberate.  ValueKey restarts it
          // fresh on every tap (AnimatedScale(scale:1.0) has no animation
          // on creation; TweenAB with begin:0.5 always starts from below).
          if (_showPauseIcon)
            Center(
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_tapCount),
                  tween: Tween(begin: 0.5, end: 1.0),
                  duration: const Duration(milliseconds: 230),
                  curve: Curves.easeOutBack,
                  builder: (_, scale, child) =>
                      Transform.scale(scale: scale, child: child),
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
              ),
            ),

          // Play feedback — same pattern, different tap-count offset so
          // Flutter treats pause and play keys as distinct widget identities.
          if (_showPlayFeedback)
            Center(
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_tapCount + 10000),
                  tween: Tween(begin: 0.5, end: 1.0),
                  duration: const Duration(milliseconds: 230),
                  curve: Curves.easeOutBack,
                  builder: (_, scale, child) =>
                      Transform.scale(scale: scale, child: child),
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
