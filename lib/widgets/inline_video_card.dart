import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:visibility_detector/visibility_detector.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/channel.dart';
import '../models/video.dart';
import '../theme/app_theme.dart';

/// Callback so the feed can enforce single-video playback.
typedef OnBecomeVisible = void Function(String videoId);

/// Feed card that plays YouTube video inline when >50% visible.
/// Only one card plays at a time — managed by [activeVideoId] from parent.
class InlineVideoCard extends StatefulWidget {
  final Video video;
  final Channel channel;
  final bool saved;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final String? activeVideoId;
  final OnBecomeVisible onBecomeVisible;

  const InlineVideoCard({
    required this.video,
    required this.channel,
    required this.onBecomeVisible,
    super.key,
    this.saved = false,
    this.onSave,
    this.onShare,
    this.activeVideoId,
  });

  @override
  State<InlineVideoCard> createState() => _InlineVideoCardState();
}

class _InlineVideoCardState extends State<InlineVideoCard> {
  YoutubePlayerController? _controller;
  bool _playerReady = false;
  bool _expanded = false; // true once user or auto-play opens the player

  bool get _isActive => widget.activeVideoId == widget.video.id;

  @override
  void didUpdateWidget(InlineVideoCard old) {
    super.didUpdateWidget(old);
    // Pause when another card becomes active
    if (!_isActive && _controller != null) {
      _controller!.pause();
    } else if (_isActive && _controller != null && _playerReady) {
      _controller!.play();
    }
  }

  void _initController() {
    if (_controller != null) return;
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: YoutubePlayerFlags(
        autoPlay: _isActive,
        mute: false,
        enableCaption: false,
        hideControls: false,
        controlsVisibleAtStart: true,
        forceHD: false,
      ),
    )..addListener(_onUpdate);
    setState(() => _expanded = true);
  }

  void _onUpdate() {
    if (!mounted) return;
    final ready = _controller?.value.isReady ?? false;
    if (ready != _playerReady) {
      setState(() => _playerReady = ready);
      if (ready && _isActive) _controller?.play();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('inline_${widget.video.id}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        if (info.visibleFraction >= 0.5) {
          // Auto-expand and signal parent to make this the active video
          _initController();
          widget.onBecomeVisible(widget.video.id);
        } else {
          // Scrolled away — pause
          _controller?.pause();
        }
      },
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppTheme.dividerColor(context), width: 0.5),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Player or Thumbnail ────────────────────────────────────
              _expanded && _controller != null
                  ? _buildPlayer()
                  : _buildThumbnail(context),

              // Channel accent strip
              Container(height: 3, color: widget.channel.accentColor),

              // ── Info row ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(height: 1.35, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: widget.channel.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.channel.name,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '· ${timeago.format(widget.video.publishedAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (widget.onSave != null || widget.onShare != null) ...[
                          const SizedBox(width: 4),
                          _actionMenu(context),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return YoutubePlayerBuilder(
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
        bufferIndicator: const SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: AppTheme.gold,
              strokeWidth: 2.5,
            ),
          ),
        ),
      ),
      builder: (_, player) => player,
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: () {
          _initController();
          widget.onBecomeVisible(widget.video.id);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.video.thumbnailHd,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => CachedNetworkImage(
                imageUrl: widget.video.thumbnailMq,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => ColoredBox(
                  color: AppTheme.surfaceElevated(context),
                  child: Icon(Icons.play_circle_outline_rounded,
                      color: AppTheme.textMuted(context), size: 36),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
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
                  size: 18,
                  color: AppTheme.gold),
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
        if (v == 'save') widget.onSave?.call();
        if (v == 'share') widget.onShare?.call();
      },
    );
  }
}
