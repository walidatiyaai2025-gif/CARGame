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
    required this.hitCount,
    required this.missCount,
    required this.joinedRequestCount,
    required this.successfulLoadCount,
    required this.loadFailureCount,
    required this.evictionCount,
    required this.staleCompletionCount,
    required this.evictionFailureCount,
  });

  final List<String> cachedIds;
  final List<String> inFlightIds;
  final List<String> failedIds;
  final int maxEntries;
  final int hitCount;
  final int missCount;
  final int joinedRequestCount;
  final int successfulLoadCount;
  final int loadFailureCount;
  final int evictionCount;
  final int staleCompletionCount;
  final int evictionFailureCount;

  int get cachedCount => cachedIds.length;
  int get inFlightCount => inFlightIds.length;
  int get failedCount => failedIds.length;
}

/// Bounded, observable precache coordinator for manifest-backed 3D assets.
///
/// Domain/gameplay truth never depends on this cache. Precache failures are isolated
/// and remembered for diagnostics, while UI fallbacks continue to render normally.
/// Concurrent requests for the same asset share one load operation, and clear/forget
/// invalidation cannot be undone by a late asynchronous completion.
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
  final LinkedHashMap<String, Future<bool>> _inFlight =
      LinkedHashMap<String, Future<bool>>();
  final LinkedHashSet<String> _failed = LinkedHashSet<String>();
  final Map<String, int> _assetGenerations = <String, int>{};

  int _generation = 0;
  int _hitCount = 0;
  int _missCount = 0;
  int _joinedRequestCount = 0;
  int _successfulLoadCount = 0;
  int _loadFailureCount = 0;
  int _evictionCount = 0;
  int _staleCompletionCount = 0;
  int _evictionFailureCount = 0;

  GameAssetCacheSnapshot get snapshot => GameAssetCacheSnapshot(
    cachedIds: List.unmodifiable(_cached.keys),
    inFlightIds: List.unmodifiable(_inFlight.keys),
    failedIds: List.unmodifiable(_failed),
    maxEntries: maxEntries,
    hitCount: _hitCount,
    missCount: _missCount,
    joinedRequestCount: _joinedRequestCount,
    successfulLoadCount: _successfulLoadCount,
    loadFailureCount: _loadFailureCount,
    evictionCount: _evictionCount,
    staleCompletionCount: _staleCompletionCount,
    evictionFailureCount: _evictionFailureCount,
  );

  bool isCached(String assetId) => _cached.containsKey(assetId);
  bool isInFlight(String assetId) => _inFlight.containsKey(assetId);
  bool hasFailed(String assetId) => _failed.contains(assetId);

  Future<bool> precache(
    BuildContext context,
    GameAssetRegistry registry,
    String assetId,
  ) {
    final existing = _cached.remove(assetId);
    if (existing != null) {
      _cached[assetId] = existing;
      _hitCount += 1;
      notifyListeners();
      return Future<bool>.value(true);
    }

    final joined = _inFlight[assetId];
    if (joined != null) {
      _joinedRequestCount += 1;
      notifyListeners();
      return joined;
    }

    _missCount += 1;
    final descriptor = registry.find(assetId);
    if (descriptor == null) {
      _loadFailureCount += 1;
      _recordFailure(assetId);
      return Future<bool>.value(false);
    }

    final globalGeneration = _generation;
    final assetGeneration = _assetGenerations[assetId] ?? 0;
    final provider = AssetImage(descriptor.path);

    late final Future<bool> operation;
    operation =
        _loadAndCache(
          context,
          assetId,
          provider,
          globalGeneration: globalGeneration,
          assetGeneration: assetGeneration,
        ).whenComplete(() {
          if (identical(_inFlight[assetId], operation)) {
            _inFlight.remove(assetId);
            notifyListeners();
          }
        });

    _inFlight[assetId] = operation;
    notifyListeners();
    return operation;
  }

  Future<void> precacheNearFuture(
    BuildContext context,
    GameAssetRegistry registry,
    Iterable<String> assetIds, {
    int limit = 8,
    bool retryFailed = false,
  }) async {
    if (limit <= 0) return;
    final effectiveLimit = limit < maxEntries ? limit : maxEntries;
    final unique = <String>{};
    var attempts = 0;
    for (final rawId in assetIds) {
      if (attempts >= effectiveLimit) break;
      final id = rawId.trim();
      if (id.isEmpty || !unique.add(id)) continue;
      if (!retryFailed && hasFailed(id)) continue;
      attempts += 1;
      await precache(context, registry, id);
    }
  }

  Future<void> forget(String assetId) async {
    _assetGenerations[assetId] = (_assetGenerations[assetId] ?? 0) + 1;
    final provider = _cached.remove(assetId);
    final failedRemoved = _failed.remove(assetId);
    if (provider != null) {
      await _evictSafely(provider);
    }
    if (provider != null || failedRemoved || _inFlight.containsKey(assetId)) {
      notifyListeners();
    }
  }

  Future<void> clear() async {
    if (_cached.isEmpty && _failed.isEmpty && _inFlight.isEmpty) return;
    _generation += 1;
    final providers = List<AssetImage>.from(_cached.values);
    _cached.clear();
    _failed.clear();
    for (final provider in providers) {
      await _evictSafely(provider);
    }
    notifyListeners();
  }

  void resetStatistics() {
    _hitCount = 0;
    _missCount = 0;
    _joinedRequestCount = 0;
    _successfulLoadCount = 0;
    _loadFailureCount = 0;
    _evictionCount = 0;
    _staleCompletionCount = 0;
    _evictionFailureCount = 0;
    notifyListeners();
  }

  Future<bool> _loadAndCache(
    BuildContext context,
    String assetId,
    AssetImage provider, {
    required int globalGeneration,
    required int assetGeneration,
  }) async {
    try {
      await _precacheLoader(provider, context);
      if (_isStale(assetId, globalGeneration, assetGeneration)) {
        _staleCompletionCount += 1;
        await _evictSafely(provider);
        return false;
      }

      _failed.remove(assetId);
      _cached[assetId] = provider;
      _successfulLoadCount += 1;
      await _trimToBudget();
      return true;
    } catch (_) {
      if (!_isStale(assetId, globalGeneration, assetGeneration)) {
        _loadFailureCount += 1;
        _recordFailure(assetId, notify: false);
      }
      return false;
    }
  }

  bool _isStale(String assetId, int globalGeneration, int assetGeneration) {
    return globalGeneration != _generation ||
        assetGeneration != (_assetGenerations[assetId] ?? 0);
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
        await _evictSafely(provider);
      }
    }
  }

  Future<void> _evictSafely(AssetImage provider) async {
    _evictionCount += 1;
    try {
      await _evictor(provider);
    } catch (_) {
      _evictionFailureCount += 1;
    }
  }

  static Future<void> _precacheWithFlutter(
    AssetImage provider,
    BuildContext context,
  ) {
    return precacheImage(provider, context);
  }

  static Future<void> _evictWithFlutter(AssetImage provider) async {
    await provider.evict(cache: PaintingBinding.instance.imageCache);
  }
}
