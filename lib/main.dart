import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/storage/progress_store.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await MobileAds.instance.initialize();
  final store = ProgressStore();
  await store.load();
  runApp(CargoSortApp(store: store));
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
