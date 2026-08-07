import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'game_asset_registry.dart';

@immutable
final class GameAssetCacheSnapshot {
  const GameAssetCacheSnapshot({
    required this.cachedIds,
    required this.inFlightIds,
    required this.failedIds,
    required this.maxEntries,
  });

  final List<String> cachedIds;
  final List<String> inFlightIds;
  final List<String> failedIds;
  final int maxEntries;

  int get cachedCount => cachedIds.length;
  int get inFlightCount => inFlightIds.length;
  int get failedCount => failedIds.length;
}

/// Bounded, observable precache coordinator for manifest-backed 3D assets.
///
/// Domain/gameplay truth never depends on this cache. Precache failures are isolated
/// and remembered for diagnostics, while UI fallbacks continue to render normally.
final class GameAssetCachePolicy extends ChangeNotifier {
  GameAssetCachePolicy({this.maxEntries = 24}) : assert(maxEntries > 0);

  final int maxEntries;

  final LinkedHashSet<String> _cached = LinkedHashSet<String>();
  final Set<String> _inFlight = <String>{};
  final LinkedHashSet<String> _failed = LinkedHashSet<String>();

  GameAssetCacheSnapshot get snapshot => GameAssetCacheSnapshot(
    cachedIds: List.unmodifiable(_cached),
    inFlightIds: List.unmodifiable(_inFlight),
    failedIds: List.unmodifiable(_failed),
    maxEntries: maxEntries,
  );

  bool isCached(String assetId) => _cached.contains(assetId);
  bool isInFlight(String assetId) => _inFlight.contains(assetId);
  bool hasFailed(String assetId) => _failed.contains(assetId);

  Future<bool> precache(
    BuildContext context,
    GameAssetRegistry registry,
    String assetId,
  ) async {
    final descriptor = registry.find(assetId);
    if (descriptor == null) {
      _recordFailure(assetId);
      return false;
    }

    if (_cached.remove(assetId)) {
      _cached.add(assetId);
      return true;
    }
    if (_inFlight.contains(assetId)) return false;

    _inFlight.add(assetId);
    notifyListeners();
    try {
      await precacheImage(AssetImage(descriptor.path), context);
      _failed.remove(assetId);
      _cached.add(assetId);
      _trimToBudget();
      return true;
    } catch (_) {
      _recordFailure(assetId, notify: false);
      return false;
    } finally {
      _inFlight.remove(assetId);
      notifyListeners();
    }
  }

  Future<void> precacheNearFuture(
    BuildContext context,
    GameAssetRegistry registry,
    Iterable<String> assetIds, {
    int limit = 8,
  }) async {
    if (limit <= 0) return;
    final unique = <String>{};
    for (final id in assetIds) {
      if (unique.length >= limit) break;
      if (id.trim().isEmpty || !unique.add(id)) continue;
      await precache(context, registry, id);
    }
  }

  void forget(String assetId) {
    final changed = _cached.remove(assetId) | _failed.remove(assetId);
    if (changed) notifyListeners();
  }

  void clear() {
    if (_cached.isEmpty && _failed.isEmpty && _inFlight.isEmpty) return;
    _cached.clear();
    _failed.clear();
    _inFlight.clear();
    notifyListeners();
  }

  void _recordFailure(String assetId, {bool notify = true}) {
    _failed.remove(assetId);
    _failed.add(assetId);
    while (_failed.length > maxEntries) {
      _failed.remove(_failed.first);
    }
    if (notify) notifyListeners();
  }

  void _trimToBudget() {
    while (_cached.length > maxEntries) {
      final evicted = _cached.first;
      _cached.remove(evicted);
      PaintingBinding.instance.imageCache.evict(
        const AssetImage(''),
        includeLive: false,
      );
    }
  }
}
