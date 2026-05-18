import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'providers/feed_provider.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'services/ad_block_service.dart';
import 'services/ad_service.dart';
import 'services/background_service.dart';
import 'services/connectivity_service.dart';
import 'services/iap_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/ad_block_overlay.dart';
import 'widgets/connectivity_overlay.dart';

/// Fix 1 — Splash Screen Freeze
/// main() now does the absolute minimum so runApp() fires on the first frame.
/// Heavy init (Hive, SDKs, providers) runs in parallel with the splash animation
/// inside _SplashGate. The app is never blocked before the first paint.
void main() async {
  // Must be the very first line — no await before this.
  WidgetsFlutterBinding.ensureInitialized();

  // Only orientation lock here — a fast synchronous call.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // runApp immediately — splash is shown on the very first frame.
  runApp(const FinReelsApp());
}

class FinReelsApp extends StatelessWidget {
  const FinReelsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinReels',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const _SplashGate(),
    );
  }
}

/// Splash is displayed immediately. Heavy init runs in the background.
/// The main shell is shown only after BOTH the splash timer AND init are done.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _splashDone = false;
  bool _initDone = false;

  // Holds fully-initialised providers, set after init completes.
  FeedProvider? _feedProvider;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget — runs concurrently with the splash animation.
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    // Open Hive box for EPUB reading-progress persistence.
    await Hive.initFlutter();
    await Hive.openBox<String>('reading_progress');

    // Boot services in dependency order — all heavyweight work is here,
    // NOT in main(), so the splash is already visible before any of this runs.
    await ConnectivityService.instance.init();
    await BackgroundService.instance.init();
    await BackgroundService.instance.registerRssCheck();
    await NotificationService.instance.init();
    await AdService.instance.init();
    await IapService.instance.init();
    unawaited(AdBlockService.instance.init());

    // Build the feed provider here so it can start fetching immediately.
    final provider = FeedProvider()..init();

    if (!mounted) return;
    setState(() {
      _feedProvider = provider;
      _initDone = true;
    });
    _maybeTransition();
  }

  void _onSplashComplete() {
    _splashDone = true;
    unawaited(NotificationService.instance.requestPermission());
    _maybeTransition();
  }

  /// Transitions to the shell only when both conditions are met.
  void _maybeTransition() {
    if (_splashDone && _initDone && mounted) {
      setState(() {}); // Triggers the build that shows the shell.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show shell only when splash is done AND init is done.
    if (_splashDone && _initDone && _feedProvider != null) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _feedProvider!),
          ChangeNotifierProvider.value(value: IapService.instance),
        ],
        child: const ConnectivityOverlay(
          child: AdBlockOverlay(child: _AppRoot()),
        ),
      );
    }

    // Splash is shown immediately and holds until both flags are true.
    return SplashScreen(onComplete: _onSplashComplete);
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(AdService.instance.showAppOpenAd());
      unawaited(context.read<FeedProvider>().refresh());
    }
  }

  @override
  Widget build(BuildContext context) => const MainShell();
}
