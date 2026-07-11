import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'data/resource_category_data.dart';
import 'providers/feed_provider.dart';
import 'screens/main_shell.dart';
import 'screens/my_business_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ad_block_service.dart';
import 'services/ad_service.dart';
import 'services/background_service.dart';
import 'services/connectivity_service.dart';
import 'services/engagement_service.dart';
import 'services/iap_service.dart';
import 'services/notification_service.dart';
import 'services/user_profile_service.dart';
import 'theme/app_theme.dart';
import 'widgets/ad_block_overlay.dart';
import 'widgets/connectivity_overlay.dart';

/// Fix 1 — Splash Screen Freeze
/// main() now does the absolute minimum so runApp() fires on the first frame.
/// Heavy init (Hive, SDKs, providers) runs in parallel with the splash animation
/// inside _SplashGate. The app is never blocked before the first paint.
void main() {
  // runZonedGuarded + the two handlers below are the last line of defence
  // against a genuinely uncaught exception taking the whole app process
  // down with zero visibility into why. Framework-level errors (thrown
  // during build/layout/paint) go through FlutterError.onError; anything
  // else — a stray exception in an async callback, a Timer, a stream
  // listener outside a try/catch — is caught by the zone or by
  // PlatformDispatcher.onError. Every individual service already guards
  // itself defensively (see _safeInit below), so this is specifically the
  // net for whatever that couldn't anticipate.
  //
  // This does NOT send crash reports anywhere by itself — it only
  // prevents a hard crash and logs via debugPrint. Wire in Crashlytics,
  // Sentry, or similar here (both callbacks below) if/when you want
  // production crash analytics.
  runZonedGuarded(() async {
    // Must be the very first line — no await before this.
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('[crash] Flutter error: ${details.exceptionAsString()}');
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      debugPrint('[crash] Uncaught platform error: $error\n$stack');
      return true; // handled — do not let it crash the process
    };

    // Only orientation lock here — a fast synchronous call.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Edge-to-edge: the app draws fully behind the status bar and
    // navigation bar/gesture area, with MediaQuery padding correctly
    // reporting those insets so SafeArea/Scaffold still lay content out
    // correctly. Combined with the transparent statusBarColor set below,
    // this is what lets the Scaffold's own background colour paint all
    // the way to the physical top of the screen instead of leaving a
    // visibly different strip behind the time/signal/battery icons.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // runApp immediately — splash is shown on the very first frame.
    runApp(const FinReelsApp());
  }, (Object error, StackTrace stack) {
    debugPrint('[crash] Uncaught zone error: $error\n$stack');
  });
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
      // Wraps EVERY screen in the navigation stack — including ones with no
      // AppBar at all, like MainShell — so the status bar is always
      // transparent with correctly-contrasted icons, regardless of which
      // screen is currently showing. Screens WITH an AppBar additionally
      // get the same treatment from AppBarTheme.systemOverlayStyle; this
      // wrapper is what makes screens WITHOUT one consistent too.
      builder: (context, child) {
        final brightness = MediaQuery.platformBrightnessOf(context);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.overlayStyleFor(brightness),
          child: child ?? const SizedBox.shrink(),
        );
      },
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
    // Open Hive box for EPUB reading-progress persistence. Kept blocking —
    // it's a local-disk operation and typically resolves in single-digit ms.
    // Wrapped defensively: if Hive somehow fails (corrupted box, disk issue),
    // reading progress just won't persist — that must never be allowed to
    // strand the user on the splash screen forever.
    try {
      await Hive.initFlutter();
      await Hive.openBox<String>('reading_progress');
    } on Object catch (e) {
      debugPrint('[startup] Hive init failed (non-fatal): $e');
    }

    // ── Run every independent service init CONCURRENTLY ─────────────────────
    // Previously these 6 calls ran one after another — total wait time was
    // the SUM of each (often 2-5+ seconds combined, which is exactly why the
    // splash used to "stay long"). None of these actually depend on each
    // other (BackgroundService.init() and registerRssCheck() are the only
    // pair with a real ordering requirement, so that pair is wrapped
    // together below). Running them in parallel means the wait time becomes
    // the MAX of the group instead of the sum — typically under a second.
    //
    // Each one is also wrapped in _safeInit so that if a single service
    // throws (e.g. AdMob/IAP failing on a device with no Play Services, or
    // a network hiccup during notification-channel setup), it can NEVER
    // hang the splash screen forever or crash the app — it just logs and
    // moves on, and the app opens normally without that one feature until
    // it can be retried later.
    //
    // A hard 6-second ceiling on the WHOLE group is the final safety net:
    // even if every individual safeguard above somehow failed to return
    // (e.g. a service awaiting a Completer that's never resolved), the
    // splash will still release after 6 s rather than hanging indefinitely.
    try {
      await Future.wait([
        _safeInit('Connectivity',   () => ConnectivityService.instance.init()),
        _safeInit('Background',     _initBackgroundServices),
        _safeInit('Notifications',  () => NotificationService.instance.init()),
        _safeInit('Ads',            () => AdService.instance.init()),
        _safeInit('IAP',            () => IapService.instance.init()),
        // Both of these must finish before FeedProvider() below is
        // constructed: its session channel order reads the selected
        // category (and engagement scores) synchronously at construction time.
        _safeInit('ResourceCategories', () => ResourceCategoryData.load()),
        _safeInit('UserProfile',        () => UserProfileService.instance.init()),
        _safeInit('Engagement',         () => EngagementService.instance.init()),
      ]).timeout(const Duration(seconds: 6));
    } on TimeoutException {
      debugPrint('[startup] Service init group exceeded 6s ceiling — '
          'continuing without waiting further.');
    }
    unawaited(AdBlockService.instance.init());

    // Build the feed provider here so it can start fetching immediately.
    final provider = FeedProvider();
    unawaited(provider.init());

    if (!mounted) return;
    setState(() {
      _feedProvider = provider;
      _initDone = true;
    });
    _maybeTransition();
  }

  /// BackgroundService.registerRssCheck() depends on init() having already
  /// run, so this pair must stay sequential relative to each other — but
  /// the pair as a whole runs in parallel with everything else above.
  Future<void> _initBackgroundServices() async {
    await BackgroundService.instance.init();
    await BackgroundService.instance.registerRssCheck();
  }

  /// Runs [fn] and swallows any error. A single misbehaving service (no
  /// Play Services, a flaky network call during setup, a misconfigured SDK
  /// key, etc.) must never be able to hang the splash screen forever or
  /// crash app startup — it should just be skipped, logged, and the app
  /// should continue without that feature until it can recover later.
  Future<void> _safeInit(String name, Future<void> Function() fn) async {
    try {
      await fn();
    } on Object catch (e, st) {
      debugPrint('[startup] $name init failed (non-fatal): $e\n$st');
    }
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
          ChangeNotifierProvider.value(value: AdService.instance),
          ChangeNotifierProvider.value(value: UserProfileService.instance),
          ChangeNotifierProvider.value(value: EngagementService.instance),
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
      // A purchased ad-free window can lapse while the app sits in the
      // background — recheck against the wall clock on every resume so
      // ads correctly resume the moment it expires, not only on a full
      // app restart.
      unawaited(AdService.instance.refreshStatus());
      unawaited(AdService.instance.showAppOpenAd());
      // Forces a true network refresh (replacing each channel's cached 15
      // with whatever is genuinely latest on YouTube right now) — but only
      // if it's been a few minutes since the last one, to avoid hammering
      // the RSS endpoint on rapid app-switching.
      unawaited(context.read<FeedProvider>().refreshOnResume());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!UserProfileService.instance.onboardingComplete) {
      return MyBusinessScreen(
        isOnboarding: true,
        // onboardingComplete flips inside MyBusinessScreen._save() before
        // this fires, so the rebuild below reliably picks the MainShell
        // branch instead of looping back into onboarding.
        onDone: () => setState(() {}),
      );
    }
    return const MainShell();
  }
}
