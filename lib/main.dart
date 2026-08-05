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
        await AppErrorBoundary.install().timeout(const Duration(seconds: 5));
      } catch (error, stackTrace) {
        debugPrint('Logger initialization skipped: $error\n$stackTrace');
      }

      _setStatus('Configuring display...');
      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]).timeout(const Duration(seconds: 3));
      } catch (error, stackTrace) {
        await _safeWarning(
          'Failed to configure orientation',
          error,
          stackTrace,
        );
      }

      _setStatus('Loading saved progress...');
      try {
        await _store.load().timeout(const Duration(seconds: 5));
      } catch (error, stackTrace) {
        await _safeWarning(
          'Progress store load failed; defaults will be used',
          error,
          stackTrace,
        );
      }

      if (!mounted) return;
      setState(() => _ready = true);

      // Ads must never block the first visible application screen.
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
      await MobileAds.instance.initialize().timeout(const Duration(seconds: 10));
      await AppLogger.instance.checkpoint('ADMOB_READY');
    } catch (error, stackTrace) {
      await _safeWarning(
        'Google Mobile Ads initialization failed; app will continue without ads',
        error,
        stackTrace,
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

  void _setStatus(String value) {
    if (!mounted) return;
    setState(() => _status = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return FatalBootstrapApp(
        error: _fatalError!,
        stackTrace: _fatalStackTrace ?? StackTrace.empty,
      );
    }

    if (_ready) {
      return CargoSortApp(store: _store);
    }

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
                  const SizedBox(height: 28),
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
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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
    unawaited(_logger.info('Language changed', details: _locale.languageCode));
  }

  Future<void> _showRuntimeError(LoggedAppError appError) async {
    if (_dialogVisible) return;

    final context = _navigatorKey.currentContext;
    if (context == null || !mounted) return;

    _dialogVisible = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 42),
          title: Text('${appError.level}: Application issue'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'The app captured an error. Copy it and send it for review.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        appError.fullText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: appError.fullText));
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Error copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
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
    ErrorWidget.builder = (FlutterErrorDetails details) {
      unawaited(_logger.flutterError(details));
      final text = '${details.exceptionAsString()}\n\n${details.stack ?? ''}';

      return Material(
        color: const Color(0xFFF8F9FA),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                const SizedBox(height: 12),
                const Text('A screen error occurred. Copy the details below.'),
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
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy error'),
                ),
              ],
            ),
          ),
        ),
      );
    };

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
