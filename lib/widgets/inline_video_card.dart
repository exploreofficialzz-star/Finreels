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
// 1. NO BLACK FLASH
//    Thumbnail always visible under the player. Player is opacity-0 until
//    onReady fires, then fades in over 300 ms. User sees thumbnail → spinner
//    → player — never a black screen.
//
// 2. VIDEO PAUSE AD TRIGGER
//    Every time the user taps pause (the play/pause button or a tap on the
//    player area while playing), AdService.onVideoPaused() is called.
//    Ad fires every 4th pause: pauses 4, 8, 12 …
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
  bool _playerReady = false;
  bool _expanded    = false;
  bool _ended       = false;

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

  void _onControllerUpdate() {
    if (!mounted) return;
    final v     = _controller!.value;
    final ready = v.isReady;

    // Detect ready state change.
    if (ready != _playerReady) {
      setState(() => _playerReady = ready);
      if (ready && _isActive) _controller?.play();
    }

    // Detect playing → paused transition to trigger ad.
    final currentState = v.playerState;
    if (_prevState == PlayerState.playing &&
        currentState == PlayerState.paused) {
      AdService.instance.onVideoPaused();
    }
    _prevState = currentState;
  }

  // ── Tap thumbnail → create player ─────────────────────────────────────────

  void _onTap() {
    if (_controller == null) {
      _controller = YoutubePlayerController(
        initialVideoId: widget.video.id,
        flags: const YoutubePlayerFlags(
          autoPlay:      true,
          enableCaption: false,
          // hideControls = false (default) → all native controls visible.
        ),
      )..addListener(_onControllerUpdate);
      if (mounted) setState(() { _expanded = true; _ended = false; });
      updateKeepAlive();
    }
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
            _expanded && _controller != null
                ? _buildPlayerArea()
                : _buildThumbnail(context),
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

  // ── Player area ───────────────────────────────────────────────────────────

  Widget _buildPlayerArea() {
    return VisibilityDetector(
      key: Key('player_${widget.video.id}'),
      onVisibilityChanged: _onVisibilityChanged,
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
          onReady: () {
            if (mounted) setState(() => _playerReady = true);
            if (_isActive) _controller?.play();
          },
          onEnded: (_) {
            if (mounted) setState(() => _ended = true);
          },
          bufferIndicator: const SizedBox.shrink(),
        ),
        builder: (context, player) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Layer 1: thumbnail always underneath (no black flash).
                CachedNetworkImage(
                  imageUrl: widget.video.thumbnailHd,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => CachedNetworkImage(
                    imageUrl: widget.video.thumbnailMq,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        ColoredBox(color: AppTheme.surfaceElevated(context)),
                  ),
                ),
                // Layer 2: player fades in when ready.
                AnimatedOpacity(
                  opacity:  _playerReady ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: player,
                ),
                // Layer 3: spinner while WebView initialises.
                if (!_playerReady && !_ended)
                  const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.gold, strokeWidth: 2.5),
                  ),
                // Layer 4: black bar hides YouTube watermark.
                if (!_ended)
                  const Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: SizedBox(
                        height: 36, child: ColoredBox(color: Colors.black)),
                  ),
                // Layer 5: our end screen hides YouTube's recommendation cards.
                if (_ended) _buildEndOverlay(),
              ],
            ),
          );
        },
      ),
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

  Widget _buildThumbnail(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: _onTap,
        child: Stack(fit: StackFit.expand, children: [
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
        ]),
      ),
    );
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
