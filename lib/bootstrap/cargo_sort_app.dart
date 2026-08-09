import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/ads/ad_consent_controller.dart';
import '../core/logging/app_logger.dart';
import '../core/logging/log_viewer_screen.dart';
import '../core/motion/motion_lifecycle_scope.dart';
import '../core/navigation/game_navigator.dart';
import '../core/navigation/game_route_names.dart';
import '../core/privacy/local_data_controller.dart';
import '../core/settings/app_settings_store.dart';
import '../core/storage/progress_store.dart';
import '../core/theme/app_theme.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../l10n/app_localizations.dart';

class CargoSortApp extends StatefulWidget {
  const CargoSortApp({
    super.key,
    required this.store,
    required this.settings,
    this.adConsentController,
  });

  final ProgressStore store;
  final AppSettingsStore settings;
  final AdConsentController? adConsentController;

  @override
  State<CargoSortApp> createState() => _CargoSortAppState();
}

class _CargoSortAppState extends State<CargoSortApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppLogger _logger = AppLogger.instance;
  final LocalDataController _localDataController = LocalDataController();
  Locale _locale = const Locale('en');
  StreamSubscription<LoggedAppError>? _errorSubscription;
  late ProgressStore _activeStore;
  late AppSettingsStore _activeSettings;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    _activeStore = widget.store;
    _activeSettings = widget.settings;
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
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    unawaited(
      GameNavigator.pushNamed<void>(
        context,
        name: GameRouteNames.settings,
        builder: (_) => SettingsScreen(
          settings: _activeSettings,
          onToggleLanguage: _toggleLanguage,
          adConsentController: widget.adConsentController,
          localDataController: _localDataController,
          onLocalDataDeleted: _rehydrateAfterLocalDataDeletion,
        ),
      ),
    );
  }

  Future<void> _rehydrateAfterLocalDataDeletion() async {
    final nextStore = ProgressStore();
    final nextSettings = AppSettingsStore();

    try {
      await Future.wait<void>([nextStore.load(), nextSettings.load()]);
    } catch (_) {
      // Constructors already hold safe defaults. A reset must not restore
      // deleted values merely because a local plugin reload failed.
    }

    if (!mounted) return;
    setState(() {
      _activeStore = nextStore;
      _activeSettings = nextSettings;
    });
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
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
                final navigatorContext = _navigatorKey.currentContext;
                if (navigatorContext == null) return;
                unawaited(
                  GameNavigator.pushNamed<void>(
                    navigatorContext,
                    name: GameRouteNames.logs,
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
              store: _activeStore,
              settings: _activeSettings,
              onToggleLanguage: _toggleLanguage,
              adConsentState: widget.adConsentController?.state,
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
