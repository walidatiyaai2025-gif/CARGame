import 'package:cargo_sort_game/core/application/crash_reporting_port.dart';
import 'package:cargo_sort_game/core/diagnostics/privacy_gated_crash_reporting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CrashReport report({String? message, String? stackTrace}) => CrashReport(
    severity: CrashReportSeverity.nonFatal,
    source: CrashReportSource.flutter,
    message: message ?? 'Widget failed',
    stackTrace: stackTrace ?? 'stack line',
    context: CrashReportContext(
      appVersion: '1.0.2',
      buildNumber: '3',
      environment: 'release',
    ),
    timestamp: DateTime.utc(2026, 8, 10, 1, 2, 3),
  );

  test('remote reporting is disabled when build config is off', () async {
    var emitted = false;
    final reporter = PrivacyGatedCrashReporting(
      configEnabled: false,
      privacy: const _AllowDiagnosticsPrivacy(),
      emitter: (_) async => emitted = true,
    );

    await reporter.capture(report());

    expect(reporter.isRemoteReportingEnabled, isFalse);
    expect(emitted, isFalse);
  });

  test('remote reporting is disabled when privacy eligibility is denied', () async {
    var emitted = false;
    final reporter = PrivacyGatedCrashReporting(
      configEnabled: true,
      privacy: const DenyAllCrashReportingPrivacy(),
      emitter: (_) async => emitted = true,
    );

    await reporter.capture(report());

    expect(reporter.isRemoteReportingEnabled, isFalse);
    expect(emitted, isFalse);
  });

  test('enabled reporting emits only redacted bounded correlation payload', () async {
    Map<String, Object>? emitted;
    final reporter = PrivacyGatedCrashReporting(
      configEnabled: true,
      privacy: const _AllowDiagnosticsPrivacy(),
      emitter: (payload) async => emitted = payload,
    );

    final secret = 'fake-test-secret-value';
    final longMessage =
        'failure token=$secret ${List<String>.filled(700, 'x').join()}';
    await reporter.capture(
      report(
        message: longMessage,
        stackTrace: 'C:\\Users\\example\\project\\main.dart:10\ntoken=$secret',
      ),
    );

    expect(reporter.isRemoteReportingEnabled, isTrue);
    expect(emitted, isNotNull);
    expect(emitted!['schema_version'], CrashReport.schemaVersion);
    expect(emitted!['severity'], 'nonFatal');
    expect(emitted!['source'], 'flutter');
    expect(emitted!['app_version'], '1.0.2');
    expect(emitted!['build_number'], '3');
    expect(emitted!['environment'], 'release');
    expect(emitted!['timestamp_utc'], '2026-08-10T01:02:03.000Z');

    final safeMessage = emitted!['message']! as String;
    final safeStack = emitted!['stack_trace']! as String;
    expect(safeMessage, isNot(contains(secret)));
    expect(safeMessage, contains('[REDACTED]'));
    expect(safeMessage.length, lessThanOrEqualTo(512));
    expect(safeStack, isNot(contains(secret)));
    expect(safeStack, contains('<USER_PATH>'));
    expect(safeStack.length, lessThanOrEqualTo(8192));
  });

  test('emitter failures never escape into gameplay', () async {
    final reporter = PrivacyGatedCrashReporting(
      configEnabled: true,
      privacy: const _AllowDiagnosticsPrivacy(),
      emitter: (_) async => throw StateError('processor unavailable'),
    );

    await expectLater(reporter.capture(report()), completes);
  });

  test('crash context rejects unknown environments', () {
    expect(
      () => CrashReportContext(
        appVersion: '1.0.2',
        buildNumber: '3',
        environment: 'production-ish',
      ),
      throwsArgumentError,
    );
  });
}

final class _AllowDiagnosticsPrivacy implements CrashReportingPrivacyPort {
  const _AllowDiagnosticsPrivacy();

  @override
  bool get canReportDiagnostics => true;
}
