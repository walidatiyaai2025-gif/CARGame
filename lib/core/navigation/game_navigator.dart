import 'package:flutter/material.dart';

import '../motion/game_route.dart';

/// Central navigation façade for CARGame.
///
/// Keeps route motion, route naming and optional duplicate-push protection in one
/// place so screens do not recreate PageRouteBuilder/MaterialPageRoute policies.
final class GameNavigator {
  GameNavigator._();

  static final Set<String> _activeGuards = <String>{};

  static Future<T?> push<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? name,
    String? guardKey,
  }) async {
    final navigator = Navigator.of(context);
    final key = guardKey?.trim();

    if (key != null && key.isNotEmpty) {
      if (!_activeGuards.add(key)) {
        return null;
      }
    }

    try {
      return await navigator.push<T>(
        GameRoute.build<T>(context: context, builder: builder, name: name),
      );
    } finally {
      if (key != null && key.isNotEmpty) {
        _activeGuards.remove(key);
      }
    }
  }

  static Future<T?> replace<T, TO>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? name,
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      GameRoute.build<T>(context: context, builder: builder, name: name),
      result: result,
    );
  }

  @visibleForTesting
  static void resetGuards() => _activeGuards.clear();
}
