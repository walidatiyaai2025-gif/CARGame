import '../application/crash_reporting_port.dart';
import '../security/secret_redactor.dart';

typedef CrashReportEmitter = Future<void> Function(Map<String, Object> payload);

final class DenyAllCrashReportingPrivacy implements CrashReportingPrivacyPort {
  const DenyAllCrashReportingPrivacy();

  @override
  bool get canReportDiagnostics => false;
}

final class PrivacyGatedCrashReporting implements CrashReportingPort {
  PrivacyGatedCrashReporting({
    required bool configEnabled,
    required CrashReportingPrivacyPort privacy,
    CrashReportEmitter? emitter,
  }) : _configEnabled = configEnabled,
       _privacy = privacy,
       _emitter = emitter;

  factory PrivacyGatedCrashReporting.disabled() => PrivacyGatedCrashReporting(
    configEnabled: false,
    privacy: const DenyAllCrashReportingPrivacy(),
  );

  static const int maxMessageLength = 512;
  static const int maxStackTraceLength = 8192;

  final bool _configEnabled;
  final CrashReportingPrivacyPort _privacy;
  final CrashReportEmitter? _emitter;

  @override
  bool get isRemoteReportingEnabled =>
      _configEnabled && _privacy.canReportDiagnostics && _emitter != null;

  @override
  Future<void> capture(CrashReport report) async {
    if (!isRemoteReportingEnabled) return;

    final payload = Map<String, Object>.unmodifiable(<String, Object>{
      'schema_version': CrashReport.schemaVersion,
      'severity': report.severity.name,
      'source': report.source.name,
      'message': _redactAndBound(report.message, maxMessageLength),
      'stack_trace': _redactAndBound(
        report.stackTrace,
        maxStackTraceLength,
        allowEmpty: true,
      ),
      'app_version': report.context.appVersion,
      'build_number': report.context.buildNumber,
      'environment': report.context.environment,
      'timestamp_utc': report.timestamp.toIso8601String(),
    });

    try {
      await _emitter!(payload);
    } catch (_) {
      // Remote diagnostics is always optional. A processor failure must never
      // affect startup, gameplay, local diagnostics, or user-visible behavior.
    }
  }

  static String _redactAndBound(
    String value,
    int maxLength, {
    bool allowEmpty = false,
  }) {
    final redacted = SecretRedactor.redact(value).trim();
    if (redacted.isEmpty) return allowEmpty ? '' : 'Unknown error';
    if (redacted.length <= maxLength) return redacted;
    return redacted.substring(0, maxLength);
  }
}
