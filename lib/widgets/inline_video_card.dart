import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:visibility_detector/visibility_detector.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/channel.dart';
import '../models/video.dart';
import '../screens/channel_videos_screen.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fixes in this file:
//
// 1. NO BLACK FLASH (real fix — root cause was widget subtree replacement)
//    Previously, tapping the thumbnail swapped TWO ENTIRELY SEPARATE widget
//    subtrees (_buildThumbnail() ↔ _buildPlayerArea()) via a ternary in
//    build(). Flutter had to unmount the thumbnail's Image widget and mount
//    a brand new one inside the player area in the same frame — combined
//    with the YouTube WebView's native platform-view surface ALSO
//    initialising in that same frame (which itself renders black for its
//    first few frames at the OS compositing level, regardless of Flutter
//    widget opacity), this produced the "goes black, then comes back, then
//    plays" flash.
//
//    Fix: ONE media area is built and stays mounted for the lifetime of the
//    card. The thumbnail Image widget is never torn down — the player is
//    simply inserted as an ADDITIONAL Stack layer above it once the user
//    taps, hidden behind a deliberate reveal-delay (not just onReady) so any
//    native platform-view black frame happens while the thumbnail is still
//    the only visible thing.
//
// 2. VIDEO PAUSE AD TRIGGER
//    Every time the user taps pause (the play/pause button or a tap on the
//    player area while playing), AdService.onVideoTapped() is called.
//    Ad fires every 2nd pause (interstitialCycleLength).
//    This is tracked inside YoutubePlayer via a controller listener that
//    watches for PlayerState transitions from playing → paused.
//
// 3. FULLSCREEN — no restart
//    YoutubePlayerBuilder moves the existing WebView into an Overlay.
//    Same controller, same position, zero restart.
//    We only set orientation in the callbacks.
//
// 4. YOUTUBE BRANDING COVERED
//    36 px black bar at the bottom of the player.
//    Flutter replay overlay covers end-screen cards.
// ─────────────────────────────────────────────────────────────────────────────

class InlineVideoCard extends StatefulWidget {
  final Video video;
  final Channel channel;
  final bool saved;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final ValueNotifier<String?> activeVideoNotifier;

  const InlineVideoCard({
    required this.video,
    required this.channel,
    required this.activeVideoNotifier,
    super.key,
    this.saved = false,
    this.onSave,
    this.onShare,
  });

  @override
  State<InlineVideoCard> createState() => _InlineVideoCardState();
}

class _InlineVideoCardState extends State<InlineVideoCard>
    with AutomaticKeepAliveClientMixin {
  YoutubePlayerController? _controller;
  bool _playerReady  = false; // YouTube IFrame API onReady fired
  bool _revealPlayer = false; // true only after onReady + grace delay
  bool _expanded     = false; // true once the user has tapped
  bool _ended        = false;
  Timer? _revealTimer;

  /// Tracks the previous PlayerState so we can detect playing → paused.
  PlayerState _prevState = PlayerState.unknown;

  bool get _isActive =>
      widget.activeVideoNotifier.value == widget.video.id;

  @override
  bool get wantKeepAlive => _expanded;

  @override
  void initState() {
    super.initState();
    widget.activeVideoNotifier.addListener(_onActiveChanged);
  }

  @override
  void dispose() {
    widget.activeVideoNotifier.removeListener(_onActiveChanged);
    _revealTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  // ── Play / pause coordination ─────────────────────────────────────────────

  void _onActiveChanged() {
    if (!mounted || _controller == null) return;
    if (_isActive && _playerReady) {
      _controller!.play();
    } else if (!_isActive) {
      _controller!.pause();
    }
  }

  /// Called the moment the YouTube IFrame API reports ready (via either the
  /// onReady callback OR the controller listener — both funnel through here
  /// so there is exactly one reveal mechanism, not two competing ones).
  void _markReady() {
    if (!mounted || _playerReady) return;
    setState(() => _playerReady = true);
    if (_isActive) _controller?.play();

    // Grace delay before revealing the player layer. The YouTube IFrame
    // API's "ready" event does NOT guarantee the underlying native
    // platform-view (WebView) surface has finished its own initialisation —
    // that surface can still render a black frame for a short period
    // afterwards at the OS compositing level, which Flutter-side opacity
    // alone cannot mask. Waiting a beat here ensures any such black frame
    // happens while the thumbnail is still the only thing visible.
    _revealTimer?.cancel();
    _revealTimer = Timer(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _revealPlayer = true);
    });
  }

  int _lastCardUpdateMs = 0;

  void _onControllerUpdate() {
    if (!mounted) return;

    // Rate-limit to 15 calls/sec — the listener fires on every WebView tick,
    // which is far more than needed for ready/pause detection.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastCardUpdateMs < 66) return;
    _lastCardUpdateMs = nowMs;
    final v     = _controller!.value;
    final ready = v.isReady;

    // Detect ready state change.
    if (ready != _playerReady) _markReady();

    // Detect playing → paused transition to trigger ad.
    final currentState = v.playerState;
    if (_prevState == PlayerState.playing &&
        currentState == PlayerState.paused) {
      AdService.instance.onVideoTapped();
    }
    _prevState = currentState;
  }

  // ── Tap thumbnail → create player ─────────────────────────────────────────

  void _onTap() {
    if (_controller == null) {
      _controller = YoutubePlayerController(
        initialVideoId: widget.video.id,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          enableCaption: false,
          // hideControls = false (default) → all native controls visible.
        ),
      )..addListener(_onControllerUpdate);
      if (mounted) setState(() { _expanded = true; _ended = false; });
      updateKeepAlive();
    }
    // Already expanded — tapping again should not recreate the controller
    // or reset reveal state; just (re)claim "active" status in the feed.
    widget.activeVideoNotifier.value = widget.video.id;
  }

  void _onReplay() {
    if (_controller == null) return;
    setState(() => _ended = false);
    _controller!
      ..seekTo(Duration.zero)
      ..play();
  }

  // ── Visibility: pause when scrolled off screen ────────────────────────────

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted || _controller == null || !_expanded) return;
    if (info.visibleFraction < 0.2) {
      _controller!.pause();
    } else if (info.visibleFraction >= 0.5 && _isActive && _playerReady) {
      _controller!.play();
    }
  }

  // ── Fullscreen — orientation only ─────────────────────────────────────────

  void _onEnterFullScreen() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _onExitFullScreen() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor(context), width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMediaArea(context),
            Container(height: 3, color: widget.channel.accentColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        height: 1.35, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChannelVideosScreen(channel: widget.channel),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                                color: widget.channel.accentColor,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(widget.channel.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.gold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '· ${timeago.format(widget.video.publishedAt)}',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (widget.onSave != null || widget.onShare != null) ...[
                      const SizedBox(width: 4),
                      _actionMenu(context),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Media area — ALWAYS mounted, never torn down ───────────────────────────
  //
  // This single widget handles every state (thumbnail-only, loading,
  // playing, ended). The Stack and its thumbnail Image layer persist for the
  // entire lifetime of this card — only the player layer is conditionally
  // inserted on top once the user taps. This is the structural fix for the
  // black-flash issue: no subtree is ever unmounted+remounted on tap.

  Widget _buildMediaArea(BuildContext context) {
    final media = AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 0: thumbnail — always mounted, never rebuilt on tap.
            CachedNetworkImage(
              imageUrl: widget.video.thumbnailHd,
              fit: BoxFit.cover,
              placeholder: (_, __) => Shimmer.fromColors(
                baseColor:      const Color(0xFF1E1E1E),
                highlightColor: const Color(0xFF2C2C2C),
                child: const ColoredBox(color: Colors.white),
              ),
              errorWidget: (_, __, ___) => CachedNetworkImage(
                imageUrl: widget.video.thumbnailMq,
                fit: BoxFit.cover,
                placeholder: (_, __) => Shimmer.fromColors(
                  baseColor:      const Color(0xFF1E1E1E),
                  highlightColor: const Color(0xFF2C2C2C),
                  child: const ColoredBox(color: Colors.white),
                ),
                errorWidget: (_, __, ___) =>
                    ColoredBox(color: AppTheme.surfaceElevated(context)),
              ),
            ),

            // Layer 1: player — only inserted once the controller exists,
            // hidden until _revealPlayer latches true (grace-delayed past
            // onReady — see _markReady).
            if (_controller != null)
              AnimatedOpacity(
                opacity:  _revealPlayer ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 280),
                child: YoutubePlayerBuilder(
                  onEnterFullScreen: _onEnterFullScreen,
                  onExitFullScreen:  _onExitFullScreen,
                  player: YoutubePlayer(
                    controller: _controller!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: AppTheme.gold,
                    progressColors: const ProgressBarColors(
                      playedColor: AppTheme.gold,
                      handleColor: AppTheme.gold,
                    ),
                    onReady: _markReady,
                    onEnded: (_) {
                      if (mounted) setState(() => _ended = true);
                    },
                    bufferIndicator: const SizedBox.shrink(),
                  ),
                  builder: (context, player) => player,
                ),
              ),

            // Layer 2: spinner while the WebView warms up.
            if (_controller != null && !_revealPlayer && !_ended)
              const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.gold, strokeWidth: 2.5),
              ),

            // Layer 3: play button — only before the first tap.
            if (_controller == null)
              Center(
                child: Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 32),
                ),
              ),

            // Layer 4: black bar hides YouTube watermark — once the player
            // has been tapped (regardless of reveal state) and not ended.
            if (_controller != null && !_ended)
              const Positioned(
                bottom: 0, left: 0, right: 0,
                child: SizedBox(
                    height: 36, child: ColoredBox(color: Colors.black)),
              ),

            // Layer 5: our end screen hides YouTube's recommendation cards.
            if (_ended) _buildEndOverlay(),
          ],
        ),
      ),
    );

    // VisibilityDetector only matters once a player exists — wrapping it
    // unconditionally is harmless and keeps the key stable across rebuilds.
    return VisibilityDetector(
      key: Key('player_${widget.video.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: media,
    );
  }

  Widget _buildEndOverlay() {
    return Stack(fit: StackFit.expand, children: [
      CachedNetworkImage(
        imageUrl: widget.video.thumbnailHd,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => CachedNetworkImage(
          imageUrl: widget.video.thumbnailMq,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black),
        ),
      ),
      const ColoredBox(color: Color(0xBB000000)),
      Center(
        child: GestureDetector(
          onTap: _onReplay,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60, height: 60,
              decoration: const BoxDecoration(
                  color: AppTheme.gold, shape: BoxShape.circle),
              child: const Icon(Icons.replay_rounded,
                  color: Colors.black, size: 32),
            ),
            const SizedBox(height: 10),
            const Text('Replay',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
        ),
      ),
    ]);
  }

  Widget _actionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          size: 18, color: AppTheme.textMuted(context)),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        if (widget.onSave != null)
          PopupMenuItem(
            value: 'save',
            child: Row(children: [
              Icon(
                widget.saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_add_outlined,
                size: 18, color: AppTheme.gold,
              ),
              const SizedBox(width: 10),
              Text(widget.saved ? 'Remove bookmark' : 'Bookmark'),
            ]),
          ),
        if (widget.onShare != null)
          const PopupMenuItem(
            value: 'share',
            child: Row(children: [
              Icon(Icons.share_outlined, size: 18),
              SizedBox(width: 10),
              Text('Share'),
            ]),
          ),
      ],
      onSelected: (v) {
        if (v == 'save')  widget.onSave?.call();
        if (v == 'share') widget.onShare?.call();
      },
    );
  }
}
