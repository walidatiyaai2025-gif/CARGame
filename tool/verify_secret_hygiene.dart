import 'dart:io';

const _allowMarker = 'secret-scan: allow';

final _textExtensions = <String>{
  '.dart',
  '.yaml',
  '.yml',
  '.md',
  '.txt',
  '.json',
  '.ps1',
  '.bat',
  '.gradle',
  '.kts',
  '.properties',
  '.xml',
  '.html',
  '.js',
  '.css',
};

final _forbiddenFileExtensions = <String>{
  '.jks',
  '.keystore',
  '.pem',
  '.p12',
  '.pfx',
};

final _privateKeyHeader = RegExp(
  r'-----BEGIN(?: [A-Z0-9]+)* PRIVATE KEY-----',
  caseSensitive: false,
);

final _knownSecretPatterns = <RegExp>[
  RegExp(r'\bAKIA[0-9A-Z]{16}\b'),
  RegExp(r'\bgh[pousr]_[A-Za-z0-9_]{20,}\b'),
  RegExp(r'\bAIza[0-9A-Za-z_-]{30,}\b'),
  RegExp(r'\bxox[baprs]-[0-9A-Za-z-]{20,}\b'),
];

final _credentialAssignment = RegExp(
  r'''\b(password|passwd|pwd|token|access[_-]?token|refresh[_-]?token|api[_-]?key|apikey|client[_-]?secret|secret)\b\s*[:=]\s*["']?([A-Za-z0-9_./+=-]{16,})''',
  caseSensitive: false,
);

final _windowsUserPath = RegExp(
  r'\b[A-Za-z]:\\Users\\[^\\\r\n]+',
  caseSensitive: false,
);

final _unixUserPath = RegExp(
  r'/(?:Users|home)/[^/\s]+(?:/[^\s\r\n]*)?',
);

const _placeholderFragments = <String>{
  'placeholder',
  'example',
  'sample',
  'dummy',
  'redacted',
  'changeme',
  'change-me',
  'your-',
  'your_',
  'not-real',
  'fake',
};

Future<void> main() async {
  final tracked = await Process.run('git', ['ls-files']);
  if (tracked.exitCode != 0) {
    stderr.writeln('Unable to enumerate tracked files with git ls-files.');
    stderr.write(tracked.stderr);
    exitCode = 2;
    return;
  }

  final violations = <String>[];
  final paths = (tracked.stdout as String)
      .split(RegExp(r'\r?\n'))
      .where((path) => path.trim().isNotEmpty)
      .toList(growable: false);

  for (final path in paths) {
    final lowerPath = path.toLowerCase();
    final extension = _extensionOf(lowerPath);

    if (_forbiddenFileExtensions.contains(extension)) {
      violations.add('$path: tracked signing/private-key material is forbidden');
      continue;
    }

    if (_isForbiddenLocalSecretFile(lowerPath)) {
      violations.add('$path: local secret/config artifact must not be tracked');
      continue;
    }

    if (!_textExtensions.contains(extension) && !_isExtensionlessPolicyFile(path)) {
      continue;
    }

    final file = File(path);
    if (!await file.exists()) continue;

    String content;
    try {
      content = await file.readAsString();
    } on FileSystemException {
      continue;
    }

    final lines = content.split(RegExp(r'\r?\n'));
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (line.contains(_allowMarker)) continue;

      final reason = _violationReason(line);
      if (reason != null) {
        violations.add('$path:${index + 1}: $reason');
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('Secret hygiene verification failed:');
    for (final violation in violations) {
      stderr.writeln(' - $violation');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Secret hygiene verification passed for ${paths.length} tracked files.');
}

String? _violationReason(String line) {
  if (_privateKeyHeader.hasMatch(line)) {
    return 'private-key material detected';
  }

  for (final pattern in _knownSecretPatterns) {
    if (pattern.hasMatch(line)) {
      return 'high-confidence credential/token pattern detected';
    }
  }

  final assignment = _credentialAssignment.firstMatch(line);
  if (assignment != null) {
    final value = assignment.group(2)!.toLowerCase();
    if (!_looksLikePlaceholder(value)) {
      return 'credential-like assignment detected';
    }
  }

  if (_windowsUserPath.hasMatch(line) || _unixUserPath.hasMatch(line)) {
    return 'machine-local user profile path detected';
  }

  return null;
}

bool _looksLikePlaceholder(String value) {
  return _placeholderFragments.any(value.contains);
}

bool _isForbiddenLocalSecretFile(String lowerPath) {
  final name = lowerPath.split('/').last;
  if (name == '.env') return true;
  if (name.startsWith('.env.') && name != '.env.example') return true;
  if (name == 'key.properties') return true;
  if (name == 'dart-defines.local.json' || name == 'dart_defines.local.json') {
    return true;
  }
  return lowerPath.startsWith('secrets/') || lowerPath.contains('/secrets/');
}

bool _isExtensionlessPolicyFile(String path) {
  final name = path.split('/').last;
  return name == '.gitignore' || name == 'LICENSE';
}

String _extensionOf(String path) {
  final name = path.split('/').last;
  final dot = name.lastIndexOf('.');
  return dot <= 0 ? '' : name.substring(dot);
}
