import 'dart:convert';
import 'dart:io';

Never _fail(String message) {
  stderr.writeln('PRIVACY INVENTORY VALIDATION FAILED: $message');
  exitCode = 1;
  throw StateError(message);
}

Set<String> _stringSet(Object? value) {
  if (value is! List) {
    return <String>{};
  }
  return value.whereType<String>().toSet();
}

void main() {
  final inventoryFile = File('docs/privacy/data_inventory.json');
  if (!inventoryFile.existsSync()) {
    _fail('docs/privacy/data_inventory.json is missing.');
  }

  final decoded = jsonDecode(inventoryFile.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    _fail('Inventory root must be a JSON object.');
  }

  if (decoded['schemaVersion'] != 1) {
    _fail('Unsupported or missing schemaVersion.');
  }

  final processors = decoded['processors'];
  final flows = decoded['dataFlows'];
  final policy = decoded['dependencyPolicy'];
  if (processors is! List || flows is! List || policy is! Map<String, dynamic>) {
    _fail('processors, dataFlows, and dependencyPolicy are required.');
  }

  final processorIds = <String>{};
  for (final item in processors) {
    if (item is! Map<String, dynamic>) {
      _fail('Processor entries must be objects.');
    }
    final id = item['id'];
    if (id is! String || id.trim().isEmpty) {
      _fail('Processor id is required.');
    }
    if (!processorIds.add(id)) {
      _fail('Duplicate processor id: $id');
    }
  }

  final requiredFlowIds = <String>{
    'game-progress',
    'app-settings',
    'diagnostic-logs',
    'ad-sdk-processing',
  };
  final flowIds = <String>{};
  for (final item in flows) {
    if (item is! Map<String, dynamic>) {
      _fail('Data-flow entries must be objects.');
    }
    final id = item['id'];
    if (id is! String || id.trim().isEmpty) {
      _fail('Data-flow id is required.');
    }
    if (!flowIds.add(id)) {
      _fail('Duplicate data-flow id: $id');
    }

    for (final key in <String>[
      'category',
      'purpose',
      'processor',
      'storage',
      'consent',
      'retention',
      'deletion',
      'source',
    ]) {
      final value = item[key];
      if (value is! String || value.trim().isEmpty) {
        _fail('Data flow $id is missing $key.');
      }
    }

    final processor = item['processor'] as String;
    if (!processorIds.contains(processor)) {
      _fail('Data flow $id references unknown processor $processor.');
    }

    final source = File(item['source'] as String);
    if (!source.existsSync()) {
      _fail('Data flow $id source does not exist: ${item['source']}');
    }
  }

  final missingFlows = requiredFlowIds.difference(flowIds);
  if (missingFlows.isNotEmpty) {
    _fail('Required data flows are missing: ${missingFlows.join(', ')}');
  }

  final pubspec = File('pubspec.yaml').readAsStringSync();
  final networkDependencies = _stringSet(policy['networkDataDependencies']);
  final localDependencies = _stringSet(policy['localStorageDependencies']);
  final forbiddenUnlessUpdated = _stringSet(
    policy['forbiddenUnlessInventoryUpdated'],
  );

  for (final dependency in {...networkDependencies, ...localDependencies}) {
    final dependencyPattern = RegExp(
      '^  ${RegExp.escape(dependency)}:',
      multiLine: true,
    );
    if (!dependencyPattern.hasMatch(pubspec)) {
      _fail('Inventory declares dependency $dependency but pubspec does not.');
    }
  }

  for (final dependency in forbiddenUnlessUpdated) {
    final dependencyPattern = RegExp(
      '^  ${RegExp.escape(dependency)}:',
      multiLine: true,
    );
    if (dependencyPattern.hasMatch(pubspec)) {
      _fail(
        'Dependency $dependency was added but the privacy inventory still marks it '
        'as forbidden-until-reviewed.',
      );
    }
  }

  final principles = decoded['principles'];
  if (principles is! Map<String, dynamic> ||
      principles['analyticsEnabled'] != false ||
      principles['cloudSyncEnabled'] != false ||
      principles['offlineFirst'] != true) {
    _fail(
      'Current offline/analytics/cloud privacy principles changed unexpectedly.',
    );
  }

  stdout.writeln(
    'Privacy inventory validation PASSED: '
    '${flows.length} flows, ${processors.length} processors.',
  );
}
