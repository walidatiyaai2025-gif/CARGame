import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/logging/app_logger.dart';
import 'core/logging/log_viewer_screen.dart';
import 'core/motion/motion_lifecycle_scope.dart';
import 'core/services/optional_service_coordinator.dart';
import 'core/settings/app_settings_store.dart';
import 'core/storage/progress_store.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';
import 'l10n/app_localizations.dart';

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
  final ProgressStore _store = ProgressStore();
  final AppSettingsStore _settings = AppSettingsStore();
  final OptionalServiceCoordinator _optionalServices =
      OptionalServiceCoordinator(
        defaultTimeout: const Duration(seconds: 20),
        maxAttempts: 3,
      );
  String _status = 'Preparing your cargo journey...';
  bool _ready = false;
  bool _bootstrapStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_optionalServices.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    unawaited(_applyImmersiveFullscreen());
    if (_optionalServices.snapshot(_adsServiceName).canRetry) {
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
        () => _store.load(),
        timeout: const Duration(seconds: 6),
      ),
      _runOptionalStartupTask(
        'application settings',
        () => _settings.load(),
        timeout: const Duration(seconds: 6),
      ),
    ]);

    _setStatus('Opening the warehouse...');
    await minimumSplash;

    if (!mounted) return;
    setState(() => _ready = true);

    // Network-backed and platform services begin only after the offline core
    // experience is available. Failure is contained by the coordinator.
    unawaited(_initializeAdsInBackground());
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

  Future<void> _initializeAdsInBackground({bool forceRetry = false}) async {
    final initialized = forceRetry
        ? await _optionalServices.retry(_adsServiceName, _initializeMobileAds)
        : await _optionalServices.initialize(
            _adsServiceName,
            _initializeMobileAds,
          );

    final snapshot = _optionalServices.snapshot(_adsServiceName);
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
      return CargoSortApp(store: _store, settings: _settings);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: MotionLifecycleScope(child: _PremiumSplash(status: _status)),
    );
  }
}

class _PremiumSplash extends StatefulWidget {
  const _PremiumSplash({required this.status});
  final String status;

  @override
  State<_PremiumSplash> createState() => _PremiumSplashState();
}

class _PremiumSplashState extends State<_PremiumSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: .96,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF102C4C), Color(0xFF255B88), Color(0xFF112A45)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: -70,
                right: -55,
                child: _GlowOrb(size: 210),
              ),
              const Positioned(
                bottom: -90,
                left: -70,
                child: _GlowOrb(size: 250),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _scale,
                        child: Container(
                          width: 146,
                          height: 146,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(42),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFC447), Color(0xFFFF8A1F)],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66FF9F1C),
                                blurRadius: 34,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: const Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.warehouse_rounded,
                                size: 88,
                                color: Colors.white,
                              ),
                              Positioned(
                                right: 18,
                                bottom: 18,
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  size: 42,
                                  color: AppTheme.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'CARGO SORT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'SORT • SHIP • CONQUER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.yellow,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.4,
                        ),
                      ),
                      const SizedBox(height: 34),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: const LinearProgressIndicator(
                          minHeight: 9,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.yellow,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          widget.status,
                          key: ValueKey(widget.status),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Version $appVersion ($appBuildNumber)',
                        style: TextStyle(
                          color: Colors.white60,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        appAuthor,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: .055),
    ),
  );
}

class CargoSortApp extends StatefulWidget {
  const CargoSortApp({super.key, required this.store, required this.settings});

  final ProgressStore store;
  final AppSettingsStore settings;

  @override
  State<CargoSortApp> createState() => _CargoSortAppState();
}

class _CargoSortAppState extends State<CargoSortApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppLogger _logger = AppLogger.instance;
  Locale _locale = const Locale('en');
  StreamSubscription<LoggedAppError>? _errorSubscription;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _errorSubscription = _logger.runtimeErrors.listen(_showRuntimeError);
    unawaited(_logger.checkpoint('APP_WIDGET_INITIALIZED'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(_logger.info('Lifecycle changed', details: state.name));
  }

  void _toggleLanguage() {
    setState(() {
      _locale = _locale.languageCode == 'en'
          ? const Locale('ar')
          : const Locale('en');
    });
  }

  void _openSettings() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          settings: widget.settings,
          onToggleLanguage: _toggleLanguage,
        ),
      ),
    );
  }

  Future<void> _showRuntimeError(LoggedAppError appError) async {
    if (_dialogVisible || !mounted) return;
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    _dialogVisible = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 42),
          title: Text('${appError.level}: Application issue'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(
              child: SelectableText(appError.fullText),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: appError.fullText)),
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _navigatorKey.currentState?.push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LogViewerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.article_outlined),
              label: const Text('Full log'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    } finally {
      _dialogVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Cargo Sort',
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: MotionLifecycleScope(
        child: Stack(
          children: [
            HomeScreen(
              store: widget.store,
              settings: widget.settings,
              onToggleLanguage: _toggleLanguage,
            ),
            PositionedDirectional(
              top: 66,
              end: 16,
              child: SafeArea(
                child: Material(
                  color: Colors.white,
                  elevation: 5,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Settings',
                    onPressed: _openSettings,
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: AppTheme.navy,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
