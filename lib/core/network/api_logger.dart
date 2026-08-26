class ApiLogger {
  ApiLogger._();

  static void request({
    required String method,
    required String url,
  }) {
    print('════════ QD NETWORK REQUEST ════════');
    print('$method $url');
  }

  static void response({
    required int statusCode,
    required int durationMs,
    int? bytes,
  }) {
    print('STATUS: $statusCode');
    print('TIME: ${durationMs}ms');

    if (bytes != null) {
      print('BYTES: $bytes');
    }

    print('════════════════════════════════════');
  }

  static void error({
    required String method,
    required String url,
    Object? error,
  }) {
    print('════════ QD NETWORK ERROR ═════════');
    print('$method $url');

    if (error != null) {
      print('ERROR: $error');
    }

    print('════════════════════════════════════');
  }
}