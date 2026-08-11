import 'dart:convert';
import 'dart:io';

import 'package:cargo_sort_game/core/assets/game_asset_intake_plan.dart';
import 'package:cargo_sort_game/core/assets/game_asset_provenance_catalog.dart';
import 'package:cargo_sort_game/core/assets/game_asset_registry.dart';

Future<void> main(List<String> arguments) async {
  const manifestPath = 'assets/3d/manifest.json';
  const provenancePath = 'assets/3d/provenance/catalog.json';
  const runtimeRoot = 'assets/3d/runtime';

  try {
    final limit = _parseLimit(arguments);
    final jsonOutput = arguments.contains('--json');

    final registry = GameAssetRegistry.fromJsonString(
      await File(manifestPath).readAsString(),
    );
    final provenance = GameAssetProvenanceCatalog.fromJsonString(
      await File(provenancePath).readAsString(),
    );

    final runtimeBinaryPaths = <String>[];
    final runtimeDirectory = Directory(runtimeRoot);
    if (runtimeDirectory.existsSync()) {
      await for (final entity in runtimeDirectory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File && entity.path.toLowerCase().endsWith('.webp')) {
          runtimeBinaryPaths.add(entity.path.replaceAll('\\', '/'));
        }
      }
    }

    final plan = GameAssetIntakePlan.build(
      registry: registry,
      provenance: provenance,
      runtimeBinaryPaths: runtimeBinaryPaths,
    );
    final batch = plan.nextBatch(limit: limit);

    if (jsonOutput) {
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert(<String, Object?>{
          'cargoDescriptors': plan.items.length,
          'admitted': plan.admittedCount,
          'missingRuntimeBinary': plan.binaryMissingCount,
          'missingProvenance': plan.provenanceMissingCount,
          'batchLimit': limit,
          'batch': batch.map((item) => item.toJson()).toList(growable: false),
        }),
      );
      return;
    }

    stdout.writeln('AST-007 CARGO ASSET INTAKE');
    stdout.writeln('Cargo descriptors      : ${plan.items.length}');
    stdout.writeln('Admitted               : ${plan.admittedCount}');
    stdout.writeln('Missing runtime binary : ${plan.binaryMissingCount}');
    stdout.writeln('Missing provenance     : ${plan.provenanceMissingCount}');
    stdout.writeln('Next production batch  : ${batch.length}');
    stdout.writeln();

    for (final item in batch) {
      final descriptor = item.descriptor;
      stdout.writeln('- ${descriptor.id}');
      stdout.writeln('  concept : ${descriptor.semantics.englishConcept}');
      stdout.writeln('  output  : ${descriptor.path}');
      stdout.writeln(
        '  profile : ${descriptor.profile.wireName} '
        '${descriptor.dimensions.width}x${descriptor.dimensions.height}',
      );
      stdout.writeln('  state   : ${item.state.wireName}');
    }
  } catch (error, stackTrace) {
    stderr.writeln('AST-007 ASSET INTAKE PLANNING FAILED');
    stderr.writeln(error);
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

int _parseLimit(List<String> arguments) {
  const prefix = '--limit=';
  final value = arguments
      .where((argument) => argument.startsWith(prefix))
      .map((argument) => argument.substring(prefix.length))
      .firstOrNull;
  if (value == null) return 12;

  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0 || parsed > 124) {
    throw FormatException('--limit must be an integer from 1 to 124: $value');
  }
  return parsed;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
