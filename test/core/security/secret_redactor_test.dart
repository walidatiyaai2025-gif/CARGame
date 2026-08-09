import 'package:cargo_sort_game/core/security/secret_redactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecretRedactor', () {
    test('redacts bearer tokens', () {
      const input = 'Authorization: Bearer abcdefghijklmnop.1234567890'; // secret-scan: allow

      final output = SecretRedactor.redact(input);

      expect(output, 'Authorization: Bearer [REDACTED]');
      expect(output, isNot(contains('abcdefghijklmnop')));
    });

    test('redacts common credential assignments while preserving key names', () {
      const input = 'password="super-secret-value" api_key=abc123456789 token:xyz987654321'; // secret-scan: allow

      final output = SecretRedactor.redact(input);

      expect(output, contains('password="[REDACTED]"'));
      expect(output, contains('api_key=[REDACTED]'));
      expect(output, contains('token:[REDACTED]'));
      expect(output, isNot(contains('super-secret-value')));
    });

    test('redacts secret query parameters without destroying the URL', () {
      const input = 'https://example.test/path?mode=play&access_token=abc123456789&lang=en'; // secret-scan: allow

      final output = SecretRedactor.redact(input);

      expect(
        output,
        'https://example.test/path?mode=play&access_token=[REDACTED]&lang=en',
      );
    });

    test('redacts high-confidence standalone credentials', () {
      const input =
          'github=ghp_ABCDEFGHIJKLMNOPQRSTUVWX ' // secret-scan: allow
          'aws=AKIAABCDEFGHIJKLMNOP ' // secret-scan: allow
          'google=AIzaABCDEFGHIJKLMNOPQRSTUVWXYZ123456 ' // secret-scan: allow
          'slack=xoxb-12345678901234567890'; // secret-scan: allow

      final output = SecretRedactor.redact(input);

      expect(output, isNot(contains('ghp_')));
      expect(output, isNot(contains('AKIA')));
      expect(output, isNot(contains('AIza')));
      expect(output, isNot(contains('xoxb-')));
      expect(RegExp(r'\[REDACTED\]').allMatches(output), hasLength(4));
    });

    test('redacts private key blocks', () {
      final input = [
        '-----BEGIN PRIVATE KEY-----', // secret-scan: allow
        'not-real-key-material-for-redaction-test',
        '-----END PRIVATE KEY-----',
      ].join('\n');

      expect(SecretRedactor.redact(input), SecretRedactor.redacted);
    });

    test('redacts Windows and Unix user-specific paths', () {
      const input = 'C:\\Users\\Example\\AppData\\Local\\app.log /home/example/project/file.dart'; // secret-scan: allow

      final output = SecretRedactor.redact(input);

      expect(output, isNot(contains('Example')));
      expect(output, isNot(contains('/home/example'))); // secret-scan: allow
      expect(output, contains(SecretRedactor.userPath));
    });

    test('preserves relative feature paths containing a home segment', () {
      const input = "import 'features/home/home_screen.dart';";

      expect(SecretRedactor.redact(input), input);
    });

    test('does not redact ordinary diagnostics or Google public test ad ids', () {
      const input =
          'level=42 status=ready ad=ca-app-pub-3940256099942544/6300978111 '
          'url=https://example.test/help?lang=en';

      expect(SecretRedactor.redact(input), input);
    });
  });
}
