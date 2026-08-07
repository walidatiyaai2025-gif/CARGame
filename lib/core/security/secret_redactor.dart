final class SecretRedactor {
  SecretRedactor._();

  static const String redacted = '[REDACTED]';
  static const String userPath = '<USER_PATH>';

  static final RegExp _privateKeyBlock = RegExp(
    r'-----BEGIN(?: [A-Z0-9]+)* PRIVATE KEY-----[\s\S]*?-----END(?: [A-Z0-9]+)* PRIVATE KEY-----',
    caseSensitive: false,
  );

  static final RegExp _bearerToken = RegExp(
    r'\b(Bearer\s+)[A-Za-z0-9._~+/=-]{8,}',
    caseSensitive: false,
  );

  static final RegExp _credentialAssignment = RegExp(
    r'\b(password|passwd|pwd|token|access[_-]?token|refresh[_-]?token|api[_-]?key|apikey|client[_-]?secret|secret|authorization)\b(\s*[:=]\s*)(["\']?)([^\s,"\';}{]{4,})(["\']?)',
    caseSensitive: false,
  );

  static final RegExp _credentialQueryParameter = RegExp(
    r'([?&](?:password|passwd|pwd|token|access_token|refresh_token|api_key|apikey|client_secret|secret)=)([^&#\s]+)',
    caseSensitive: false,
  );

  static final RegExp _windowsUserPath = RegExp(
    r'\b[A-Za-z]:\\Users\\[^\\\r\n]+',
    caseSensitive: false,
  );

  static final RegExp _unixUserPath = RegExp(
    r'(?<![A-Za-z0-9_])/(?:Users|home)/[^/\s]+(?:/[^\s\r\n]*)?',
    caseSensitive: true,
  );

  static String redact(String input) {
    if (input.isEmpty) return input;

    var output = input.replaceAll(_privateKeyBlock, redacted);

    output = output.replaceAllMapped(
      _bearerToken,
      (match) => '${match.group(1)}$redacted',
    );

    output = output.replaceAllMapped(_credentialAssignment, (match) {
      final key = match.group(1)!;
      final separator = match.group(2)!;
      final quote = match.group(3) ?? '';
      return '$key$separator$quote$redacted$quote';
    });

    output = output.replaceAllMapped(
      _credentialQueryParameter,
      (match) => '${match.group(1)}$redacted',
    );

    output = output.replaceAll(_windowsUserPath, userPath);
    output = output.replaceAll(_unixUserPath, userPath);

    return output;
  }
}
