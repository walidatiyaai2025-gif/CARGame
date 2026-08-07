import 'dart:io';

final class _Rule {
  const _Rule(this.name, this.pattern, this.message);

  final String name;
  final RegExp pattern;
  final String message;
}

void main() {
  final root = Directory.current;
  final scriptFiles = root
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) {
        final path = file.path.toLowerCase();
        return path.endsWith('.ps1') ||
            path.endsWith('.bat') ||
            path.endsWith('.cmd');
      })
      .where((file) {
        final normalized = file.path.replaceAll('\\', '/');
        return !normalized.contains('/build/') &&
            !normalized.contains('/.dart_tool/') &&
            !normalized.contains('/.git/');
      })
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final rules = <_Rule>[
    _Rule(
      'fixed-emulator-serial',
      RegExp(r'\bemulator-\d{4,}\b', caseSensitive: false),
      'Use dynamic adb device discovery instead of a fixed emulator serial.',
    ),
    _Rule(
      'fixed-avd-argument',
      RegExp(
        r'''["']-avd["']\s*,?\s*["'][A-Za-z0-9_.-]+["']''',
        caseSensitive: false,
      ),
      'Pass a discovered/parameterized AVD name instead of a literal -avd value.',
    ),
    _Rule(
      'fixed-avd-default',
      RegExp(
        r'''\$AvdName\s*=\s*["'][^"'$%][^"']+["']''',
        caseSensitive: false,
      ),
      'Keep the AVD parameter default empty so the script can discover an installed AVD.',
    ),
    _Rule(
      'fixed-adb-target',
      RegExp(
        r'''\badb(?:\.exe)?\b[^\r\n]*\s-s\s+["']?[A-Za-z0-9._:-]+["']?''',
        caseSensitive: false,
      ),
      'Resolve the adb target dynamically instead of passing a literal -s serial.',
    ),
  ];

  final failures = <String>[];
  for (final file in scriptFiles) {
    final content = file.readAsStringSync();
    final relativePath = file.path
        .replaceFirst('${root.path}${Platform.pathSeparator}', '')
        .replaceAll('\\', '/');

    for (final rule in rules) {
      for (final match in rule.pattern.allMatches(content)) {
        final line = 1 + '\n'.allMatches(content.substring(0, match.start)).length;
        failures.add(
          '$relativePath:$line [${rule.name}] ${rule.message}',
        );
      }
    }
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Dynamic Android target validation FAILED:');
    for (final failure in failures) {
      stderr.writeln(' - $failure');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Dynamic Android target validation PASSED for ${scriptFiles.length} scripts.',
  );
}
