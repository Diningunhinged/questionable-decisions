import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'api_logger.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint',
    );

    final stopwatch = Stopwatch()..start();

    ApiLogger.request(
      method: 'GET',
      url: uri.toString(),
    );

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              ...?headers,
            },
          )
          .timeout(ApiConfig.requestTimeout);

      stopwatch.stop();

      ApiLogger.response(
        statusCode: response.statusCode,
        durationMs: stopwatch.elapsedMilliseconds,
        bytes: response.bodyBytes.length,
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw ApiException(
          'API request failed.',
          statusCode: response.statusCode,
        );
      }

      return response;
    } catch (error) {
      stopwatch.stop();

      if (error is ApiException) {
        rethrow;
      }

      ApiLogger.error(
        method: 'GET',
        url: uri.toString(),
        error: error,
      );

      throw ApiException(
        'Unable to connect to the Dining Unhinged API.',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}