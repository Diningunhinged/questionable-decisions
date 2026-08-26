import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/crawl_location_search_result.dart';
import 'location_search_provider.dart';

class NominatimLocationSearchProvider
    implements LocationSearchProvider {
  const NominatimLocationSearchProvider({
    http.Client? client,
  }) : _client = client;

  static const String _baseUrl =
      'https://nominatim.openstreetmap.org/search';

  static const String _userAgent =
      'QuestionableDecisions/1.0 '
      '(location search; contact: '
      'hello@diningunhinged.ca)';

  final http.Client? _client;

  @override
  Future<List<CrawlLocationSearchResult>> search(
    String query,
  ) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'q': normalizedQuery,
        'format': 'jsonv2',
        'limit': '5',
        'countrycodes': 'ca',
        'addressdetails': '1',
      },
    );

    final httpClient = _client ?? http.Client();

    try {
      final response = await httpClient
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': _userAgent,
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Location search failed '
          '(${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw const FormatException(
          'Location search returned an '
          'unexpected response.',
        );
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(
            CrawlLocationSearchResult.fromNominatimJson,
          )
          .where(
            (result) => result.isValid,
          )
          .toList();
    } finally {
      if (_client == null) {
        httpClient.close();
      }
    }
  }
}