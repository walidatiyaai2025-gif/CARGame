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
  const GameAssetIntakeItem({
    required this.descriptor,
    required this.state,
  });

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

final class GameAssetIntakePlan {
  GameAssetIntakePlan._(List<GameAssetIntakeItem> items)
    : items = List.unmodifiable(items);

  final List<GameAssetIntakeItem> items;

  factory GameAssetIntakePlan.build({
    required GameAssetRegistry registry,
    required GameAssetProvenanceCatalog provenance,
    required Iterable<String> runtimeBinaryPaths,
    GameAssetCategory category = GameAssetCategory.cargo,
  }) {
    final runtimePaths = runtimeBinaryPaths
        .map((path) => path.replaceAll('\\', '/'))
        .toSet();

    final items = <GameAssetIntakeItem>[];
    for (final descriptor in registry.byCategory(category)) {
      final provenanceRecord = provenance.find(descriptor.id);
      provenanceRecord?.validateAgainst(descriptor);

      final hasBinary = runtimePaths.contains(descriptor.path);
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
      final priority = _statePriority(left.state).compareTo(
        _statePriority(right.state),
      );
      if (priority != 0) return priority;
      return left.descriptor.id.compareTo(right.descriptor.id);
    });

    return GameAssetIntakePlan._(items);
  }

  int get admittedCount => items.where((item) => item.isAdmitted).length;

  int get binaryMissingCount =>
      items.where((item) => item.needsRuntimeBinary).length;

  int get provenanceMissingCount =>
      items.where((item) => item.needsProvenance).length;

  List<GameAssetIntakeItem> nextBatch({int limit = 12}) {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'must be greater than zero');
    }
    return List.unmodifiable(
      items.where((item) => !item.isAdmitted).take(limit),
    );
  }

  static int _statePriority(GameAssetIntakeState state) => switch (state) {
    GameAssetIntakeState.missingProvenance => 0,
    GameAssetIntakeState.missingBinary => 1,
    GameAssetIntakeState.missingBinaryAndProvenance => 2,
    GameAssetIntakeState.admitted => 3,
  };
}