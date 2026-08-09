import 'dart:io';

const _packagePrefix = 'package:cargo_sort_game/';

final RegExp _directivePattern = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

enum ArchitectureZone { domain, application }

class ArchitectureViolation {
  const ArchitectureViolation({
    required this.sourcePath,
    required this.directive,
    required this.reason,
  });

  final String sourcePath;
  final String directive;
  final String reason;

  @override
  String toString() => '$sourcePath -> $directive: $reason';
}

class ArchitectureContract {
  ArchitectureContract(this.projectRoot);

  final Directory projectRoot;

  List<ArchitectureViolation> scan() {
    final violations = <ArchitectureViolation>[];
    violations.addAll(_scanZone('lib/core/domain', ArchitectureZone.domain));
    violations.addAll(
      _scanZone('lib/core/application', ArchitectureZone.application),
    );
    return violations;
  }

  List<ArchitectureViolation> inspectSource({
    required ArchitectureZone zone,
    required String sourcePath,
    required String source,
  }) {
    final violations = <ArchitectureViolation>[];
    for (final match in _directivePattern.allMatches(source)) {
      final directive = match.group(1)!;
      final resolved = _resolveDirective(sourcePath, directive);
      if (_isAllowed(zone, directive, resolved)) continue;

      violations.add(
        ArchitectureViolation(
          sourcePath: sourcePath,
          directive: directive,
          reason: _reasonFor(zone),
        ),
      );
    }
    return violations;
  }

  List<ArchitectureViolation> _scanZone(
    String relativeRoot,
    ArchitectureZone zone,
  ) {
    final directory = Directory('${projectRoot.path}/$relativeRoot');
    if (!directory.existsSync()) return const <ArchitectureViolation>[];

    final violations = <ArchitectureViolation>[];
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final sourcePath = _relativePath(entity);
      violations.addAll(
        inspectSource(
          zone: zone,
          sourcePath: sourcePath,
          source: entity.readAsStringSync(),
        ),
      );
    }
    return violations;
  }

  bool _isAllowed(
    ArchitectureZone zone,
    String directive,
    String? resolved,
  ) {
    if (directive.startsWith('dart:')) return true;
    if (resolved == null) return false;

    return switch (zone) {
      ArchitectureZone.domain => resolved.startsWith('lib/core/domain/'),
      ArchitectureZone.application =>
        resolved.startsWith('lib/core/domain/') ||
            resolved.startsWith('lib/core/application/'),
    };
  }

  String? _resolveDirective(String sourcePath, String directive) {
    if (directive.startsWith(_packagePrefix)) {
      return 'lib/${directive.substring(_packagePrefix.length)}';
    }
    if (directive.startsWith('package:')) return null;
    if (directive.startsWith('dart:')) return null;

    final rootUri = projectRoot.absolute.uri;
    final sourceUri = rootUri.resolve(sourcePath);
    final targetUri = sourceUri.resolve(directive);
    final rootPath = _normalize(projectRoot.absolute.path);
    final targetPath = _normalize(File.fromUri(targetUri).absolute.path);
    if (!targetPath.startsWith('$rootPath/')) return null;
    return targetPath.substring(rootPath.length + 1);
  }

  String _relativePath(File file) {
    final rootPath = _normalize(projectRoot.absolute.path);
    final filePath = _normalize(file.absolute.path);
    return filePath.substring(rootPath.length + 1);
  }

  String _reasonFor(ArchitectureZone zone) => switch (zone) {
    ArchitectureZone.domain =>
      'domain may depend only on Dart SDK and core/domain',
    ArchitectureZone.application =>
      'application may depend only on Dart SDK, core/domain, and core/application',
  };

  static String _normalize(String value) => value.replaceAll('\\', '/');
}
