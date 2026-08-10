import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'bootstrap/app_composition.dart';
import 'bootstrap/cargo_sort_app.dart';
import 'core/assets/game_image_memory_policy.dart';
import 'core/logging/app_logger.dart';
import 'core/motion/motion_lifecycle_scope.dart';
import 'core/theme/app_theme.dart';

export 'bootstrap/cargo_sort_app.dart' show CargoSortApp;

const String appVersion = '1.0.2';
const String appBuildNumber = '3';
const String appAuthor = 'Walid Atiya Ata - PMP';
const String _adsServiceName = 'mobile_ads';

Future<void> _applyImmersiveFullscreen() async {
  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } catch (error, stackTrace) {
    debugPrint('Immersive fullscreen unavailable: $error\n$stackTrace');
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GameImageMemoryPolicy.standard.configureImageCache(
    PaintingBinding.instance.imageCache,
  );
  unawaited(_applyImmersiveFullscreen());
  SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
    if (!systemOverlaysAreVisible) return;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await _applyImmersiveFullscreen();
  });
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_applyImmersiveFullscreen());
  });
  runZonedGuarded<void>(() => runApp(const BootstrapApp()), (
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('Uncaught zone error: $error\n$stackTrace');
  });
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp>
    with WidgetsBindingObserver {
  final AppComposition _composition = AppComposition.production();
  String _status = 'Preparing your cargo journey...';
  bool _ready = false;
  bool _bootstrapStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _composition.adConsent.state.addListener(_handleConsentChanged);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _composition.adConsent.state.removeListener(_handleConsentChanged);
    unawaited(_composition.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    unawaited(_applyImmersiveFullscreen());
    final consent = _composition.adConsent.state;
    if (!consent.canRequestAds) {
      if (consent.lastError != null) {
        unawaited(_refreshConsentAndInitializeAds());
      }
      return;
    }
    if (_composition.optionalServices.snapshot(_adsServiceName).canRetry) {
      unawaited(_initializeAdsInBackground(forceRetry: true));
    }
  }

  Future<void> _bootstrap() async {
    if (_bootstrapStarted) return;
    _bootstrapStarted = true;

    final minimumSplash = Future<void>.delayed(
      const Duration(milliseconds: 1300),
    );

    _setStatus('Starting secure services...');
    await _runOptionalStartupTask(
      'logger',
      () => AppErrorBoundary.install(),
      timeout: const Duration(seconds: 3),
    );

    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]).timeout(const Duration(seconds: 3)).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint(
          'Orientation configuration unavailable: $error\n$stackTrace',
        );
      }),
    );

    _setStatus('Loading player profile...');

    // Local player data is the core dependency. A slow local plugin must not
    // trap the user on the splash screen; safe defaults remain playable and
    // the original load future can complete independently.
    await Future.wait<void>([
      _runOptionalStartupTask(
        'player profile',
        () => _composition.progressStore.load(),
        timeout: const Duration(seconds: 6),
      ),
      _runOptionalStartupTask(
        'application settings',
        () => _composition.settingsStore.load(),
        timeout: const Duration(seconds: 6),
      ),
    ]);

    _setStatus('Opening the warehouse...');
    await minimumSplash;

    if (!mounted) return;
    setState(() => _ready = true);

    // Network-backed and platform services begin only after the offline core
    // experience is available. Failure is contained by the coordinator.
    unawaited(_refreshConsentAndInitializeAds());
  }

  Future<void> _runOptionalStartupTask(
    String name,
    Future<void> Function() action, {
    required Duration timeout,
  }) async {
    try {
      await action().timeout(timeout);
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('$name startup timed out; continuing: $error\n$stackTrace');
      unawaited(
        _logStartupWarning('$name startup timed out', error, stackTrace),
      );
    } catch (error, stackTrace) {
      debugPrint('$name startup failed; continuing: $error\n$stackTrace');
      unawaited(_logStartupWarning('$name startup failed', error, stackTrace));
    }
  }

  Future<void> _logStartupWarning(
    String message,
    Object error,
    StackTrace stackTrace,
  ) async {
    try {
      await AppLogger.instance.info(message, details: '$error\n$stackTrace');
    } catch (_) {
      // Logging is optional during bootstrap.
    }
  }

  void _handleConsentChanged() {
    if (!_composition.adConsent.state.canRequestAds) return;
    final snapshot = _composition.optionalServices.snapshot(_adsServiceName);
    if (snapshot.isReady) return;
    unawaited(_initializeAdsInBackground(forceRetry: snapshot.canRetry));
  }

  Future<void> _refreshConsentAndInitializeAds() async {
    final canRequestAds = await _composition.adConsent.refresh();
    if (!canRequestAds) {
      try {
        await AppLogger.instance.info(
          'Ads remain unavailable until privacy requirements permit requests.',
          details:
              '${_composition.adConsent.state.lastError ?? 'consent not granted/required state'}',
        );
      } catch (_) {
        // Privacy/ads are optional and must never block offline play.
      }
      return;
    }
    final snapshot = _composition.optionalServices.snapshot(_adsServiceName);
    await _initializeAdsInBackground(forceRetry: snapshot.canRetry);
  }

  Future<void> _initializeAdsInBackground({bool forceRetry = false}) async {
    if (!_composition.adConsent.state.canRequestAds) return;
    final initialized = forceRetry
        ? await _composition.optionalServices.retry(
            _adsServiceName,
            _initializeMobileAds,
          )
        : await _composition.optionalServices.initialize(
            _adsServiceName,
            _initializeMobileAds,
          );

    final snapshot = _composition.optionalServices.snapshot(_adsServiceName);
    if (initialized) {
      try {
        await AppLogger.instance.checkpoint('ADMOB_READY');
      } catch (_) {
        // Logging must not affect service availability.
      }
      return;
    }

    try {
      await AppLogger.instance.info(
        'Ads unavailable; offline game continues normally.',
        details: '${snapshot.lastError}',
      );
    } catch (_) {
      debugPrint('Ads unavailable: ${snapshot.lastError}');
    }
  }

  Future<void> _initializeMobileAds() async {
    await MobileAds.instance.initialize();
  }

  void _setStatus(String value) {
    if (mounted) setState(() => _status = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return CargoSortApp(
        store: _composition.progressStore,
        settings: _composition.settingsStore,
        adConsentController: _composition.adConsent,
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: MotionLifecycleScope(child: _PremiumSplash(status: _status)),
    );
  }
}

class _PremiumSplash extends StatelessWidget {
  const _PremiumSplash({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.skyGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22003366),
                        blurRadius: 28,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: AppTheme.navy,
                    size: 58,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CARGO SORT',
                  style: TextStyle(
                    color: AppTheme.navy,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
