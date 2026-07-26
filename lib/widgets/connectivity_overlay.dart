import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';

/// Wraps the entire app. When network drops to [NetworkStatus.noNetwork] or
/// [NetworkStatus.noInternet], a compact banner slides down from the top of
/// the screen — content below is still fully visible and interactive, unlike
/// the previous full-screen block.
///
/// The [NetworkStatus.checking] state intentionally shows nothing: the check
/// completes in well under a second on a working connection, so a flash of
/// UI would look like a bug rather than information.
///
/// [AdBlockOverlay] (which wraps the inner app) is a separate widget and is
/// deliberately NOT changed here — ad-blocker detection still blocks the
/// whole screen, as that is an intentional enforcement screen.
class ConnectivityOverlay extends StatefulWidget {
  final Widget child;
  const ConnectivityOverlay({required this.child, super.key});

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay> {
  NetworkStatus _status = NetworkStatus.checking;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _status = ConnectivityService.instance.current;
    ConnectivityService.instance.statusStream.listen((s) {
      if (mounted) setState(() => _status = s);
    });
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await ConnectivityService.instance.retry();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    // 'checking' is silent — see class doc comment above.
    final showBanner = _status == NetworkStatus.noNetwork ||
        _status == NetworkStatus.noInternet;

    return Stack(
      children: [
        // App content is ALWAYS rendered and interactive behind the banner.
        widget.child,

        if (showBanner)
          // Positioned at the top of the screen only — does not intercept
          // taps outside its own footprint, so scrolling/navigation below
          // continues to work normally while the connection is down.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _NetworkBanner(
                  status: _status,
                  retrying: _retrying,
                  onRetry: _retry,
                ),
              ),
            ),
          )
              .animate()
              .slideY(
                begin: -1.2,
                end: 0,
                duration: 320.ms,
                curve: Curves.easeOutCubic,
              )
              .fadeIn(duration: 200.ms),
      ],
    );
  }
}

// ── Compact banner card ─────────────────────────────────────────────────────

class _NetworkBanner extends StatelessWidget {
  final NetworkStatus status;
  final bool retrying;
  final VoidCallback onRetry;

  const _NetworkBanner({
    required this.status,
    required this.retrying,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          // Slightly opaque surface so content shows through at edges.
          color: AppTheme.bgColor(context).withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.gold.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(child: _buildText(context)),
            const SizedBox(width: 10),
            _buildRetryButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final icon = status == NetworkStatus.noNetwork
        ? Icons.wifi_off_rounded
        : Icons.signal_wifi_statusbar_connected_no_internet_4_rounded;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Icon(icon, color: AppTheme.gold, size: 20),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 2.seconds,
          color: AppTheme.gold.withValues(alpha: 0.25),
        );
  }

  Widget _buildText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor(context),
                height: 1.2,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          _subtitle,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary(context),
                height: 1.3,
              ),
        ),
      ],
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return GestureDetector(
      onTap: retrying ? null : onRetry,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: retrying
              ? AppTheme.gold.withValues(alpha: 0.5)
              : AppTheme.gold,
          borderRadius: BorderRadius.circular(20),
        ),
        child: retrying
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }

  String get _title => status == NetworkStatus.noNetwork
      ? 'No Network'
      : 'No Internet Access';

  String get _subtitle => status == NetworkStatus.noNetwork
      ? 'Check your Wi-Fi or mobile data'
      : 'Connected but no data — check your plan';
}
