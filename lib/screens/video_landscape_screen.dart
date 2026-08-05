import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../theme/app_theme.dart';

/// Dedicated landscape-only player for a single video.
///
/// Pushed from [VideoPlayerScreen] when the user taps fullscreen. Only this
/// route is locked to landscape — the rest of the app stays portrait.
/// Returns the playback position (Duration) via [Navigator.pop] so the
/// portrait player can resume at the same place.
class VideoLandscapeScreen extends StatefulWidget {
  final String videoId;
  final Duration startAt;

  const VideoLandscapeScreen({
    required this.videoId,
    this.startAt = Duration.zero,
    super.key,
  });

  @override
  State<VideoLandscapeScreen> createState() => _VideoLandscapeScreenState();
}

class _VideoLandscapeScreenState extends State<VideoLandscapeScreen> {
  late YoutubePlayerController _controller;
  bool _playing = true;
  bool _showIcon = false;
  int _tapCount = 0;
  Timer? _iconTimer;
  final ValueNotifier<double> _progress = ValueNotifier(0);
  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _duration = ValueNotifier(Duration.zero);
  int _lastMs = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true,
        enableCaption: false,
        startAt: widget.startAt.inSeconds,
      ),
    )..addListener(_onUpdate);
  }

  void _onUpdate() {
    if (!mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastMs < 33) return;
    _lastMs = now;
    final v = _controller.value;
    final dur = v.metaData.duration;
    final pos = v.position;
    _position.value = pos;
    _duration.value = dur;
    _progress.value = dur.inMilliseconds > 0
        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final playing = v.playerState == PlayerState.playing;
    if (playing != _playing) setState(() => _playing = playing);
  }

  @override
  void dispose() {
    _iconTimer?.cancel();
    _progress.dispose();
    _position.dispose();
    _duration.dispose();
    _controller
      ..removeListener(_onUpdate)
      ..dispose();
    // Restore portrait for the rest of the app.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _pop() {
    Navigator.pop(context, _controller.value.position);
  }

  void _toggle() {
    if (_playing) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {
      _playing = !_playing;
      _tapCount++;
      _showIcon = true;
    });
    _iconTimer?.cancel();
    _iconTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showIcon = false);
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? "${d.inHours}:" : ""}$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: YoutubePlayer(
              controller: _controller,
              onReady: () {
                if (widget.startAt > Duration.zero) {
                  _controller.seekTo(widget.startAt);
                }
                _controller.play();
              },
              bufferIndicator: const SizedBox.shrink(),
            ),
          ),

          // FinReels watermark covering the YouTube logo (bottom-right).
          const Positioned(
            right: 12,
            bottom: 48,
            child: _FinReelsWatermark(),
          ),

          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: const SizedBox.expand(),
          ),

          if (_showIcon)
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
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _playing
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              ),
            ),

          if (!_playing && !_showIcon)
            Center(
              child: IgnorePointer(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 44),
                ),
              ),
            ),

          // Top bar: back + exit fullscreen
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 8,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 28),
                  onPressed: _pop,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.fullscreen_exit_rounded,
                      color: Colors.white, size: 28),
                  onPressed: _pop,
                ),
              ],
            ),
          ),

          // Bottom progress
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            child: ValueListenableBuilder<double>(
              valueListenable: _progress,
              builder: (_, prog, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.5,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: AppTheme.gold,
                      inactiveTrackColor: Colors.white30,
                      thumbColor: AppTheme.gold,
                    ),
                    child: Slider(
                      value: prog.clamp(0.0, 1.0),
                      onChanged: (f) {
                        final dur = _duration.value;
                        if (dur.inMilliseconds > 0) {
                          _controller.seekTo(Duration(
                              milliseconds:
                                  (f * dur.inMilliseconds).round()));
                        }
                      },
                    ),
                  ),
                  ValueListenableBuilder<Duration>(
                    valueListenable: _position,
                    builder: (_, pos, __) => ValueListenableBuilder<Duration>(
                      valueListenable: _duration,
                      builder: (_, dur, __) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${_fmt(pos)} / ${_fmt(dur)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinReelsWatermark extends StatelessWidget {
  const _FinReelsWatermark();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppTheme.gold.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
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
          const SizedBox(width: 5),
          const Text(
            'FinReels',
            style: TextStyle(
              color: AppTheme.gold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
