import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/video.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';

/// Full-screen 9:16 Shorts player.
/// • App stays portrait (AndroidManifest screenOrientation="portrait").
/// • FittedBox fills screen in 9:16, YouTube controls hidden.
/// • Custom progress bar + tap-to-play/pause.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.shorts.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              unawaited(AdService.instance.onShortScrolled());
            },
            itemBuilder: (context, index) => _ShortPage(
              key: ValueKey(widget.shorts[index].id),
              video: widget.shorts[index],
              isActive: index == _currentIndex,
              autoPlayOnActivate: index != widget.initialIndex || widget.autoPlayFirst,
            ),
          ),
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
        ],
      ),
    );
  }
}

class _ShortPage extends StatefulWidget {
  final Video video;
  final bool isActive;
  final bool autoPlayOnActivate;

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

  @override
  void initState() {
    super.initState();
    final autoPlay = widget.autoPlayOnActivate && widget.isActive;
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: YoutubePlayerFlags(
        autoPlay: autoPlay,
        loop: true,
        hideControls: true,
      ),
    )..addListener(_onUpdate);
    if (autoPlay) _userStarted = true;
  }

  void _onUpdate() {
    if (!mounted) return;
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
    } else if (_ready && (widget.autoPlayOnActivate || _userStarted)) {
      _controller.play();
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
    _playing ? _controller.pause() : _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width,
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
                width: size.width,
                height: size.width * (16 / 9),
                child: YoutubePlayer(
                  controller: _controller,
                  onReady: () {
                    if (mounted) {
                      setState(() => _ready = true);
                      if (widget.isActive &&
                          (widget.autoPlayOnActivate || _userStarted)) {
                        _controller.play();
                      }
                    }
                  },
                  bufferIndicator: const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // Tap to play/pause
          GestureDetector(
            onTap: _togglePlay,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),

          // Loading / play button
          if (!_ready || (!_playing && !_userStarted))
            Center(
              child: _userStarted && !_ready
                  ? const CircularProgressIndicator(
                      color: AppTheme.gold, strokeWidth: 2.5)
                  : Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 38),
                    ),
            ),

          // Pause icon
          if (_userStarted && !_playing && _ready)
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pause_rounded,
                    color: Colors.white, size: 38),
              ),
            ),

          // Bottom gradient + title + progress
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
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4)
                          ],
                        )),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation(AppTheme.gold),
                        minHeight: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          const Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(Icons.keyboard_arrow_up_rounded,
                  color: Colors.white38, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
