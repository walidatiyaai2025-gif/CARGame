import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../security/secret_redactor.dart';

class LoggedAppError {
  const LoggedAppError({
    required this.level,
    required this.message,
    required this.details,
    required this.timestamp,
  });

  final String level;
  final String message;
  final String details;
  final DateTime timestamp;

  String get fullText {
    final buffer = StringBuffer()
      ..writeln('[${timestamp.toIso8601String()}] [$level]')
      ..writeln(message.trim());
    if (details.trim().isNotEmpty) {
      buffer
        ..writeln('--- Details ---')
        ..write(details.trim());
    }
    return buffer.toString();
  }
}

class AppLogger extends ChangeNotifier {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  final List<String> _entries = <String>[];
  final StreamController<LoggedAppError> _runtimeErrors =
      StreamController<LoggedAppError>.broadcast();

  File? _logFile;
  bool _initialized = false;

  List<String> get entries => List.unmodifiable(_entries);
  String get fullText => _entries.join('\n\n');
  String? get logFilePath => _logFile?.path;
  Stream<LoggedAppError> get runtimeErrors => _runtimeErrors.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final directory = await getApplicationSupportDirectory();
      final logsDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}logs',
      );
      if (!await logsDirectory.exists()) {
        await logsDirectory.create(recursive: true);
      }

      _logFile = File(
        '${logsDirectory.path}${Platform.pathSeparator}app_error.log',
      );

      if (await _logFile!.exists()) {
        final existing = SecretRedactor.redact(await _logFile!.readAsString());
        if (existing.trim().isNotEmpty) {
          _entries.add(existing.trim());
        }
      }

      await info('Logger initialized', details: 'File: ${_logFile!.path}');
    } catch (error, stackTrace) {
      _entries.add(
        _format('LOGGER_INIT_ERROR', error.toString(), stackTrace.toString()),
      );
    }
    notifyListeners();
  }

  Future<void> info(String message, {String? details}) {
    return _write('INFO', message, details ?? '');
  }

  Future<void> warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    bool notifyUser = false,
  }) {
    return _write(
      'WARNING',
      message,
      _details(error, stackTrace),
      notifyUser: notifyUser,
    );
  }

  Future<void> error(
    String message,
    Object error,
    StackTrace stackTrace, {
    bool notifyUser = true,
  }) {
    return _write(
      'ERROR',
      message,
      _details(error, stackTrace),
      notifyUser: notifyUser,
    );
  }

  Future<void> flutterError(FlutterErrorDetails details) {
    return _write(
      'FLUTTER_ERROR',
      details.exceptionAsString(),
      details.stack?.toString() ?? details.toString(),
      notifyUser: true,
    );
  }

  Future<void> platformError(Object error, StackTrace stackTrace) {
    return _write(
      'PLATFORM_ERROR',
      error.toString(),
      stackTrace.toString(),
      notifyUser: true,
    );
  }

  Future<void> isolateError(dynamic errorData) async {
    Object error = 'Unknown isolate error';
    StackTrace stackTrace = StackTrace.empty;
    if (errorData is List && errorData.isNotEmpty) {
      error = errorData.first ?? error;
      if (errorData.length > 1 && errorData[1] != null) {
        stackTrace = StackTrace.fromString(errorData[1].toString());
      }
    }

    await _write(
      'ISOLATE_ERROR',
      error.toString(),
      stackTrace.toString(),
      notifyUser: true,
    );
  }

  Future<void> checkpoint(String name, {String? details}) {
    return _write('CHECKPOINT', name, details ?? '');
  }

  Future<void> clear() async {
    _entries.clear();
    try {
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.writeAsString('');
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: fullText));
  }

  Future<void> _write(
    String level,
    String message,
    String details, {
    bool notifyUser = false,
  }) async {
    final timestamp = DateTime.now();
    final safeMessage = SecretRedactor.redact(message);
    final safeDetails = SecretRedactor.redact(details);
    final entry = _format(
      level,
      safeMessage,
      safeDetails,
      timestamp: timestamp,
    );

    _entries.add(entry);
    if (_entries.length > 300) {
      _entries.removeRange(0, _entries.length - 300);
    }

    try {
      if (_logFile != null) {
        await _logFile!.writeAsString(
          '$entry\n\n',
          mode: FileMode.append,
          flush: true,
        );
      }
    } catch (_) {}

    if (kDebugMode) {
      debugPrint(entry);
    }

    if (notifyUser && !_runtimeErrors.isClosed) {
      _runtimeErrors.add(
        LoggedAppError(
          level: level,
          message: safeMessage,
          details: safeDetails,
          timestamp: timestamp,
        ),
      );
    }

    notifyListeners();
  }

  String _format(
    String level,
    String message,
    String details, {
    DateTime? timestamp,
  }) {
    final time = (timestamp ?? DateTime.now()).toIso8601String();
    final safeMessage = SecretRedactor.redact(message);
    final safeDetails = SecretRedactor.redact(details);
    final buffer = StringBuffer()
      ..writeln('[$time] [$level]')
      ..writeln(safeMessage.trim());
    if (safeDetails.trim().isNotEmpty) {
      buffer
        ..writeln('--- Details ---')
        ..write(safeDetails.trim());
    }
    return buffer.toString();
  }

  String _details(Object? error, StackTrace? stackTrace) {
    final buffer = StringBuffer();
    if (error != null) buffer.writeln(error);
    if (stackTrace != null) buffer.write(stackTrace);
    return buffer.toString();
  }
}

class AppErrorBoundary {
  static RawReceivePort? _isolateErrorPort;

  static Future<void> install() async {
    final logger = AppLogger.instance;
    await logger.initialize();

    FlutterError.onError = (FlutterErrorDetails details) {
      unawaited(logger.flutterError(details));
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError =
        (Object error, StackTrace stackTrace) {
          unawaited(logger.platformError(error, stackTrace));
          return true;
        };

    _isolateErrorPort = RawReceivePort((dynamic pair) {
      unawaited(logger.isolateError(pair));
    });
    Isolate.current.addErrorListener(_isolateErrorPort!.sendPort);
  }
}
