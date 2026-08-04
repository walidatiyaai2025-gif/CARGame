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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppErrorBoundary.install();

  await runZonedGuarded<Future<void>>(() async {
    final logger = AppLogger.instance;
    await logger.checkpoint('BOOTSTRAP_START');

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      await logger.checkpoint('ORIENTATION_READY');
    } catch (error, stackTrace) {
      await logger.warning(
        'Failed to configure orientation',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await MobileAds.instance.initialize();
      await logger.checkpoint('ADMOB_READY');
    } catch (error, stackTrace) {
      await logger.warning(
        'Google Mobile Ads initialization failed; app will continue without ads',
        error: error,
        stackTrace: stackTrace,
        notifyUser: true,
      );
    }

    final store = ProgressStore();
    try {
      await store.load();
      await logger.checkpoint('PROGRESS_STORE_READY');
    } catch (error, stackTrace) {
      await logger.warning(
        'Progress store load failed; defaults will be used',
        error: error,
        stackTrace: stackTrace,
        notifyUser: true,
      );
    }

    runApp(CargoSortApp(store: store));
    await logger.checkpoint('RUN_APP_CALLED');
  }, (Object error, StackTrace stackTrace) async {
    await AppLogger.instance.error(
      'Uncaught bootstrap error',
      error,
      stackTrace,
      notifyUser: false,
    );
    runApp(FatalErrorScreen(error: error, stackTrace: stackTrace));
  });
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
    unawaited(
      _logger.info('Language changed', details: _locale.languageCode),
    );
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
          icon: const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
            size: 42,
          ),
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
                await Clipboard.setData(
                  ClipboardData(text: appError.fullText),
                );
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
                const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red,
                ),
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
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: text),
                  ),
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
