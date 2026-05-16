import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
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
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initController();
    // Fire interstitial aggressively on every video open
    unawaited(AdService.instance.onVideoOpened());
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            // Keep user inside the app — only allow YouTube embed domain
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            final host = uri.host;
            final allowed = host.contains('youtube.com') ||
                host.contains('youtu.be') ||
                host.contains('ytimg.com') ||
                host.contains('googlevideo.com') ||
                host.contains('ggpht.com') ||
                host.isEmpty;
            return allowed
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(_buildPlayerHtml());
  }

  String _buildPlayerHtml() {
    final id = widget.video.id;
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #000; width: 100vw; height: 100vh; overflow: hidden; }
    .wrapper {
      position: relative; width: 100%; height: 100%;
      display: flex; align-items: center; justify-content: center;
    }
    iframe {
      width: 100%; height: 100%;
      border: none; display: block;
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <iframe
      src="https://www.youtube.com/embed/$id?autoplay=1&rel=0&modestbranding=1&playsinline=1&enablejsapi=1"
      allow="autoplay; fullscreen; encrypted-media"
      allowfullscreen>
    </iframe>
  </div>
</body>
</html>''';
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
        title: Text(
          widget.channel.name,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share(
              '${widget.video.title}\n\nWatch: ${widget.video.watchUrl}',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen_rounded),
            onPressed: _toggleFullscreen,
          ),
        ],
      ),
      body: Column(
        children: [
          // Player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.gold),
                    ),
                  ),
              ],
            ),
          ),

          // Channel accent strip
          Container(height: 3, color: widget.channel.accentColor),

          // Video info
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color:
                              widget.channel.accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.channel.accentColor.withValues(
                                alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            widget.channel.initials,
                            style: TextStyle(
                              color: widget.channel.accentColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.channel.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              widget.channel.focus,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.video.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'About this video',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppTheme.gold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.video.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Space for floating nav
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Banner ad at bottom
          if (!AdService.instance.adsRemoved) const LabelledBannerAd(),
        ],
      ),
    );
  }

  Widget _buildFullscreenPlayer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.gold),
            ),
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
