import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../data/channel_data.dart';
import '../models/channel.dart';
import '../models/video.dart';
import '../providers/feed_provider.dart';
import '../services/ad_service.dart';
import '../services/engagement_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/no_flash_page_route.dart';
import 'channel_videos_screen.dart';
import 'video_landscape_screen.dart';

/// In-app video player (Round 14 — theme, watermark, sound, landscape, see more).
///
/// • Starts with sound (mute:false). Thumbnail stays until first decoded frame
///   so the WebView never flashes black; audio is allowed immediately.
/// • No solid black bar covering the bottom of the video — only a slim
///   gradient behind the scrubber. YouTube branding is covered by a FinReels
///   watermark chip at the bottom-right.
/// • Fullscreen opens a dedicated landscape route (does not rotate the whole
///   app shell). Position is restored on return.
/// • Content area below the player uses the active theme (light/dark).
/// • "See more" row shows suggested long-form videos from other channels in
///   the same category (with general feed fallback).
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
  /// Latches true once position > 0 — first real decoded frame.
  /// Never resets after start (prevents thumbnail flash on pause/play).
  bool _hasStartedPlaying = false;
  bool _intendedPlaying = true;
  bool _showCenterIcon = false;
  int _tapCount = 0;
  Timer? _centerIconTimer;

  late final ValueNotifier<double> _progressNotifier;
  late final ValueNotifier<Duration> _positionNotifier;
  late final ValueNotifier<Duration> _durationNotifier;

  bool _playerAttached = false;
  bool _openingLandscape = false;

  @override
  void initState() {
    super.initState();
    unawaited(EngagementService.instance.recordView(widget.video));
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _progressNotifier = ValueNotifier<double>(0);
    _positionNotifier = ValueNotifier<Duration>(Duration.zero);
    _durationNotifier = ValueNotifier<Duration>(Duration.zero);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _playerAttached = true);
    });

    // Sound ON from the start. Thumbnail covers until position > 0 so the
    // WebView's black init surface is never visible.
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true,
        enableCaption: false,
      ),
    )..addListener(_onUpdate);
  }

  int _lastUpdateMs = 0;

  void _onUpdate() {
    if (!mounted) return;
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

    final justStarted =
        !_hasStartedPlaying && playing && pos.inMilliseconds > 0;

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
    final willPause = _intendedPlaying;
    if (willPause) {
      _controller.pause();
    } else {
      _controller.play();
    }
    unawaited(AdService.instance.onVideoPlayPauseTapped());

    setState(() {
      _intendedPlaying = !willPause;
      _playing = !willPause;
      _tapCount++;
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
      // Keep _hasStartedPlaying true — no thumbnail flash on replay.
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

  Future<void> _openLandscape() async {
    if (_openingLandscape) return;
    _openingLandscape = true;
    final resumeAt = _controller.value.position;

    // Fully tear down the portrait WebView BEFORE opening landscape.
    // Two youtube_player_flutter controllers for the same videoId on
    // screen at once leave the landscape instance stuck on the poster
    // (00:00 / 00:00) — confirmed against device screenshots.
    _controller.removeListener(_onUpdate);
    _controller.pause();
    _controller.dispose();

    final returned = await Navigator.of(context).push<Duration>(
      NoFlashPageRoute(
        builder: (_) => VideoLandscapeScreen(
          videoId: widget.video.id,
          startAt: resumeAt,
          thumbnailUrl: widget.video.thumbnailHd,
        ),
      ),
    );
    if (!mounted) return;

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final seekTo = returned ?? resumeAt;
    // Recreate portrait controller at the returned position.
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true,
        enableCaption: false,
        startAt: seekTo.inSeconds.clamp(0, 1 << 30),
      ),
    )..addListener(_onUpdate);

    setState(() {
      _hasStartedPlaying = true; // skip thumbnail flash — user already watched
      _intendedPlaying = true;
      _playing = true;
      _ended = false;
      _playerAttached = true;
      _openingLandscape = false;
    });

    // Seek again after a short delay in case startAt was ignored.
    if (seekTo > Duration.zero) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        try {
          _controller.seekTo(seekTo);
          _controller.play();
        } catch (_) {}
      });
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? "${d.inHours}:" : ""}$m:$s';
  }

  List<Video> _suggestions() {
    final fp = FeedProvider.instance;
    if (fp == null) return const [];
    return fp.suggestedFor(
      excludeVideoId: widget.video.id,
      excludeChannelId: widget.channel.id,
      categoryId: widget.channel.resourceCategoryId,
      limit: 12,
    );
  }

  void _openSuggested(Video v) {
    final ch = ChannelData.byId[v.channelId] ?? ChannelData.fallback;
    Navigator.of(context).pushReplacement(
      NoFlashPageRoute(
        builder: (_) => VideoPlayerScreen(video: v, channel: ch),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final playerH = sw * (9 / 16);
    final bg = AppTheme.bgColor(context);
    final suggestions = _suggestions();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppBar(
              backgroundColor: bg,
              elevation: 0,
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

            // ── Player (always 16:9, black only inside the video frame) ──
            SizedBox(
              width: double.infinity,
              height: playerH,
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_playerAttached)
                      YoutubePlayer(
                        controller: _controller,
                        onReady: () {
                          if (!mounted) return;
                          setState(() => _ready = true);
                          // Re-assert play with sound (package quirk).
                          _controller
                            ..unMute()
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

                    // Thumbnail until first frame — zero fade to avoid flash.
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

                    if (_playerAttached && !_hasStartedPlaying && !_ended)
                      const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.gold, strokeWidth: 3),
                      ),

                    // Solid cover over the YouTube logo region (bottom-right
                    // of the iframe). Sized from device screenshots so the
                    // native YouTube mark is fully hidden; FinReels branding
                    // sits on the cover. Placed above the scrubber gradient.
                    if (_hasStartedPlaying && !_ended)
                      const Positioned(
                        right: 0,
                        bottom: 44,
                        child: _FinReelsWatermark(),
                      ),

                    if (_ended) _buildEndOverlay(),
                    if (!_ended) _buildControls(context),
                  ],
                ),
              ),
            ),

            // Slim accent under the player (not a black bar).
            Container(height: 2, color: widget.channel.accentColor),

            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                      Divider(color: AppTheme.dividerColor(context)),
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

                    // ── See more / suggested videos ───────────────────────
                    if (suggestions.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Divider(color: AppTheme.dividerColor(context)),
                      const SizedBox(height: 16),
                      Text('See more',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.gold)),
                      const SizedBox(height: 4),
                      Text(
                        widget.channel.resourceCategoryId != null
                            ? 'More from related channels'
                            : 'Suggested for you',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      ...suggestions.map((v) {
                        final ch =
                            ChannelData.byId[v.channelId] ?? ChannelData.fallback;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SuggestedTile(
                            video: v,
                            channel: ch,
                            onTap: () => _openSuggested(v),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

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
        // Slim gradient only behind the scrubber — not a solid black bar.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xCC000000), Colors.transparent],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: _progressNotifier,
                    builder: (_, prog, __) => SizedBox(
                      height: 18,
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
                        onTap: _openLandscape,
                        child: const Icon(
                          Icons.fullscreen_rounded,
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

// ── FinReels watermark chip (covers YouTube logo) ───────────────────────────

class _FinReelsWatermark extends StatelessWidget {
  const _FinReelsWatermark();

  @override
  Widget build(BuildContext context) {
    // Opaque block sized to the YouTube logo region in the iframe
    // (bottom-right). Semi-transparent chips left the YT mark readable.
    return Container(
      width: 120,
      height: 34,
      alignment: Alignment.center,
      color: const Color(0xF2000000),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Image.asset(
              'assets/icons/app_icon.png',
              width: 16,
              height: 16,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.play_arrow_rounded,
                color: AppTheme.gold,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'FinReels',
            style: TextStyle(
              color: AppTheme.gold,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Suggested video tile ────────────────────────────────────────────────────

class _SuggestedTile extends StatelessWidget {
  final Video video;
  final Channel channel;
  final VoidCallback onTap;

  const _SuggestedTile({
    required this.video,
    required this.channel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceColor(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.dividerColor(context), width: 0.5),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 140,
                  height: 80,
                  child: CachedNetworkImage(
                    imageUrl: video.thumbnailHd,
                    fit: BoxFit.cover,
                    memCacheWidth: 280,
                    memCacheHeight: 160,
                    errorWidget: (_, __, ___) => CachedNetworkImage(
                      imageUrl: video.thumbnailMq,
                      fit: BoxFit.cover,
                      memCacheWidth: 280,
                      memCacheHeight: 160,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${channel.name} · ${timeago.format(video.publishedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
