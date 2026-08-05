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
///
/// Production behaviour (Round 13 — instant start / no audio-under-thumbnail):
/// • Controller starts with autoPlay:true + mute:true so the WebView begins
///   buffering the moment it mounts — no extra wait for an onReady → play()
///   round-trip.
/// • Audio stays muted until position > 0 (first decoded frame). Thumbnail
///   and spinner stay up until that same latch. This eliminates the reported
///   "spinner finished, audio playing, thumbnail still covering" race: the
///   YouTube iframe can emit PlayerState.playing (and start decoding audio)
///   a few hundred ms before the first painted frame is reported via
///   position. Muting until the frame is proven keeps the user experience
///   silent-and-covered until the reveal is safe.
/// • Play / pause matches YouTube: brief centre feedback on every tap;
///   when paused after the video has started, a persistent centre play
///   button stays on screen until the user resumes.
/// • Fullscreen = in-place AnimatedContainer expand. No rotation, no new route.
/// • Video end = thumbnail + replay button.
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
  bool _ended = false;
  bool _playing = false;
  bool _ready = false;
  bool _fullscreen = false;
  /// Latches true once position > 0 — first real decoded frame exists.
  /// Never resets (so pausing does not flash the thumbnail again).
  bool _hasStartedPlaying = false;
  /// Instant UI source of truth for play/pause — updated on every tap
  /// without waiting for the JS bridge to confirm. Prevents double-tap
  /// races where two taps both read the same stale _playing value.
  bool _intendedPlaying = true;
  bool _showCenterIcon = false;
  int _tapCount = 0;
  Timer? _centerIconTimer;
  /// True once we have unmuted after the first frame. Guards against
  /// calling unMute() repeatedly on every tick.
  bool _unmuted = false;

  late final ValueNotifier<double> _progressNotifier;
  late final ValueNotifier<Duration> _positionNotifier;
  late final ValueNotifier<Duration> _durationNotifier;

  /// WebView is kept out of the tree until after frame 0 so the push
  /// transition never races the WebView's black init surface.
  bool _playerAttached = false;

  @override
  void initState() {
    super.initState();
    unawaited(EngagementService.instance.recordView(widget.video));
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _progressNotifier = ValueNotifier<double>(0);
    _positionNotifier = ValueNotifier<Duration>(Duration.zero);
    _durationNotifier = ValueNotifier<Duration>(Duration.zero);

    // Attach WebView on the next frame so frame 0 is pure thumbnail.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _playerAttached = true);
    });

    // autoPlay:true starts the network fetch as soon as the iframe is
    // ready — no second round-trip via onReady → play().
    // mute:true is mandatory until the first frame (see class docs).
    // hideControls:true — we draw our own controls; the package's native
    // play button would flash under the thumbnail during init.
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: true,
        hideControls: true,
        enableCaption: false,
      ),
    )..addListener(_onUpdate);
  }

  int _lastUpdateMs = 0;

  void _onUpdate() {
    if (!mounted) return;

    // Cap at ~30 fps — progress UI does not need WebView tick rate.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastUpdateMs < 33) return;
    _lastUpdateMs = nowMs;

    final cv = _controller.value;
    final ended = cv.playerState == PlayerState.ended;
    final playing = cv.playerState == PlayerState.playing;
    final ready = cv.isReady;
    final pos = cv.position;
    final dur = cv.metaData.duration;
    final prog = dur.inMilliseconds > 0
        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    _progressNotifier.value = prog;
    _positionNotifier.value = pos;
    _durationNotifier.value = dur;

    // First decoded frame proof — same signal used by shorts_player and
    // inline_video_card. Position advancing past zero means real frames
    // are painting; PlayerState.playing alone is not enough (audio can
    // start slightly earlier).
    final justStarted =
        !_hasStartedPlaying && playing && pos.inMilliseconds > 0;

    if (justStarted) {
      // Reveal video + unmute in the same frame. Audio was held mute so
      // the user never hears sound under the thumbnail.
      if (!_unmuted) {
        _controller.unMute();
        _unmuted = true;
      }
    }

    if (ended != _ended ||
        playing != _playing ||
        ready != _ready ||
        justStarted) {
      setState(() {
        _ended = ended;
        _playing = playing;
        _ready = ready;
        if (justStarted) {
          _hasStartedPlaying = true;
          _intendedPlaying = true;
          // Cancel any stale tap-bleed icon queued while loading.
          _showCenterIcon = false;
          _centerIconTimer?.cancel();
        }
        if (ended) {
          _intendedPlaying = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _centerIconTimer?.cancel();
    _progressNotifier.dispose();
    _positionNotifier.dispose();
    _durationNotifier.dispose();
    _controller
      ..removeListener(_onUpdate)
      ..dispose();
    super.dispose();
  }

  void _togglePlay() {
    // Source of truth is _intendedPlaying (updated synchronously here),
    // not _playing (which lags behind the JS bridge and is rate-limited).
    // This is what makes rapid tap-tap correctly alternate play/pause.
    final willPause = _intendedPlaying;
    if (willPause) {
      _controller.pause();
    } else {
      _controller.play();
    }
    unawaited(AdService.instance.onVideoPlayPauseTapped());

    setState(() {
      _intendedPlaying = !willPause;
      _playing = !willPause; // optimistic — listener will reconcile
      _tapCount++;
      // Only show the brief centre feedback after the video has actually
      // started. Prevents a navigation finger-up from flashing an icon
      // over the loading thumbnail.
      if (_hasStartedPlaying) _showCenterIcon = true;
    });

    if (_hasStartedPlaying) {
      _centerIconTimer?.cancel();
      _centerIconTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _showCenterIcon = false);
      });
    }
  }

  void _replay() {
    _progressNotifier.value = 0;
    _positionNotifier.value = Duration.zero;
    setState(() {
      _ended = false;
      // Keep _hasStartedPlaying true so we don't re-cover with thumbnail;
      // the player is already warm. Reset intended state for auto-play.
      _intendedPlaying = true;
      _playing = true;
    });
    _controller
      ..seekTo(Duration.zero)
      ..play();
  }

  void _seekTo(double fraction) {
    final dur = _durationNotifier.value;
    if (dur.inMilliseconds > 0) {
      _controller.seekTo(Duration(
          milliseconds: (fraction * dur.inMilliseconds).round()));
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
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
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
                  // ── [1] YouTube iframe ──────────────────────────────────
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
                            // autoPlay flag already requested play, but
                            // re-assert in case the flag was delayed by the
                            // package (known youtube_player_flutter quirk —
                            // see issue #840 workaround of calling play in
                            // onReady). Stay muted until first frame.
                            _controller
                              ..mute()
                              ..play();
                          },
                          onEnded: (_) {
                            if (mounted) {
                              setState(() {
                                _ended = true;
                                _intendedPlaying = false;
                                _playing = false;
                              });
                            }
                          },
                          bufferIndicator: const SizedBox.shrink(),
                        ),
                      ),
                    ),

                  // ── [2] Thumbnail — until first decoded frame ───────────
                  // Same URL + memCache dims as the feed card so the image
                  // is already in Flutter's memory cache on open.
                  if (!_hasStartedPlaying)
                    CachedNetworkImage(
                      imageUrl: widget.video.thumbnailHd,
                      fit: BoxFit.cover,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      memCacheWidth: 720,
                      memCacheHeight: 405,
                      errorWidget: (_, __, ___) => CachedNetworkImage(
                        imageUrl: widget.video.thumbnailMq,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        memCacheWidth: 720,
                        memCacheHeight: 405,
                      ),
                    ),

                  // ── [3] Spinner — same latch as the thumbnail ───────────
                  if (_playerAttached && !_hasStartedPlaying && !_ended)
                    const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.gold, strokeWidth: 3),
                    ),

                  if (_ended) _buildEndOverlay(),
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
                    : const SizedBox(
                        width: double.infinity,
                        child: LabelledBannerAd(),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    // Persistent play button when paused after start (YouTube pattern).
    // Brief feedback icon on every tap. Never shown during initial load.
    final showPersistentPlay =
        _hasStartedPlaying && !_intendedPlaying && !_showCenterIcon;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),

        // Brief tap-feedback (900 ms) — icon of the action just taken.
        // play → play icon, pause → pause icon. ValueKey restarts the
        // scale animation on every tap.
        if (_showCenterIcon && _hasStartedPlaying)
          IgnorePointer(
            child: Center(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(_tapCount),
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 230),
                curve: Curves.easeOutBack,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
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

        // Persistent centre play when paused (YouTube-style).
        if (showPersistentPlay)
          IgnorePointer(
            child: Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 42,
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
                  ValueListenableBuilder<double>(
                    valueListenable: _progressNotifier,
                    builder: (_, prog, __) => SizedBox(
                      height: 20,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12),
                          activeTrackColor: AppTheme.gold,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: AppTheme.gold,
                          overlayColor:
                              AppTheme.gold.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: prog.clamp(0.0, 1.0),
                          onChanged: _seekTo,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      ValueListenableBuilder<Duration>(
                        valueListenable: _positionNotifier,
                        builder: (_, pos, __) =>
                            ValueListenableBuilder<Duration>(
                          valueListenable: _durationNotifier,
                          builder: (_, dur, __) => Text(
                            '${_fmt(pos)} / ${_fmt(dur)}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 10),
                          ),
                        ),
                      ),
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
          memCacheWidth: 720,
          memCacheHeight: 405,
          errorWidget: (_, __, ___) => CachedNetworkImage(
            imageUrl: widget.video.thumbnailMq,
            fit: BoxFit.cover,
            memCacheWidth: 720,
            memCacheHeight: 405,
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
