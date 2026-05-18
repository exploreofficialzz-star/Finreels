import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/video.dart';
import '../theme/app_theme.dart';

/// Full-screen vertical Shorts player — exact YouTube Shorts UX.
/// PageView.builder snaps between shorts on vertical swipe.
/// Each page owns its YoutubePlayerController, disposed on page exit.
class ShortsPlayerScreen extends StatefulWidget {
  final List<Video> shorts;
  final int initialIndex;

  const ShortsPlayerScreen({
    required this.shorts,
    required this.initialIndex,
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

    // Force landscape unlock for the player, then relock on exit
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
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
            },
            itemBuilder: (context, index) {
              return _ShortPage(
                video: widget.shorts[index],
                isActive: index == _currentIndex,
              );
            },
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// One page in the shorts PageView. Owns its YoutubePlayerController.
class _ShortPage extends StatefulWidget {
  final Video video;
  final bool isActive;

  const _ShortPage({required this.video, required this.isActive});

  @override
  State<_ShortPage> createState() => _ShortPageState();
}

class _ShortPageState extends State<_ShortPage> {
  late YoutubePlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: YoutubePlayerFlags(
        autoPlay: widget.isActive,
        loop: true,
        controlsVisibleAtStart: false,
        enableCaption: false,
      ),
    )..addListener(_onUpdate);
  }

  void _onUpdate() {
    if (!mounted) return;
    if (_controller.value.isReady != _ready) {
      setState(() => _ready = _controller.value.isReady);
    }
  }

  @override
  void didUpdateWidget(_ShortPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && _ready) {
      _controller.play();
    } else if (!widget.isActive) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onUpdate)
      ..dispose();
    super.dispose();
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
          // Black background
          const ColoredBox(color: Colors.black),

          // YouTube player centered
          Center(
            child: YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: AppTheme.gold,
                progressColors: const ProgressBarColors(
                  playedColor: AppTheme.gold,
                  handleColor: AppTheme.gold,
                ),
                onReady: () {
                  if (mounted) {
                    setState(() => _ready = true);
                    if (widget.isActive) _controller.play();
                  }
                },
                bufferIndicator: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.gold,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              builder: (_, player) => player,
            ),
          ),

          // Bottom gradient + title overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
              child: Text(
                widget.video.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
            ),
          ),

          // Swipe hint arrow at bottom
          const Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(Icons.keyboard_arrow_up_rounded,
                  color: Colors.white54, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
