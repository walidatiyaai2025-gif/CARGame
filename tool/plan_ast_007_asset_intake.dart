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
    final options = _CliOptions.parse(arguments);
    if (options.help) {
      stdout.write(_usage);
      return;
    }

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
    final states = options.state == null
        ? null
        : <GameAssetIntakeState>{options.state!};
    final batch = options.summaryOnly
        ? const <GameAssetIntakeItem>[]
        : plan.nextBatch(
            limit: options.limit,
            offset: options.offset,
            states: states,
          );

    switch (options.format) {
      case _OutputFormat.human:
        _writeHuman(plan, batch, options);
      case _OutputFormat.json:
        _writeJson(plan, batch, options);
      case _OutputFormat.csv:
        _writeCsv(batch);
    }

    if (options.strict && !plan.isComplete) {
      stderr.writeln(
        'AST-007 intake is incomplete: ${plan.remainingCount} descriptor(s) '
        'remain and/or orphan records are present.',
      );
      exitCode = 2;
    }
  } catch (error, stackTrace) {
    stderr.writeln('AST-007 ASSET INTAKE PLANNING FAILED');
    stderr.writeln(error);
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

void _writeHuman(
  GameAssetIntakePlan plan,
  List<GameAssetIntakeItem> batch,
  _CliOptions options,
) {
  final summary = plan.summary;
  stdout.writeln('AST-007 CARGO ASSET INTAKE');
  stdout.writeln('Cargo descriptors      : ${summary.totalCount}');
  stdout.writeln('Admitted               : ${summary.admittedCount}');
  stdout.writeln('Remaining              : ${summary.remainingCount}');
  stdout.writeln('Completion             : ${summary.completionPercent}%');
  stdout.writeln('Missing runtime binary : ${summary.binaryMissingCount}');
  stdout.writeln('Missing provenance     : ${summary.provenanceMissingCount}');
  stdout.writeln(
    'Missing both           : ${summary.missingBinaryAndProvenanceCount}',
  );
  stdout.writeln(
    'Orphan runtime WebP    : ${summary.orphanRuntimeBinaryCount}',
  );
  stdout.writeln('Orphan provenance      : ${summary.orphanProvenanceCount}');
  stdout.writeln('Batch offset           : ${options.offset}');
  stdout.writeln(
    'State filter           : ${options.state?.wireName ?? 'any'}',
  );
  stdout.writeln('Next production batch  : ${batch.length}');

  if (plan.orphanRuntimeBinaryPaths.isNotEmpty) {
    stdout.writeln();
    stdout.writeln('WARNING: unreferenced cargo runtime WebP files:');
    for (final path in plan.orphanRuntimeBinaryPaths) {
      stdout.writeln('  - $path');
    }
  }
  if (plan.orphanProvenanceAssetIds.isNotEmpty) {
    stdout.writeln();
    stdout.writeln('WARNING: orphan cargo provenance records:');
    for (final assetId in plan.orphanProvenanceAssetIds) {
      stdout.writeln('  - $assetId');
    }
  }

  if (batch.isEmpty) return;
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
}

void _writeJson(
  GameAssetIntakePlan plan,
  List<GameAssetIntakeItem> batch,
  _CliOptions options,
) {
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'summary': plan.summary.toJson(),
      'batchLimit': options.limit,
      'batchOffset': options.offset,
      'stateFilter': options.state?.wireName,
      'summaryOnly': options.summaryOnly,
      'orphanRuntimeBinaryPaths': plan.orphanRuntimeBinaryPaths,
      'orphanProvenanceAssetIds': plan.orphanProvenanceAssetIds,
      'batch': batch.map((item) => item.toJson()).toList(growable: false),
    }),
  );
}

void _writeCsv(List<GameAssetIntakeItem> batch) {
  stdout.writeln(
    'assetId,concept,runtimePath,profile,width,height,state,'
    'needsRuntimeBinary,needsProvenance',
  );
  for (final item in batch) {
    final descriptor = item.descriptor;
    stdout.writeln(
      <Object?>[
        descriptor.id,
        descriptor.semantics.englishConcept,
        descriptor.path,
        descriptor.profile.wireName,
        descriptor.dimensions.width,
        descriptor.dimensions.height,
        item.state.wireName,
        item.needsRuntimeBinary,
        item.needsProvenance,
      ].map(_csvCell).join(','),
    );
  }
}

String _csvCell(Object? value) {
  final text = value?.toString() ?? '';
  if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
    return text;
  }
  return '"${text.replaceAll('"', '""')}"';
}

enum _OutputFormat { human, json, csv }

final class _CliOptions {
  const _CliOptions({
    required this.limit,
    required this.offset,
    required this.state,
    required this.format,
    required this.summaryOnly,
    required this.strict,
    required this.help,
  });

  final int limit;
  final int offset;
  final GameAssetIntakeState? state;
  final _OutputFormat format;
  final bool summaryOnly;
  final bool strict;
  final bool help;

  factory _CliOptions.parse(List<String> arguments) {
    var limit = 12;
    var offset = 0;
    GameAssetIntakeState? state;
    var format = _OutputFormat.human;
    var summaryOnly = false;
    var strict = false;
    var help = false;
    var legacyJson = false;

    for (final argument in arguments) {
      if (argument == '--json') {
        legacyJson = true;
        continue;
      }
      if (argument == '--summary-only') {
        summaryOnly = true;
        continue;
      }
      if (argument == '--strict') {
        strict = true;
        continue;
      }
      if (argument == '--help' || argument == '-h') {
        help = true;
        continue;
      }
      if (argument.startsWith('--limit=')) {
        limit = _parseBoundedInt(
          argument.substring('--limit='.length),
          name: '--limit',
          minimum: 1,
          maximum: 124,
        );
        continue;
      }
      if (argument.startsWith('--offset=')) {
        offset = _parseBoundedInt(
          argument.substring('--offset='.length),
          name: '--offset',
          minimum: 0,
          maximum: 123,
        );
        continue;
      }
      if (argument.startsWith('--state=')) {
        final wireName = argument.substring('--state='.length);
        if (wireName == 'any') {
          state = null;
        } else {
          state = GameAssetIntakeState.values
              .where(
                (value) =>
                    value != GameAssetIntakeState.admitted &&
                    value.wireName == wireName,
              )
              .firstOrNull;
          if (state == null) {
            throw FormatException(
              '--state must be any, missing_provenance, missing_binary, '
              'or missing_binary_and_provenance: $wireName',
            );
          }
        }
        continue;
      }
      if (argument.startsWith('--format=')) {
        final value = argument.substring('--format='.length);
        format = switch (value) {
          'human' => _OutputFormat.human,
          'json' => _OutputFormat.json,
          'csv' => _OutputFormat.csv,
          _ => throw FormatException(
            '--format must be human, json, or csv: $value',
          ),
        };
        continue;
      }
      throw FormatException('Unknown option: $argument');
    }

    if (legacyJson) {
      if (format != _OutputFormat.human && format != _OutputFormat.json) {
        throw const FormatException(
          '--json cannot be combined with --format=csv',
        );
      }
      format = _OutputFormat.json;
    }

    return _CliOptions(
      limit: limit,
      offset: offset,
      state: state,
      format: format,
      summaryOnly: summaryOnly,
      strict: strict,
      help: help,
    );
  }
}

int _parseBoundedInt(
  String value, {
  required String name,
  required int minimum,
  required int maximum,
}) {
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < minimum || parsed > maximum) {
    throw FormatException(
      '$name must be an integer from $minimum to $maximum: $value',
    );
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

const _usage = '''
AST-007 cargo asset intake planner

Usage:
  dart run tool/plan_ast_007_asset_intake.dart [options]

Options:
  --limit=N        Batch size from 1 to 124 (default: 12).
  --offset=N       Skip N pending items before selecting the batch.
  --state=STATE    any | missing_provenance | missing_binary |
                   missing_binary_and_provenance.
  --format=FORMAT  human | json | csv (default: human).
  --json           Backward-compatible alias for --format=json.
  --summary-only   Print summary/orphan data without batch rows.
  --strict         Exit 2 unless all descriptors are admitted and no orphans exist.
  --help, -h       Show this help text.
''';
