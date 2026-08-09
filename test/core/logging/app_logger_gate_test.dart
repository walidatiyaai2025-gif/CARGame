import 'package:cargo_sort_game/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('disabled local diagnostics does not retain new log entries', () async {
    final logger = AppLogger.instance;

    await logger.initialize(enabled: false);
    await logger.info('should not be retained');
    await logger.warning('should not be retained either');

    expect(logger.isEnabled, isFalse);
    expect(logger.entries, isEmpty);
    expect(logger.fullText, isEmpty);
    expect(logger.logFilePath, isNull);
  });
}
