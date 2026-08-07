import 'dart:io';

import 'package:cargo_sort_game/core/assets/game_asset_admission.dart';
import 'package:cargo_sort_game/core/assets/game_asset_provenance_catalog.dart';
import 'package:cargo_sort_game/core/assets/game_asset_registry.dart';

Future<void> main() async {
  const manifestPath = 'assets/3d/manifest.json';
  const provenancePath = 'assets/3d/provenance/catalog.json';
  const runtimeRoot = 'assets/3d/runtime';

  try {
    final manifestFile = File(manifestPath);
    final provenanceFile = File(provenancePath);
    if (!manifestFile.existsSync()) {
      throw StateError('Missing asset manifest: $manifestPath');
    }
    if (!provenanceFile.existsSync()) {
      throw StateError('Missing provenance catalog: $provenancePath');
    }

    final registry = GameAssetRegistry.fromJsonString(
      await manifestFile.readAsString(),
    );
    final provenance = GameAssetProvenanceCatalog.fromJsonString(
      await provenanceFile.readAsString(),
    );

    final binaryPaths = <String>[];
    final runtime = Directory(runtimeRoot);
    if (runtime.existsSync()) {
      await for (final entity in runtime.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.webp')) {
          binaryPaths.add(entity.path.replaceAll('\\', '/'));
        }
      }
    }

    GameAssetAdmission.validate(
      registry: registry,
      provenance: provenance,
      runtimeBinaryPaths: binaryPaths,
    );

    stdout.writeln('ASSET PIPELINE VALIDATION PASSED');
    stdout.writeln('Manifest entries : ${registry.assets.length}');
    stdout.writeln('Provenance records: ${provenance.records.length}');
    stdout.writeln('Runtime WebP files: ${binaryPaths.length}');
  } catch (error, stackTrace) {
    stderr.writeln('ASSET PIPELINE VALIDATION FAILED');
    stderr.writeln(error);
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}
