// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cargo Sort';

  @override
  String get subtitle => 'Warehouse Puzzle';

  @override
  String get play => 'Play';

  @override
  String get levels => 'Levels';

  @override
  String get coins => 'Coins';

  @override
  String get level => 'Level';

  @override
  String get moves => 'Moves';

  @override
  String get goal => 'Sort every package into the matching warehouse.';

  @override
  String get tapPackage => 'Tap a package, then tap the matching warehouse.';

  @override
  String get hint => 'Hint';

  @override
  String get restart => 'Restart';

  @override
  String get home => 'Home';

  @override
  String get completed => 'Level complete!';

  @override
  String get failed => 'No moves left';

  @override
  String get next => 'Next level';

  @override
  String get retry => 'Try again';

  @override
  String get extraMoves => 'Watch test ad: +5 moves';

  @override
  String get rewardAdded => 'Reward added';

  @override
  String get locked => 'Locked';

  @override
  String get language => 'العربية';

  @override
  String get testAds => 'Test ads enabled';

  @override
  String get privacyNote => 'Replace test ad IDs only before publishing.';
}
