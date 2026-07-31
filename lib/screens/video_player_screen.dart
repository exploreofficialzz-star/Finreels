import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/channel.dart';
import '../models/video.dart';
import '../services/ad_service.dart';
import '../services/engagement_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import 'channel_videos_screen.dart';

/// In-app video player.
/// • 16:9 forced ratio, YouTube controls hidden — custom controls drawn on top.
/// • Fullscreen = in-place AnimatedContainer expand. No rotation, no new route.
/// • Video end = thumbnail + replay button.
/// • Channel name row is tappable → channel page.
class VideoPlayerScreen extends StatefulWidget {
  final Video video;
  final Channel channel;

  const VideoPlayerScreen({
    required this.video,
    required this.channel,
    super.key,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _ended           = false;
  bool _playing          = false;
  bool _ready            = false;
  bool _fullscreen       = false;
  bool _hasStartedPlaying = false; // latches true on first play — never resets
  // Tracks what the USER intends, updated immediately on tap so the play
  // button disappears the instant they touch it — not 33ms later when the
  // YouTube JS confirms the state change.
  bool _intendedPlaying  = false;
  // Brief tap-feedback animation state (YouTube/TikTok pattern).
  bool _showCenterIcon   = false;
  int  _tapCount         = 0;       // incremented each tap to restart animation
  Timer? _centerIconTimer;
  // The WebView (YoutubePlayer) is intentionally kept OUT of the widget tree
  // until after the very first frame.  The push-transition animation runs
  // frame 0 with NO WebView in the tree, so its black initialisation screen
  // is never visible.  The thumbnail covers frame 0, then the WebView is
  // inserted from frame 1 while still hidden behind the thumbnail.
  bool _playerAttached   = false;
  double   _progress = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Learns from this open — see EngagementService for the honest scope
    // (on-device implicit-feedback ranking, not a trained model).
    unawaited(EngagementService.instance.recordView(widget.video));
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Attach the WebView one frame after the screen opens so the push
    // transition animation NEVER races against the WebView's black init frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _playerAttached = true);
    });
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: const YoutubePlayerFlags(
        hideControls: true,
      ),
    )..addListener(_onUpdate);
  }

  int _lastUpdateMs = 0;  // rate-limit _onUpdate to ≤30 calls/sec

  void _onUpdate() {
    if (!mounted) return;

    // Hard cap: ignore updates fired faster than every 33 ms (~30 fps).
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastUpdateMs < 33) return;
    _lastUpdateMs = nowMs;
    final v       = _controller.value;
    final ended   = v.playerState == PlayerState.ended;
    final playing = v.playerState == PlayerState.playing;
    final ready   = v.isReady;
    final pos     = v.position;
    final dur     = v.metaData.duration;
    final prog    = dur.inMilliseconds > 0
        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    if (ended != _ended || playing != _playing || ready != _ready ||
        (prog - _progress).abs() > 0.01) {
      setState(() {
        _ended    = ended;
        _playing  = playing;
        _ready    = ready;
        _progress = prog;
        _position = pos;
        _duration = dur;
        // Latch once the video position has actually advanced past zero.
        // PlayerState.playing fires from the YouTube JS API as soon as the
        // player's internal state machine transitions — but the WebView render
        // surface may not have painted the first frame yet.  position > 0
        // means the video clock is ticking, which only happens after real
        // decoded frames are being produced.  This eliminates the 1–3 frame
        // black gap between PlayerState.playing and the first visible frame.
        // Never resets so buffering pauses don't re-show the thumbnail.
        if (playing && pos.inMilliseconds > 0 && !_hasStartedPlaying) {
          _hasStartedPlaying = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _centerIconTimer?.cancel();
    _controller
      ..removeListener(_onUpdate)
      ..dispose();
    super.dispose();
  }

  void _togglePlay() {
    // Determine what action we're taking based on INTENT (not reported state)
    // so the UI responds the instant the user taps, not after the JS callback.
    final willPause = _playing || _intendedPlaying;
    willPause ? _controller.pause() : _controller.play();

    _centerIconTimer?.cancel();
    setState(() {
      _intendedPlaying = !willPause;
      _tapCount++;          // new key forces AnimatedScale to restart each tap
      _showCenterIcon = true;
    });
    // Auto-hide the feedback icon after 1.2 s (same timing as YouTube Shorts).
    _centerIconTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showCenterIcon = false);
    });
  }

  void _replay() {
    setState(() { _ended = false; _progress = 0; _hasStartedPlaying = false; });
    _controller.seekTo(Duration.zero);
    _controller.play();
  }

  void _seekTo(double fraction) {
    if (_duration.inMilliseconds > 0) {
      _controller.seekTo(Duration(
          milliseconds: (fraction * _duration.inMilliseconds).round()));
    }
  }

  void _toggleFullscreen() {
    setState(() => _fullscreen = !_fullscreen);
    SystemChrome.setEnabledSystemUIMode(
        _fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? "${d.inHours}:" : ""}$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final sw      = MediaQuery.of(context).size.width;
    final sh      = MediaQuery.of(context).size.height;
    final playerH = _fullscreen ? sh : sw * (9 / 16);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: !_fullscreen,
        bottom: false,
        child: Column(
          children: [
            if (!_fullscreen)
              AppBar(
                backgroundColor: AppTheme.bgColor(context),
                title: Text(widget.channel.name,
                    style: const TextStyle(fontSize: 15)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => Share.share(
                        '${widget.video.title}\n${widget.video.watchUrl}'),
                  ),
                ],
              ),

            // ── Player ──────────────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              height: playerH,
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── [1] YouTube iframe — gated on _playerAttached ───────
                  // Kept out of the tree until frame 1 (see initState) so the
                  // push-transition animation on frame 0 never shows the
                  // WebView's black initialisation screen.  The thumbnail [2]
                  // covers frame 0; from frame 1 the WebView loads silently
                  // behind it.
                  if (_playerAttached)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: sw,
                        height: sw * (9 / 16),
                        child: YoutubePlayer(
                          controller: _controller,
                          onReady: () {
                            if (!mounted) return;
                            setState(() => _ready = true);
                            _controller.play();
                          },
                          onEnded: (_) {
                            if (mounted) setState(() => _ended = true);
                          },
                          bufferIndicator: const SizedBox.shrink(),
                        ),
                      ),
                    ),

                  // ── [2] Thumbnail — ABOVE the iframe ────────────────────
                  // Shown from frame 0 (before the WebView is even in the
                  // tree) so the user ALWAYS sees content, never a black
                  // screen during the push transition.
                  //
                  // Primary image: thumbnailMq — already in CachedNetworkImage's
                  // memory cache from the feed scroll, so it renders on frame 0
                  // with zero network/disk latency.
                  //
                  // fadeInDuration: Duration.zero — disable CachedNetworkImage's
                  // built-in cross-fade so the thumbnail appears INSTANTLY, no
                  // second gap between placeholder and image.
                  //
                  // Removed INSTANTLY (no AnimatedOpacity, no delay) the exact
                  // moment _hasStartedPlaying latches true — the WebView has
                  // been in the tree since frame 1 and has fully painted by now.
                  if (!_hasStartedPlaying)
                    CachedNetworkImage(
                      imageUrl: widget.video.thumbnailMq,
                      fit: BoxFit.cover,
                      fadeInDuration:  Duration.zero,
                      fadeOutDuration: Duration.zero,
                      memCacheWidth:   800,
                      memCacheHeight:  450,
                      placeholder: (_, __) =>
                          const ColoredBox(color: Colors.black),
                      errorWidget: (_, __, ___) =>
                          const ColoredBox(color: Colors.black),
                    ),

                  // ── [3] Buffering spinner — shown after player attached, ready, not yet playing
                  if (_playerAttached && _ready && !_playing && !_ended && !_hasStartedPlaying)
                    const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.gold, strokeWidth: 3),
                    ),

                  if (_ended)  _buildEndOverlay(),
                  if (!_ended) _buildControls(context),
                ],
              ),
            ),

            if (!_fullscreen)
              Container(height: 3, color: widget.channel.accentColor),

            if (!_fullscreen)
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.video.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w700, height: 1.3)),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChannelVideosScreen(channel: widget.channel),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: widget.channel.accentColor
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: widget.channel.accentColor
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Center(
                                child: Text(widget.channel.initials,
                                    style: TextStyle(
                                        color: widget.channel.accentColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.channel.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.gold)),
                                  Text(widget.channel.focus,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: AppTheme.textMuted(context), size: 18),
                          ],
                        ),
                      ),
                      if (widget.video.description.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text('About this video',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: AppTheme.gold)),
                        const SizedBox(height: 8),
                        Text(widget.video.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.6),
                            maxLines: 12,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ),

            if (!_fullscreen)
              ListenableBuilder(
                listenable: AdService.instance,
                builder: (_, __) => AdService.instance.adsRemoved
                    ? const SizedBox.shrink()
                    : const LabelledBannerAd(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),
        // ── Brief tap-feedback icon (YouTube/TikTok pattern) ─────────────
        // The icon reflects the ACTION just taken (pause → shows pause icon,
        // play → shows play icon), auto-hides after 1.2 s.
        //
        // ValueKey(_tapCount) restarts AnimatedScale on every tap so repeated
        // fast taps each get a fresh scale-in animation.
        //
        // Only shows after the video has started (_hasStartedPlaying) so it
        // doesn't appear over the thumbnail during initial loading.
        if (_showCenterIcon && _hasStartedPlaying)
          IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                opacity: _showCenterIcon ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: AnimatedScale(
                  key: ValueKey(_tapCount),
                  scale: 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      // Icon reflects the action just taken:
                      // tapped to pause → show pause, tapped to play → show play
                      _intendedPlaying
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 20,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: AppTheme.gold,
                        inactiveTrackColor: Colors.white30,
                        thumbColor: AppTheme.gold,
                        overlayColor: AppTheme.gold.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: _progress.clamp(0.0, 1.0),
                        onChanged: _seekTo,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text('${_fmt(_position)} / ${_fmt(_duration)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10)),
                      const Spacer(),
                      GestureDetector(
                        onTap: _toggleFullscreen,
                        child: Icon(
                          _fullscreen
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_fullscreen)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () {
                setState(() => _fullscreen = false);
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEndOverlay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: widget.video.thumbnailHd,
          fit: BoxFit.cover,
          memCacheWidth: 800,
          memCacheHeight: 450,
          errorWidget: (_, __, ___) => CachedNetworkImage(
            imageUrl: widget.video.thumbnailMq,
            fit: BoxFit.cover,
            memCacheWidth: 800,
            memCacheHeight: 450,
            errorWidget: (_, __, ___) =>
                const ColoredBox(color: Colors.black),
          ),
        ),
        const ColoredBox(color: Color(0x99000000)),
        Center(
          child: GestureDetector(
            onTap: _replay,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                      color: AppTheme.gold, shape: BoxShape.circle),
                  child: const Icon(Icons.replay_rounded,
                      color: Colors.black, size: 34),
                ),
                const SizedBox(height: 10),
                const Text('Replay',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
