import 'game_asset_provenance_catalog.dart';
import 'game_asset_registry.dart';

/// Enforces the release admission boundary for binary 3D runtime art.
///
/// Manifest entries may exist before their binary is authored so UI code can bind
/// to stable IDs and exercise fallback behavior. The inverse is never allowed: a
/// runtime binary cannot exist without both a registry descriptor and a complete,
/// matching provenance record.
final class GameAssetAdmission {
  const GameAssetAdmission._();

  static void validate({
    required GameAssetRegistry registry,
    required GameAssetProvenanceCatalog provenance,
    required Iterable<String> runtimeBinaryPaths,
  }) {
    final binaries = runtimeBinaryPaths
        .map(_normalize)
        .where((path) => path.toLowerCase().endsWith('.webp'))
        .toSet();

    final manifestByPath = {
      for (final asset in registry.assets) _normalize(asset.path): asset,
    };

    for (final binaryPath in binaries) {
      final asset = manifestByPath[binaryPath];
      if (asset == null) {
        throw FormatException(
          'Runtime binary is not registered in assets/3d/manifest.json: '
          '$binaryPath',
        );
      }

      final record = provenance.find(asset.id);
      if (record == null) {
        throw FormatException(
          'Runtime binary ${asset.id} has no commercial-use provenance record.',
        );
      }
      record.validateAgainst(asset);
    }

    for (final record in provenance.records) {
      final asset = registry.find(record.assetId);
      if (asset == null) {
        throw FormatException(
          'Provenance record ${record.assetId} has no matching manifest entry.',
        );
      }
      record.validateAgainst(asset);
      if (!binaries.contains(_normalize(asset.path))) {
        throw FormatException(
          'Approved provenance record ${record.assetId} has no runtime WebP binary.',
        );
      }
    }
  }

  static String _normalize(String value) => value.replaceAll('\\', '/');
}
