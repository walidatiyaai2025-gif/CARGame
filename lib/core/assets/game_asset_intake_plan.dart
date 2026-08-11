import 'game_asset.dart';
import 'game_asset_provenance_catalog.dart';
import 'game_asset_registry.dart';

enum GameAssetIntakeState {
  admitted('admitted'),
  missingProvenance('missing_provenance'),
  missingBinary('missing_binary'),
  missingBinaryAndProvenance('missing_binary_and_provenance');

  const GameAssetIntakeState(this.wireName);

  final String wireName;
}

final class GameAssetIntakeItem {
  const GameAssetIntakeItem({required this.descriptor, required this.state});

  final GameAssetDescriptor descriptor;
  final GameAssetIntakeState state;

  bool get isAdmitted => state == GameAssetIntakeState.admitted;

  bool get needsRuntimeBinary =>
      state == GameAssetIntakeState.missingBinary ||
      state == GameAssetIntakeState.missingBinaryAndProvenance;

  bool get needsProvenance =>
      state == GameAssetIntakeState.missingProvenance ||
      state == GameAssetIntakeState.missingBinaryAndProvenance;

  Map<String, Object?> toJson() => <String, Object?>{
    'assetId': descriptor.id,
    'concept': descriptor.semantics.englishConcept,
    'runtimePath': descriptor.path,
    'profile': descriptor.profile.wireName,
    'width': descriptor.dimensions.width,
    'height': descriptor.dimensions.height,
    'state': state.wireName,
    'needsRuntimeBinary': needsRuntimeBinary,
    'needsProvenance': needsProvenance,
  };
}

final class GameAssetIntakeSummary {
  const GameAssetIntakeSummary({
    required this.totalCount,
    required this.admittedCount,
    required this.missingBinaryOnlyCount,
    required this.missingProvenanceOnlyCount,
    required this.missingBinaryAndProvenanceCount,
    required this.orphanRuntimeBinaryCount,
    required this.orphanProvenanceCount,
  });

  final int totalCount;
  final int admittedCount;
  final int missingBinaryOnlyCount;
  final int missingProvenanceOnlyCount;
  final int missingBinaryAndProvenanceCount;
  final int orphanRuntimeBinaryCount;
  final int orphanProvenanceCount;

  int get remainingCount => totalCount - admittedCount;

  int get binaryMissingCount =>
      missingBinaryOnlyCount + missingBinaryAndProvenanceCount;

  int get provenanceMissingCount =>
      missingProvenanceOnlyCount + missingBinaryAndProvenanceCount;

  bool get isComplete =>
      remainingCount == 0 &&
      orphanRuntimeBinaryCount == 0 &&
      orphanProvenanceCount == 0;

  double get completionRatio =>
      totalCount == 0 ? 1 : admittedCount / totalCount;

  int get completionPercent => (completionRatio * 100).round();

  Map<String, Object?> toJson() => <String, Object?>{
    'total': totalCount,
    'admitted': admittedCount,
    'remaining': remainingCount,
    'missingBinaryOnly': missingBinaryOnlyCount,
    'missingProvenanceOnly': missingProvenanceOnlyCount,
    'missingBinaryAndProvenance': missingBinaryAndProvenanceCount,
    'missingRuntimeBinary': binaryMissingCount,
    'missingProvenance': provenanceMissingCount,
    'orphanRuntimeBinaries': orphanRuntimeBinaryCount,
    'orphanProvenanceRecords': orphanProvenanceCount,
    'completionRatio': completionRatio,
    'completionPercent': completionPercent,
    'complete': isComplete,
  };
}

final class GameAssetIntakePlan {
  GameAssetIntakePlan._({
    required List<GameAssetIntakeItem> items,
    required List<String> orphanRuntimeBinaryPaths,
    required List<String> orphanProvenanceAssetIds,
  }) : items = List.unmodifiable(items),
       orphanRuntimeBinaryPaths = List.unmodifiable(orphanRuntimeBinaryPaths),
       orphanProvenanceAssetIds = List.unmodifiable(orphanProvenanceAssetIds);

  final List<GameAssetIntakeItem> items;
  final List<String> orphanRuntimeBinaryPaths;
  final List<String> orphanProvenanceAssetIds;

  factory GameAssetIntakePlan.build({
    required GameAssetRegistry registry,
    required GameAssetProvenanceCatalog provenance,
    required Iterable<String> runtimeBinaryPaths,
    GameAssetCategory category = GameAssetCategory.cargo,
  }) {
    final runtimePaths = runtimeBinaryPaths
        .map(_normalizeRuntimePath)
        .where((path) => path.isNotEmpty)
        .toSet();
    final descriptors = registry.byCategory(category).toList(growable: false);
    final descriptorPaths = descriptors
        .map((descriptor) => _normalizeRuntimePath(descriptor.path))
        .toSet();
    final descriptorIds = descriptors
        .map((descriptor) => descriptor.id)
        .toSet();

    final items = <GameAssetIntakeItem>[];
    for (final descriptor in descriptors) {
      final provenanceRecord = provenance.find(descriptor.id);
      provenanceRecord?.validateAgainst(descriptor);

      final hasBinary = runtimePaths.contains(
        _normalizeRuntimePath(descriptor.path),
      );
      final hasProvenance = provenanceRecord != null;
      final state = switch ((hasBinary, hasProvenance)) {
        (true, true) => GameAssetIntakeState.admitted,
        (true, false) => GameAssetIntakeState.missingProvenance,
        (false, true) => GameAssetIntakeState.missingBinary,
        (false, false) => GameAssetIntakeState.missingBinaryAndProvenance,
      };

      items.add(GameAssetIntakeItem(descriptor: descriptor, state: state));
    }

    items.sort((left, right) {
      final priority = _statePriority(
        left.state,
      ).compareTo(_statePriority(right.state));
      if (priority != 0) return priority;
      return left.descriptor.id.compareTo(right.descriptor.id);
    });

    final runtimePrefix = 'assets/3d/runtime/${category.wireName}/';
    final orphanRuntimeBinaryPaths =
        runtimePaths
            .where(
              (path) =>
                  path.startsWith(runtimePrefix) &&
                  path.toLowerCase().endsWith('.webp') &&
                  !descriptorPaths.contains(path),
            )
            .toList()
          ..sort();

    final assetIdPrefix = '${category.wireName}.';
    final orphanProvenanceAssetIds =
        provenance.records
            .where(
              (record) =>
                  record.assetId.startsWith(assetIdPrefix) &&
                  !descriptorIds.contains(record.assetId),
            )
            .map((record) => record.assetId)
            .toList()
          ..sort();

    return GameAssetIntakePlan._(
      items: items,
      orphanRuntimeBinaryPaths: orphanRuntimeBinaryPaths,
      orphanProvenanceAssetIds: orphanProvenanceAssetIds,
    );
  }

  int get admittedCount => items.where((item) => item.isAdmitted).length;

  int get remainingCount => items.length - admittedCount;

  int get binaryMissingCount =>
      items.where((item) => item.needsRuntimeBinary).length;

  int get provenanceMissingCount =>
      items.where((item) => item.needsProvenance).length;

  int countState(GameAssetIntakeState state) =>
      items.where((item) => item.state == state).length;

  bool get isComplete => summary.isComplete;

  double get completionRatio => summary.completionRatio;

  GameAssetIntakeSummary get summary => GameAssetIntakeSummary(
    totalCount: items.length,
    admittedCount: admittedCount,
    missingBinaryOnlyCount: countState(GameAssetIntakeState.missingBinary),
    missingProvenanceOnlyCount: countState(
      GameAssetIntakeState.missingProvenance,
    ),
    missingBinaryAndProvenanceCount: countState(
      GameAssetIntakeState.missingBinaryAndProvenance,
    ),
    orphanRuntimeBinaryCount: orphanRuntimeBinaryPaths.length,
    orphanProvenanceCount: orphanProvenanceAssetIds.length,
  );

  GameAssetIntakeItem? find(String assetId) {
    for (final item in items) {
      if (item.descriptor.id == assetId) return item;
    }
    return null;
  }

  List<GameAssetIntakeItem> itemsForState(GameAssetIntakeState state) =>
      List.unmodifiable(items.where((item) => item.state == state));

  List<GameAssetIntakeItem> nextBatch({
    int limit = 12,
    int offset = 0,
    Set<GameAssetIntakeState>? states,
  }) {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'must be greater than zero');
    }
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'must not be negative');
    }

    Iterable<GameAssetIntakeItem> candidates = items.where(
      (item) => !item.isAdmitted,
    );
    if (states != null && states.isNotEmpty) {
      candidates = candidates.where((item) => states.contains(item.state));
    }

    return List.unmodifiable(candidates.skip(offset).take(limit));
  }

  static String _normalizeRuntimePath(String value) {
    var normalized = value.trim().replaceAll('\\', '/');
    while (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }
    while (normalized.contains('//')) {
      normalized = normalized.replaceAll('//', '/');
    }
    return normalized;
  }

  static int _statePriority(GameAssetIntakeState state) => switch (state) {
    GameAssetIntakeState.missingProvenance => 0,
    GameAssetIntakeState.missingBinary => 1,
    GameAssetIntakeState.missingBinaryAndProvenance => 2,
    GameAssetIntakeState.admitted => 3,
  };
}
