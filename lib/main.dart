import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/logging/app_logger.dart';
import 'core/logging/log_viewer_screen.dart';
import 'core/storage/progress_store.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'l10n/app_localizations.dart';

const String appVersion = '1.0.1';
const String appBuildNumber = '2';
const String appAuthor = 'Walid Atiya Ata - PMP';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runZonedGuarded<void>(
    () => runApp(const BootstrapApp()),
    (Object error, StackTrace stackTrace) {
      debugPrint('Uncaught zone error: $error\n$stackTrace');
    },
  );
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  final ProgressStore _store = ProgressStore();
  String _status = 'Starting Cargo Sort...';
  Object? _fatalError;
  StackTrace? _fatalStackTrace;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      _setStatus('Preparing application services...');
      try {
        await AppErrorBoundary.install().timeout(const Duration(seconds: 8));
      } catch (error, stackTrace) {
        debugPrint('Logger initialization skipped: $error\n$stackTrace');
      }

      // Orientation configuration must never block application startup.
      unawaited(
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]).catchError((Object error, StackTrace stackTrace) {
          debugPrint('Orientation configuration unavailable: $error\n$stackTrace');
        }),
      );

      _setStatus('Loading saved progress...');
      try {
        await _store.load().timeout(const Duration(seconds: 8));
      } catch (error, stackTrace) {
        await _safeWarning(
          'Progress store load failed; defaults will be used',
          error,
          stackTrace,
        );
      }

      if (!mounted) return;
      setState(() => _ready = true);

      // Ads initialize after the first usable screen is visible.
      unawaited(_initializeAdsInBackground());
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _fatalError = error;
        _fatalStackTrace = stackTrace;
      });
    }
  }

  Future<void> _initializeAdsInBackground() async {
    try {
      // Google's Flutter plugin can take up to 30 seconds to complete.
      await MobileAds.instance.initialize().timeout(const Duration(seconds: 35));
      await AppLogger.instance.checkpoint('ADMOB_READY');
    } on TimeoutException catch (error, stackTrace) {
      await _safeInfo(
        'AdMob is unavailable or Google Play services are not responding. '
        'The application will continue without Google ads.',
        '$error\n$stackTrace',
      );
    } catch (error, stackTrace) {
      await _safeInfo(
        'AdMob initialization was skipped. The application will continue '
        'without Google ads.',
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _safeWarning(
    String message,
    Object error,
    StackTrace stackTrace,
  ) async {
    try {
      await AppLogger.instance.warning(
        message,
        error: error,
        stackTrace: stackTrace,
      );
    } catch (_) {
      debugPrint('$message: $error\n$stackTrace');
    }
  }

  Future<void> _safeInfo(String message, String details) async {
    try {
      await AppLogger.instance.info(message, details: details);
    } catch (_) {
      debugPrint('$message\n$details');
    }
  }

  void _setStatus(String value) {
    if (mounted) setState(() => _status = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return FatalBootstrapApp(
        error: _fatalError!,
        stackTrace: _fatalStackTrace ?? StackTrace.empty,
      );
    }

    if (_ready) return CargoSortApp(store: _store);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FlutterLogo(size: 92),
                  const SizedBox(height: 12),
                  Text(
                    'Version $appVersion ($appBuildNumber)',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    appAuthor,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Cargo Sort',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.navy,
                        ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 18),
                  Text(_status, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FatalBootstrapApp extends StatelessWidget {
  const FatalBootstrapApp({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    final text = '$error\n\n$stackTrace';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'Cargo Sort could not finish startup.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.black87,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Clipboard.setData(ClipboardData(text: text)),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy error'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CargoSortApp extends StatefulWidget {
  const CargoSortApp({super.key, required this.store});

  final ProgressStore store;

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
              onPressed: () => Clipboard.setData(
                ClipboardData(text: appError.fullText),
              ),
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
      home: HomeScreen(
        store: widget.store,
        onToggleLanguage: _toggleLanguage,
      ),
    );
  }
}
