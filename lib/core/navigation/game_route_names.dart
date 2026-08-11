/// Stable names for the main in-app navigation destinations.
///
/// Keep route identifiers centralized so analytics, diagnostics, tests and
/// duplicate-push guards observe one contract instead of screen-local strings.
abstract final class GameRouteNames {
  static const home = '/';
  static const worldMap = '/world-map';
  static const shop = '/shop';
  static const progress = '/progress';
  static const settings = '/settings';
  static const logs = '/logs';
  static const realtime3dLab = '/realtime-3d-lab';

  static String briefing(int level) => '/briefing/level/$level';
  static String game(int level) => '/game/level/$level';
  static String result(int level) => '/result/level/$level';

  static String guard(String routeName) => 'route:$routeName';
}
