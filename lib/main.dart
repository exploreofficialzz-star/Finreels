import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await ConnectivityService.instance.init();
  await BackgroundService.instance.init();
  await BackgroundService.instance.registerRssCheck();
  await NotificationService.instance.init();
  await AdService.instance.init();
  await IapService.instance.init();
  unawaited(AdBlockService.instance.init());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FeedProvider()..init()),
        ChangeNotifierProvider.value(value: IapService.instance),
      ],
      child: const FinReelsApp(),
    ),
  );
}

class FinReelsApp extends StatefulWidget {
  const FinReelsApp({super.key});

  @override
  State<FinReelsApp> createState() => _FinReelsAppState();
}

class _FinReelsAppState extends State<FinReelsApp> with WidgetsBindingObserver {
  bool _showSplash = true;

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinReels',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: _showSplash
          ? SplashScreen(
              onComplete: () {
                setState(() => _showSplash = false);
                unawaited(NotificationService.instance.requestPermission());
              },
            )
          : const ConnectivityOverlay(
              child: AdBlockOverlay(
                child: MainShell(),
              ),
            ),
    );
  }
}
