import 'dart:convert';

import '../core/network/api_client.dart';
import '../models/nearby_result.dart';

class DiningUnhingedApi {
  DiningUnhingedApi({
    ApiClient? client,
  }) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const String nearbyEndpoint =
      '/api/nearby.json';

  Future<List<NearbyResult>> fetchNearbyResults() async {
    final response = await _client.get(
      nearbyEndpoint,
    );

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const FormatException(
        'Dining Unhinged API returned an unexpected response.',
      );
    }

    return decoded
        .map(
          (item) => NearbyResult.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  void dispose() {
    _client.dispose();
  }
}