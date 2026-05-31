import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/channel.dart';
import '../models/video.dart';
import '../services/ad_service.dart';
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
  bool _ended      = false;
  bool _playing    = false;
  bool _ready      = false;
  bool _fullscreen = false;
  double   _progress = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Fire ad AFTER the push-navigation animation completes so it never
    // causes a black flash during the hero transition.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AdService.instance.onContentTapped());
    });
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: const YoutubePlayerFlags(
        hideControls: true,
      ),
    )..addListener(_onUpdate);
  }

  void _onUpdate() {
    if (!mounted) return;
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
        (prog - _progress).abs() > 0.005) {
      setState(() {
        _ended    = ended;
        _playing  = playing;
        _ready    = ready;
        _progress = prog;
        _position = pos;
        _duration = dur;
      });
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
    _playing ? _controller.pause() : _controller.play();
  }

  void _replay() {
    setState(() { _ended = false; _progress = 0; });
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
                  // ── Thumbnail — always visible until player is playing ──
                  // This eliminates the black flash: the user sees the
                  // thumbnail the instant the screen opens, while the
                  // YouTube iframe warms up in the background.
                  AnimatedOpacity(
                    opacity: (_ready && _playing) ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: CachedNetworkImage(
                      imageUrl: widget.video.thumbnailHd,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => CachedNetworkImage(
                        imageUrl: widget.video.thumbnailMq,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const ColoredBox(color: Colors.black),
                      ),
                    ),
                  ),

                  // ── YouTube iframe (behind overlay until ready) ──────────
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: sw,
                      height: sw * (9 / 16),
                      child: YoutubePlayer(
                        controller: _controller,
                        onReady: () {
                          if (mounted) setState(() => _ready = true);
                        },
                        onEnded: (_) {
                          if (mounted) setState(() => _ended = true);
                        },
                        bufferIndicator: const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // ── Buffering spinner (only after ready, while buffering) ─
                  if (_ready && !_playing && !_ended)
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

            if (!_fullscreen && !AdService.instance.adsRemoved)
              const LabelledBannerAd(),
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
        if (!_playing && _ready)
          Center(
            child: IgnorePointer(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 34),
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
          errorWidget: (_, __, ___) => CachedNetworkImage(
            imageUrl: widget.video.thumbnailMq,
            fit: BoxFit.cover,
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
