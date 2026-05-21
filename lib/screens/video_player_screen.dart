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

/// In-app video player for long-form YouTube content.
///
/// Design decisions:
/// • App is hard-locked portrait via AndroidManifest — no rotation ever.
/// • Player sized to 16:9 via AspectRatio. YouTube's own controls are hidden;
///   we draw a clean custom control bar on top.
/// • Full-screen = same screen, player expands to fill the full display height
///   using an AnimatedContainer. No rotation, no new route, no Transform.
/// • When video ends: pause + show thumbnail with gold replay button.
/// • Channel name row is tappable — leads to channel page.
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
  bool _ended   = false;
  bool _playing = false;
  bool _ready   = false;
  bool _fullscreen = false;
  double _progress = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    unawaited(AdService.instance.onContentTapped());
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        // Hide YouTube's own controls — we draw clean custom ones
        hideControls: true,
        disableDragSeek: false,
        enableCaption: false,
        loop: false,
        useHybridComposition: true,
      ),
    )..addListener(_onUpdate);
  }

  void _onUpdate() {
    if (!mounted) return;
    final v = _controller.value;
    final ended  = v.playerState == PlayerState.ended;
    final playing = v.playerState == PlayerState.playing;
    final ready  = v.isReady;
    final pos    = v.position;
    final dur    = v.metaData.duration;
    final prog   = (dur.inMilliseconds > 0)
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
    if (_playing) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _replay() {
    setState(() { _ended = false; _progress = 0; });
    _controller.seekTo(Duration.zero);
    _controller.play();
  }

  void _seekTo(double fraction) {
    if (_duration.inMilliseconds > 0) {
      _controller.seekTo(
          Duration(milliseconds: (fraction * _duration.inMilliseconds).round()));
    }
  }

  void _toggleFullscreen() {
    setState(() => _fullscreen = !_fullscreen);
    if (_fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _openChannel() {
    Navigator.push(context,
        MaterialPageRoute(
            builder: (_) => ChannelVideosScreen(channel: widget.channel)));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? "${d.inHours}:" : ""}$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final playerH = _fullscreen
        ? screenH
        : MediaQuery.of(context).size.width * (9 / 16);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: !_fullscreen,
        bottom: false,
        child: Column(
          children: [
            // ── AppBar (hidden in fullscreen) ───────────────────────────────
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

            // ── Player container ────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              height: playerH,
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // iFrame player — 16:9 scaled via FittedBox
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width * (9 / 16),
                      child: YoutubePlayer(
                        controller: _controller,
                        showVideoProgressIndicator: false,
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

                  // ── End state overlay ─────────────────────────────────────
                  if (_ended) _buildEndOverlay(),

                  // ── Buffering spinner ─────────────────────────────────────
                  if (!_ready && !_ended)
                    const Center(child: CircularProgressIndicator(
                        color: AppTheme.gold, strokeWidth: 3)),

                  // ── Custom controls (tap-to-play/pause + progress) ────────
                  if (!_ended) _buildControls(context),
                ],
              ),
            ),

            // Channel accent strip
            if (!_fullscreen)
              Container(height: 3, color: widget.channel.accentColor),

            // ── Info section (hidden in fullscreen) ─────────────────────────
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

                      // Tappable channel row
                      GestureDetector(
                        onTap: _openChannel,
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

  // ── Custom controls overlay ─────────────────────────────────────────────────

  Widget _buildControls(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Tap anywhere to toggle play/pause
        GestureDetector(
          onTap: _togglePlay,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),

        // Centre play/pause icon (shows briefly)
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

        // Bottom control bar: time + seek bar + fullscreen toggle
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
                  // Seek bar
                  SizedBox(
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
                        value: _progress.clamp(0.0, 1.0),
                        onChanged: _seekTo,
                      ),
                    ),
                  ),
                  // Time row + fullscreen button
                  Row(
                    children: [
                      Text(
                        '${_fmt(_position)} / ${_fmt(_duration)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10),
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

        // Back button in fullscreen mode
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

  // ── End state overlay ───────────────────────────────────────────────────────

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
                  decoration: BoxDecoration(
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
