import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/channel.dart';
import '../models/video.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';

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
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _embedFailed = false;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initController();
    unawaited(AdService.instance.onVideoOpened());
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (msg) {
          if (msg.message == 'embed_error') {
            if (mounted) setState(() => _embedFailed = true);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            // non-fatal resource errors are common in YouTube embed — ignore
          },
          onNavigationRequest: (req) {
            final uri = Uri.tryParse(req.url);
            if (uri == null) return NavigationDecision.prevent;
            final h = uri.host;
            final allowed = h.contains('youtube.com') ||
                h.contains('youtube-nocookie.com') ||
                h.contains('youtu.be') ||
                h.contains('ytimg.com') ||
                h.contains('googlevideo.com') ||
                h.contains('ggpht.com') ||
                h.isEmpty;
            return allowed
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(_buildHtml());
  }

  // Uses youtube-nocookie.com to bypass most embedding restrictions.
  // JS bridge detects Error 150/153 and notifies Flutter.
  String _buildHtml() {
    final id = widget.video.id;
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    body{background:#000;overflow:hidden;width:100vw;height:100vh}
    iframe{width:100%;height:100%;border:none;display:block}
  </style>
</head>
<body>
<iframe id="yt"
  src="https://www.youtube-nocookie.com/embed/$id?autoplay=1&rel=0&modestbranding=1&playsinline=1&enablejsapi=1&origin=https://www.youtube-nocookie.com"
  allow="autoplay;fullscreen;encrypted-media"
  allowfullscreen>
</iframe>
<script>
  var player;
  function onYouTubeIframeAPIReady(){
    player=new YT.Player('yt',{
      events:{
        onError:function(e){
          // Error codes 100,101,150,153 = embedding not allowed
          if([100,101,150,153].indexOf(e.data)>=0){
            FlutterBridge.postMessage('embed_error');
          }
        }
      }
    });
  }
</script>
<script src="https://www.youtube.com/iframe_api"></script>
</body>
</html>''';
  }

  Future<void> _openInYouTube() async {
    // Try YouTube app first, fall back to browser
    final appUri = Uri.parse('vnd.youtube:${widget.video.id}');
    final webUri = Uri.parse(widget.video.watchUrl);
    if (await canLaunchUrl(appUri)) {
      unawaited(launchUrl(appUri));
    } else {
      unawaited(launchUrl(webUri, mode: LaunchMode.externalApplication));
    }
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) return _buildFullscreenPlayer();

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        title: Text(widget.channel.name,
            style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open in YouTube',
            onPressed: _openInYouTube,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share(
                '${widget.video.title}\n${widget.video.watchUrl}'),
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen_rounded),
            onPressed: _toggleFullscreen,
          ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading && !_embedFailed)
                  const ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.gold),
                    ),
                  ),
                // Embed-blocked fallback overlay
                if (_embedFailed) _buildEmbedFallback(),
              ],
            ),
          ),
          Container(height: 3, color: widget.channel.accentColor),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  _ChannelRow(channel: widget.channel),
                  if (widget.video.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text('About this video',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: AppTheme.gold)),
                    const SizedBox(height: 8),
                    Text(
                      widget.video.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!AdService.instance.adsRemoved) const LabelledBannerAd(),
        ],
      ),
    );
  }

  Widget _buildEmbedFallback() {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_outline_rounded,
                  color: AppTheme.gold, size: 56),
              const SizedBox(height: 16),
              const Text(
                'This video can\'t be embedded',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'The creator has disabled in-app playback.\nTap below to watch on YouTube.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _openInYouTube,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Watch on YouTube'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenPlayer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_embedFailed) _buildEmbedFallback(),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.fullscreen_exit_rounded,
                  color: Colors.white, size: 32),
              onPressed: _toggleFullscreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final Channel channel;
  const _ChannelRow({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: channel.accentColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
                color: channel.accentColor.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(channel.initials,
                style: TextStyle(
                    color: channel.accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(channel.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(channel.focus,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
