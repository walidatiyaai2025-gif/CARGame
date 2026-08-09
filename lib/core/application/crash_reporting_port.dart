enum CrashReportSeverity { fatal, nonFatal }

enum CrashReportSource { flutter, platform, isolate, zone, startup, manual }

final class CrashReportContext {
  CrashReportContext({
    required this.appVersion,
    required this.buildNumber,
    required this.environment,
  }) {
    _validateBounded('appVersion', appVersion, maxLength: 64);
    _validateBounded('buildNumber', buildNumber, maxLength: 32);
    if (!const <String>{'debug', 'staging', 'release'}.contains(environment)) {
      throw ArgumentError.value(
        environment,
        'environment',
        'Crash report environment must be debug, staging, or release.',
      );
    }
  }

  factory CrashReportContext.fromEnvironment() => CrashReportContext(
    appVersion: const String.fromEnvironment(
      'APP_VERSION',
      defaultValue: '1.0.2',
    ),
    buildNumber: const String.fromEnvironment(
      'APP_BUILD_NUMBER',
      defaultValue: '3',
    ),
    environment: const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'debug',
    ),
  );

  final String appVersion;
  final String buildNumber;
  final String environment;
}

final class CrashReport {
  CrashReport({
    required this.severity,
    required this.source,
    required this.message,
    required this.stackTrace,
    required this.context,
    DateTime? timestamp,
  }) : timestamp = (timestamp ?? DateTime.now()).toUtc() {
    if (message.trim().isEmpty) {
      throw ArgumentError.value(message, 'message', 'Message cannot be empty.');
    }
  }

  static const int schemaVersion = 1;

  final CrashReportSeverity severity;
  final CrashReportSource source;
  final String message;
  final String stackTrace;
  final CrashReportContext context;
  final DateTime timestamp;
}

abstract interface class CrashReportingPort {
  bool get isRemoteReportingEnabled;

  Future<void> capture(CrashReport report);
}

abstract interface class CrashReportingPrivacyPort {
  bool get canReportDiagnostics;
}

final class DisabledCrashReporting implements CrashReportingPort {
  const DisabledCrashReporting();

  @override
  bool get isRemoteReportingEnabled => false;

  @override
  Future<void> capture(CrashReport report) async {}
}

void _validateBounded(String name, String value, {required int maxLength}) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > maxLength) {
    throw ArgumentError.value(
      value,
      name,
      '$name must contain 1-$maxLength characters.',
    );
  }
}
