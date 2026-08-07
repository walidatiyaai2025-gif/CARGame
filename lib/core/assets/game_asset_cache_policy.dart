import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'game_asset_registry.dart';

typedef GameAssetPrecacheLoader =
    Future<void> Function(AssetImage provider, BuildContext context);
typedef GameAssetEvictor = Future<void> Function(AssetImage provider);

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
  GameAssetCachePolicy({
    this.maxEntries = 24,
    GameAssetPrecacheLoader? precacheLoader,
    GameAssetEvictor? evictor,
  }) : assert(maxEntries > 0),
       _precacheLoader = precacheLoader ?? _precacheWithFlutter,
       _evictor = evictor ?? _evictWithFlutter;

  final int maxEntries;
  final GameAssetPrecacheLoader _precacheLoader;
  final GameAssetEvictor _evictor;

  final LinkedHashMap<String, AssetImage> _cached =
      LinkedHashMap<String, AssetImage>();
  final Set<String> _inFlight = <String>{};
  final LinkedHashSet<String> _failed = LinkedHashSet<String>();

  GameAssetCacheSnapshot get snapshot => GameAssetCacheSnapshot(
    cachedIds: List.unmodifiable(_cached.keys),
    inFlightIds: List.unmodifiable(_inFlight),
    failedIds: List.unmodifiable(_failed),
    maxEntries: maxEntries,
  );

  bool isCached(String assetId) => _cached.containsKey(assetId);
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

    final existing = _cached.remove(assetId);
    if (existing != null) {
      _cached[assetId] = existing;
      return true;
    }
    if (_inFlight.contains(assetId)) return false;

    final provider = AssetImage(
      descriptor.path,
      bundle: DefaultAssetBundle.of(context),
    );
    _inFlight.add(assetId);
    notifyListeners();
    try {
      await _precacheLoader(provider, context);
      _failed.remove(assetId);
      _cached[assetId] = provider;
      await _trimToBudget();
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

  Future<void> forget(String assetId) async {
    final provider = _cached.remove(assetId);
    final failedRemoved = _failed.remove(assetId);
    if (provider != null) {
      await _evictor(provider);
    }
    if (provider != null || failedRemoved) notifyListeners();
  }

  Future<void> clear() async {
    if (_cached.isEmpty && _failed.isEmpty && _inFlight.isEmpty) return;
    final providers = List<AssetImage>.from(_cached.values);
    _cached.clear();
    _failed.clear();
    _inFlight.clear();
    for (final provider in providers) {
      await _evictor(provider);
    }
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

  Future<void> _trimToBudget() async {
    while (_cached.length > maxEntries) {
      final evictedId = _cached.keys.first;
      final provider = _cached.remove(evictedId);
      if (provider != null) {
        await _evictor(provider);
      }
    }
  }

  static Future<void> _precacheWithFlutter(
    AssetImage provider,
    BuildContext context,
  ) {
    return precacheImage(provider, context);
  }

  static Future<void> _evictWithFlutter(AssetImage provider) async {
    await provider.evict();
  }
}
