import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/architecture/architecture_contract.dart';

void main() {
  test('core domain and application obey inward-only dependencies', () {
    final contract = ArchitectureContract(Directory.current);
    final violations = contract.scan();

    expect(
      violations,
      isEmpty,
      reason: violations.map((violation) => violation.toString()).join('\n'),
    );
  });

  test('domain rejects Flutter and storage dependencies', () {
    final contract = ArchitectureContract(Directory.current);
    final violations = contract.inspectSource(
      zone: ArchitectureZone.domain,
      sourcePath: 'lib/core/domain/example.dart',
      source: '''
import 'package:flutter/material.dart';
import '../storage/progress_store.dart';
''',
    );

    expect(violations, hasLength(2));
  });

  test('application accepts domain but rejects service implementations', () {
    final contract = ArchitectureContract(Directory.current);
    final allowed = contract.inspectSource(
      zone: ArchitectureZone.application,
      sourcePath: 'lib/core/application/example.dart',
      source: 'import \'../domain/optional_service_state.dart\';',
    );
    final rejected = contract.inspectSource(
      zone: ArchitectureZone.application,
      sourcePath: 'lib/core/application/example.dart',
      source: 'import \'../services/optional_service_coordinator.dart\';',
    );

    expect(allowed, isEmpty);
    expect(rejected, hasLength(1));
  });

  test('main entry point does not construct storage or service adapters', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('import \'bootstrap/app_composition.dart\';'));
    expect(source, isNot(contains('core/storage/progress_store.dart')));
    expect(source, isNot(contains('core/settings/app_settings_store.dart')));
    expect(
      source,
      isNot(contains('core/services/optional_service_coordinator.dart')),
    );
  });
}
