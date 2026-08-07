import 'package:flutter/material.dart';

import '../motion/game_route.dart';
import 'game_route_names.dart';

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

  /// Pushes one of the stable named destinations through the shared route policy.
  ///
  /// Named destinations are duplicate-guarded by default so repeated taps cannot
  /// stack the same destination while its first push remains active.
  static Future<T?> pushNamed<T>(
    BuildContext context, {
    required String name,
    required WidgetBuilder builder,
    bool guardDuplicates = true,
  }) {
    return push<T>(
      context,
      name: name,
      guardKey: guardDuplicates ? GameRouteNames.guard(name) : null,
      builder: builder,
    );
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

  /// Replaces the active route with one of the stable named destinations.
  ///
  /// Replacement callers own their async action guard because keeping a global
  /// navigation guard alive until the replacement route pops would block valid
  /// re-entry flows such as retrying a mission after returning to briefing.
  static Future<T?> replaceNamed<T, TO>(
    BuildContext context, {
    required String name,
    required WidgetBuilder builder,
    TO? result,
  }) {
    return replace<T, TO>(
      context,
      name: name,
      builder: builder,
      result: result,
    );
  }

  @visibleForTesting
  static void resetGuards() => _activeGuards.clear();
}
