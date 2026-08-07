import 'package:cargo_sort_game/core/navigation/game_route_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main destination names stay stable and unique', () {
    final names = <String>{
      GameRouteNames.home,
      GameRouteNames.worldMap,
      GameRouteNames.shop,
      GameRouteNames.progress,
      GameRouteNames.settings,
      GameRouteNames.logs,
    };

    expect(names, hasLength(6));
    expect(names.every((name) => name.startsWith('/')), isTrue);
  });

  test('level routes and guard keys are deterministic', () {
    expect(GameRouteNames.briefing(25), '/briefing/level/25');
    expect(GameRouteNames.game(25), '/game/level/25');
    expect(GameRouteNames.result(25), '/result/level/25');
    expect(GameRouteNames.guard(GameRouteNames.shop), 'route:/shop');
  });
}
