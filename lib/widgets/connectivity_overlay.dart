import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';

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
    final showOverlay = _status == NetworkStatus.noNetwork ||
        _status == NetworkStatus.noInternet ||
        _status == NetworkStatus.checking;

    return Stack(
      children: [
        widget.child,
        if (showOverlay)
          _OverlaySheet(
            status: _status,
            retrying: _retrying,
            onRetry: _retry,
          ).animate().fadeIn(duration: 250.ms),
      ],
    );
  }
}

class _OverlaySheet extends StatelessWidget {
  final NetworkStatus status;
  final bool retrying;
  final VoidCallback onRetry;

  const _OverlaySheet({
    required this.status,
    required this.retrying,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;

    return Material(
      color: bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildIcon(),
              const SizedBox(height: 32),
              Text(
                _title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (status != NetworkStatus.checking) _buildRetryButton(context),
              const Spacer(),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (status == NetworkStatus.checking) {
      return const SizedBox(
        width: 80,
        height: 80,
        child: CircularProgressIndicator(
          color: AppTheme.gold,
          strokeWidth: 3,
        ),
      );
    }

    final icon = status == NetworkStatus.noNetwork
        ? Icons.wifi_off_rounded
        : Icons.signal_wifi_statusbar_connected_no_internet_4_rounded;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Icon(icon, size: 48, color: AppTheme.gold),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 2.seconds, color: AppTheme.gold.withValues(alpha: 0.2));
  }

  Widget _buildRetryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: retrying ? null : onRetry,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.gold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: retrying
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.black, strokeWidth: 2.5),
              )
            : const Text('Try Again',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Text(
      'FinReels by chAs Tech Group',
      style: Theme.of(context).textTheme.labelSmall,
      textAlign: TextAlign.center,
    );
  }

  String get _title {
    switch (status) {
      case NetworkStatus.checking:
        return 'Connecting…';
      case NetworkStatus.noNetwork:
        return 'No Network';
      case NetworkStatus.noInternet:
        return 'No Internet Access';
      default:
        return 'Checking…';
    }
  }

  String get _subtitle {
    switch (status) {
      case NetworkStatus.checking:
        return 'Checking your connection…';
      case NetworkStatus.noNetwork:
        return 'Your device is not connected to any network.\n\nCheck your Wi-Fi or mobile data and try again.';
      case NetworkStatus.noInternet:
        return 'Your device is connected to a network but cannot reach the internet.\n\nCheck your Wi-Fi or mobile data plan and try again.';
      default:
        return '';
    }
  }
}
