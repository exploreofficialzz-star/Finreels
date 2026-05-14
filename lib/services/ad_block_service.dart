import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'connectivity_service.dart';

enum AdBlockStatus {
  checking,
  clear, // ads not blocked
  blocked, // ad-block detected
}

class AdBlockService {
  AdBlockService._();
  static final AdBlockService instance = AdBlockService._();

  final _statusController = StreamController<AdBlockStatus>.broadcast();
  Stream<AdBlockStatus> get statusStream => _statusController.stream;

  AdBlockStatus _current = AdBlockStatus.checking;
  AdBlockStatus get current => _current;

  bool _disposed = false;

  Future<void> init() async {
    // Only check if internet is actually available
    ConnectivityService.instance.statusStream.listen((netStatus) async {
      if (netStatus == NetworkStatus.online) {
        await runCheck();
      } else if (netStatus == NetworkStatus.noNetwork ||
          netStatus == NetworkStatus.noInternet) {
        // Can't check ads without internet; reset to checking
        _emit(AdBlockStatus.checking);
      }
    });

    if (ConnectivityService.instance.current == NetworkStatus.online) {
      await runCheck();
    }
  }

  /// Probe multiple ad-server endpoints.
  /// Strategy:
  ///   1. Internet is confirmed reachable (ConnectivityService said online).
  ///   2. Try each ad endpoint with a short timeout.
  ///   3. If ≥2 ad endpoints fail → ad-block detected.
  ///   4. If ≤1 fails → clear (could be normal CDN blip).
  Future<void> runCheck() async {
    if (_disposed) return;
    _emit(AdBlockStatus.checking);

    var failCount = 0;

    final futures = AppConfig.adCheckEndpoints.map((url) async {
      try {
        final response = await http
            .get(Uri.parse(url), headers: {
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'User-Agent':
                  'Mozilla/5.0 (compatible; FinReels/1.0; +com.chastech.finreels)',
            })
            .timeout(const Duration(seconds: 6));

        // A 4xx/5xx could mean server-side block, but 200-3xx means reachable
        if (response.statusCode < 200 || response.statusCode >= 400) {
          failCount++;
        }
      } on Exception catch (_) {
        // Network-level block (DNS blocked, connection refused, timeout)
        failCount++;
      }
    });

    await Future.wait(futures);

    // Need ≥2 failures out of 4 endpoints to flag as blocked
    // (tolerates occasional CDN hiccup)
    final isBlocked = failCount >= 2;
    _emit(isBlocked ? AdBlockStatus.blocked : AdBlockStatus.clear);
  }

  void _emit(AdBlockStatus status) {
    if (_disposed) return;
    if (status != _current) {
      _current = status;
      _statusController.add(status);
    }
  }

  void dispose() {
    _disposed = true;
    _statusController.close();
  }
}
