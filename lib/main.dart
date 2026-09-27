import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:overlay_support/overlay_support.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/analytics/firebase_analytics_service.dart';
import 'package:rewardhub/core/bindings/initial_binding.dart';
import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/routes/app_pages.dart';
import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/services/connectivity_service.dart';
import 'package:rewardhub/core/services/push_notification_service.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/theme/app_theme.dart';
import 'package:rewardhub/core/utils/alice_service.dart';
import 'package:rewardhub/core/widgets/connectivity_widget.dart';
import 'package:rewardhub/firebase_options.dart';
import 'package:rewardhub/l10n/app_localizations.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  ConnectivityService();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Built here rather than in InitialBinding because it needs Firebase to be
  // initialised, and because GetMaterialApp needs its navigator observer at
  // construction time — before any binding has run.
  final analyticsService = FirebaseAnalyticsService();
  await analyticsService.setCollectionEnabled(analyticsEnabled);

  final remoteConfigService = RemoteConfigService();
  await remoteConfigService.initialize();

  final pushNotificationService = PushNotificationService();
  await pushNotificationService.initialize();

  runApp(
    RewardHubApp(
      analyticsService: analyticsService,
      analytics: AppAnalytics(analyticsService),
      remoteConfigService: remoteConfigService,
      pushNotificationService: pushNotificationService,
    ),
  );
}

class RewardHubApp extends StatelessWidget {
  const RewardHubApp({
    super.key,
    required this.analyticsService,
    required this.analytics,
    this.remoteConfigService,
    this.pushNotificationService,
  });

  /// Supplies the `screen_view` navigator observer.
  final FirebaseAnalyticsService analyticsService;

  /// The typed event facade handed to every controller via [InitialBinding].
  final AppAnalytics analytics;

  /// The initialized remote config service.
  final RemoteConfigService? remoteConfigService;

  /// The initialized push notification service.
  final PushNotificationService? pushNotificationService;

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: GetMaterialApp(
        title: AppStrings.productName,
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        initialBinding: InitialBinding(
          analytics: analytics,
          remoteConfigService: remoteConfigService,
          pushNotificationService: pushNotificationService,
        ),
        initialRoute: AppRoutes.splash,
        // Reports a `screen_view` for every named route. Tab switches inside
        // the shell push no route, so ShellController logs those itself.
        navigatorObservers: [analyticsService.navigatorObserver],
        // Null outside debug builds with `--dart-define=alice`, so the
        // inspector's navigator (and its shake handler) never ships.
        navigatorKey: aliceRef?.getNavigatorKey(),
        getPages: AppPages.pages,
        // Offline / slow-connection banner above every route.
        builder: (context, child) =>
            ConnectivityWidget(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
