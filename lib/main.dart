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
    await logger.info('Application bootstrap started');

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      await logger.info('Orientation configured');
    } catch (error, stackTrace) {
      await logger.warning(
        'Failed to configure orientation',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await MobileAds.instance.initialize();
      await logger.info('Google Mobile Ads initialized');
    } catch (error, stackTrace) {
      await logger.warning(
        'Google Mobile Ads initialization failed; app will continue without ads',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final store = ProgressStore();
    try {
      await store.load();
      await logger.info('Progress store loaded');
    } catch (error, stackTrace) {
      await logger.warning(
        'Progress store load failed; defaults will be used',
        error: error,
        stackTrace: stackTrace,
      );
    }

    runApp(CargoSortApp(store: store));
    await logger.info('Application UI started');
  }, (Object error, StackTrace stackTrace) async {
    await AppLogger.instance.error('Uncaught bootstrap error', error, stackTrace);
    runApp(FatalErrorScreen(error: error, stackTrace: stackTrace));
  });
}

class CargoSortApp extends StatefulWidget {
  const CargoSortApp({super.key, required this.store});
  final ProgressStore store;

  @override
  State<CargoSortApp> createState() => _CargoSortAppState();
}

class _CargoSortAppState extends State<CargoSortApp> {
  Locale _locale = const Locale('en');

  void _toggleLanguage() {
    setState(() => _locale = _locale.languageCode == 'en'
        ? const Locale('ar')
        : const Locale('en'));
  }

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      AppLogger.instance.flutterError(details);
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
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
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
