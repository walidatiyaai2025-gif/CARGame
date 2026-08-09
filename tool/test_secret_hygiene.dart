import 'dart:io';

Future<void> main() async {
  final repoRoot = File.fromUri(Platform.script).parent.parent;
  final scanner = File('${repoRoot.path}/tool/verify_secret_hygiene.dart');
  if (!await scanner.exists()) {
    stderr.writeln('Secret hygiene scanner not found: ${scanner.path}');
    exitCode = 2;
    return;
  }

  final failures = <String>[];

  await _runCase(
    name: 'safe placeholders and public test ids pass',
    scannerPath: scanner.absolute.path,
    files: {
      '.env.example': 'API_KEY=your-example-api-key\n',
      'config.txt':
          'ad=ca-app-pub-3940256099942544/6300978111\nstatus=ready\n',
    },
    expectedExitCode: 0,
    failures: failures,
  );

  await _runCase(
    name: 'forced tracked local credential file is rejected',
    scannerPath: scanner.absolute.path,
    files: {'release.credentials.local.json': '{}\n'},
    expectedExitCode: 1,
    expectedErrorFragment: 'local secret/config artifact must not be tracked',
    failures: failures,
  );

  await _runCase(
    name: 'forced tracked environment override is rejected',
    scannerPath: scanner.absolute.path,
    files: {'.env.production': 'MODE=release\n'},
    expectedExitCode: 1,
    expectedErrorFragment: 'local secret/config artifact must not be tracked',
    failures: failures,
  );

  await _runCase(
    name: 'tracked keystore is rejected by filename',
    scannerPath: scanner.absolute.path,
    files: {'android/upload.jks': 'not-a-real-keystore\n'},
    expectedExitCode: 1,
    expectedErrorFragment: 'tracked signing/private-key material is forbidden',
    failures: failures,
  );

  final githubToken = 'ghp_' 'ABCDEFGHIJKLMNOPQRSTUVWX';
  await _runCase(
    name: 'high confidence token signature is rejected',
    scannerPath: scanner.absolute.path,
    files: {'diagnostic.txt': 'token=$githubToken\n'},
    expectedExitCode: 1,
    expectedErrorFragment: 'high-confidence credential/token pattern detected',
    failures: failures,
  );

  if (failures.isNotEmpty) {
    stderr.writeln('Secret hygiene regression test failed:');
    for (final failure in failures) {
      stderr.writeln(' - $failure');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Secret hygiene regression test passed.');
}

Future<void> _runCase({
  required String name,
  required String scannerPath,
  required Map<String, String> files,
  required int expectedExitCode,
  required List<String> failures,
  String? expectedErrorFragment,
}) async {
  final temp = await Directory.systemTemp.createTemp('cargame-secret-hygiene-');
  try {
    final init = await Process.run('git', ['init', '--quiet'], workingDirectory: temp.path);
    if (init.exitCode != 0) {
      failures.add('$name: unable to initialize temporary git repository');
      return;
    }

    for (final entry in files.entries) {
      final file = File('${temp.path}/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsString(entry.value);
    }

    final add = await Process.run(
      'git',
      ['add', '--force', '.'],
      workingDirectory: temp.path,
    );
    if (add.exitCode != 0) {
      failures.add('$name: unable to stage fixture files');
      return;
    }

    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', scannerPath],
      workingDirectory: temp.path,
    );
    if (result.exitCode != expectedExitCode) {
      failures.add(
        '$name: expected exit $expectedExitCode, got ${result.exitCode}; '
        'stderr=${result.stderr}',
      );
      return;
    }

    if (expectedErrorFragment != null &&
        !(result.stderr as String).contains(expectedErrorFragment)) {
      failures.add(
        '$name: expected stderr to contain "$expectedErrorFragment"; '
        'stderr=${result.stderr}',
      );
    }
  } finally {
    await temp.delete(recursive: true);
  }
}
