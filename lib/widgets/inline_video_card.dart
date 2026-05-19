import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/channel.dart';
import '../models/video.dart';
import '../theme/app_theme.dart';

/// Feed card — NO auto-play.
/// The player only initialises and plays when the user explicitly taps
/// the thumbnail. VisibilityDetector is removed entirely.
///
/// Play/pause between cards is coordinated via [activeVideoNotifier]:
/// when this card becomes active, other cards pause — without triggering
/// a parent setState (no scroll interference).
class InlineVideoCard extends StatefulWidget {
  final Video video;
  final Channel channel;
  final bool saved;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  /// Shared ValueNotifier across all feed cards.
  /// Setting it to this card's ID pauses all others.
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
  bool _expanded = false; // true once user taps play

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

  /// Fires when another card becomes active — pause without setState on parent.
  void _onActiveChanged() {
    if (!mounted || _controller == null) return;
    if (_isActive && _playerReady) {
      _controller!.play();
    } else if (!_isActive) {
      _controller!.pause();
    }
  }

  /// Called only when user explicitly taps the thumbnail.
  void _onUserTap() {
    if (_controller == null) {
      // First tap: create controller. autoPlay = false; user already tapped.
      _controller = YoutubePlayerController(
        initialVideoId: widget.video.id,
        flags: const YoutubePlayerFlags(
          autoPlay: true, // play immediately after user's deliberate tap
          enableCaption: false,
          hideControls: false,
        ),
      )..addListener(_onControllerUpdate);
      setState(() => _expanded = true);
      updateKeepAlive();
    }
    // Signal all other cards to pause — no parent rebuild.
    widget.activeVideoNotifier.value = widget.video.id;
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final ready = _controller?.value.isReady ?? false;
    if (ready != _playerReady) {
      setState(() => _playerReady = ready);
      if (ready && _isActive) _controller?.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppTheme.dividerColor(context), width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Player or Thumbnail ──────────────────────────────────────
            _expanded && _controller != null
                ? _buildPlayer()
                : _buildThumbnail(context),

            // Channel accent strip
            Container(height: 3, color: widget.channel.accentColor),

            // ── Info ─────────────────────────────────────────────────────
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
                color: AppTheme.gold, strokeWidth: 2.5),
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
        onTap: _onUserTap, // user must tap — no auto-play
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
            // Play button overlay — clear affordance that tap is required
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 34),
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
